#import "highlight.typ" as hl
#import "../styling/icons.typ": pre-icons
#import "../styling/pre-themes.typ": pre-default, pseudo-pre-default
#import "utils.typ" as ut

// -----------------------------------------------------------------------------
// Document states
// -----------------------------------------------------------------------------

/// The label of the figure being laid out, used to label the lines of the code it contains.
#let uraw-figure = state("uraw-figure", none)

/// The styles outside of the raw environments (one per nested uraw call), used by the headers, footers, and comments.
#let uraw-style = state("uraw-style", ())

/// The current text, paragraph and block settings that the raw blocks and `uraw` change, so that the headers, footers and comments look as they would outside of the raw block.
///
/// -> dictionary
#let outside-style() = (
  text: (
    font: text.font,
    size: text.size,
    hyphenate: text.hyphenate,
    overhang: text.overhang,
  ),
  par: (
    leading: par.leading,
    spacing: par.spacing,
    justify: par.justify,
    first-line-indent: par.first-line-indent,
    hanging-indent: par.hanging-indent,
  ),
  block: (
    above: block.above,
    below: block.below,
    width: block.width,
    height: block.height,
    fill: block.fill,
    stroke: block.stroke,
    inset: block.inset,
    outset: block.outset,
    radius: block.radius,
  ),
)

/// The style of the headers, footers, comments: the one outside of the raw environment (the current one before the state is known).
///
/// -> dictionary
#let base-style() = {
  let styles = uraw-style.get()
  if styles.len() > 0 { styles.last() } else {
    (text: (:), par: (:), block: (:))
  }
}

// -----------------------------------------------------------------------------
// Initialization
// -----------------------------------------------------------------------------

#let initial-config = {
  let config = pre-default
  config.header += (content: none)
  config.footer += (content: none)
  config
}

#let initial-lang-configs = {
  let configs = (:)
  for (lang, lt) in pre-icons { configs.insert(lower(lang), (lang-tag: lt)) }
  configs
}

#let uraw-config-state = state("uraw-config-state", initial-config)

#let uraw-lang-configs-state = state(
  "uraw-lang-configs-state",
  initial-lang-configs,
)

// -----------------------------------------------------------------------------
// General
// -----------------------------------------------------------------------------

#let resolve-args(args) = {
  let pos = args.pos()
  let lang = if pos.len() == 0 {
    none
  } else if type(pos.first()) == str {
    pos.first()
  } else {
    panic("If a language is given, it must be a string.")
  }
  return (lang, args.named())
}

#let uncontext-category-getter(category, lang) = if lang == none {
  uraw-config-state.get().at(category)
} else {
  ut.filter-add-dict(
    uraw-config-state.get().at(category),
    uraw-lang-configs-state
      .get()
      .at(lang, default: (:))
      .at(category, default: (:)),
  )
}

#let category-getter(category, args) = context uncontext-category-getter(
  category,
  resolve-args(args).first(),
)

#let category-setter(category, args) = {
  let (lang, args) = resolve-args(args)

  if lang == none {
    uraw-config-state.update(config => {
      config.at(category) = ut.filter-add-dict(config.at(category), args)
      return config
    })
  } else {
    uraw-lang-configs-state.update(lang-configs => {
      if not lang in lang-configs { lang-configs.insert(lang, (:)) }
      if not category in lang-configs.at(lang) {
        lang-configs.at(lang).insert(category, (:))
      }
      lang-configs.at(lang).at(category) += args
      return lang-configs
    })
  }
}

// -----------------------------------------------------------------------------
// Parsing
// -----------------------------------------------------------------------------

#let category-parser(category, args, lang) = ut.filter-add-dict(
  uncontext-category-getter(category, lang),
  args.at(category, default: (:)),
)

/// Read some code from a file, to display it with `uraw` or `uraw-diff`: its lines are numbered from the first line read (when the `start` of the numbers is `auto`).
///
/// - file (path): The file, given with `path` (a string would be read relative to the package).
/// - from (int): The first line read.
/// - to (none, int): The last line read, `none` for the end of the file.
/// - lang (auto, none, str): The language of the code, `auto` for the extension of the file.
/// -> dictionary
#let read-code(file, from: 1, to: none, lang: auto) = {
  if type(file) == str {
    panic(
      "A file of code must be given by its path, as `path(\""
        + file
        + "\")` (a string would be read relative to the package).",
    )
  }
  assert(type(file) == path, message: "A file of code must be a path.")

  // (the line break ending the file does not start a new line)
  let lines = read(file).trim("\n", at: end, repeat: false).split("\n")
  let to = if to == none { lines.len() } else { to }
  assert(
    type(from) == int
      and type(to) == int
      and 1 <= from
      and from <= to
      and to <= lines.len(),
    message: "The lines read must be between 1 and "
      + str(lines.len())
      + ", the first one being before the last one.",
  )

  let lang = if lang != auto { lang } else {
    let ext = repr(file).find(regex("\\.[^./\"]+\"\\)$"))
    if ext != none { ext.slice(1, -2) }
  }
  (
    uraw-code: (
      raw: raw(lines.slice(from - 1, to).join("\n"), lang: lang, block: true),
      first-line: from,
    ),
  )
}

/// The raw block of some code (given as a raw block, a path or read with `read-code`) and the number of its first line, any other content being returned with the first line 1.
#let code-input(it) = {
  let it = if type(it) in (str, path) { read-code(it) } else { it }
  if type(it) == dictionary and "uraw-code" in it {
    (it.uraw-code.raw, it.uraw-code.first-line)
  } else { (it, 1) }
}

#let parse-markers-entry(m) = if type(m) == array and m.len() == 2 {
  let pl = hl.parse-line(m.first())
  if pl != none { (pl, m.last()) }
} else if type(m) == dictionary and "line" in m and "content" in m {
  let pl = hl.parse-line(m.line)
  if pl != none { (pl, m.content) }
}

#let parse-markers(markers, line-index, line-numbers) = {
  let by-line = line-numbers.map(_ => none)

  for m in ut.single-to-list-map(markers, parse-markers-entry) {
    assert(
      m != none,
      message: "A marker is either an array of the form `(line, content)` or a dictionary of the form `(line: l, content: c)`.",
    )
    let ((from, to), content) = m
    for l in range(from, to + 1) {
      let i = line-index(l)
      assert(
        by-line.at(i) == none,
        message: "Several markers are given for line " + str(l) + ".",
      )
      by-line.at(i) = content
    }
  }

  return by-line
}

// -----------------------------------------------------------------------------
// Spec
// -----------------------------------------------------------------------------

#let make-spec(default, categories, shortcuts, additional) = {
  let categories = categories
    .map(sec => (
      sec,
      default.at(sec).keys()
        + if sec in ("header", "footer") { ("content",) } else { () },
    ))
    .to-dict()

  let flat-names = (
    categories
      .pairs()
      .map(((sec, parameters)) => {
        parameters.map(param => if param != "visible" {
          ((sec + "-" + param): (sec, param))
        } else { (:) })
      })
      .flatten()
      .sum(default: (:))
      + shortcuts
  )

  (categories: categories, flat-names: flat-names, additional: additional)
}

#let uraw-spec = make-spec(
  pre-default,
  (
    "code",
    "numbers",
    "general",
    "header",
    "footer",
    "frame",
    "lang-tag",
    "highlight",
    "comment",
    "jump",
  ),
  (
    line-spacing: ("code", "line-spacing"),
    indentation: ("code", "indentation"),
    indent-size: ("code", "indent-size"),
    theme: ("code", "theme"),
    indented-line-return: ("code", "indented-line-return"),
    start: ("numbers", "start"),
    end: ("numbers", "end"),
    width: ("frame", "width"),
    breakable: ("frame", "breakable"),
    sharp-page-break: ("frame", "sharp-page-break"),
  )
    + pre-default.general.keys().map(k => (k, ("general", k))).to-dict(),
  ("markers", "highlights", "comments", "jumps", "follows", "precedes"),
)

#let diff-categories = ("diff-marker", "old", "new")

#let diff-spec = make-spec(
  pre-default
    + (general: pre-default.general + pre-default.diff.general)
    + diff-categories.map(c => (c, pre-default.diff.at(c))).to-dict(),
  diff-categories + uraw-spec.categories.keys(),
  (
    line-spacing: ("code", "line-spacing"),
    indentation: ("code", "indentation"),
    indent-size: ("code", "indent-size"),
    theme: ("code", "theme"),
    start: ("numbers", "start"),
    end: ("numbers", "end"),
    width: ("frame", "width"),
    breakable: ("frame", "breakable"),
    sharp-page-break: ("frame", "sharp-page-break"),
  )
    + (pre-default.general + pre-default.diff.general)
      .keys()
      .map(k => (k, ("general", k)))
      .to-dict(),
  ("follows", "precedes"),
)

#let pseudo-spec = make-spec(
  pseudo-pre-default,
  ("code", "numbers", "general", "header", "footer", "frame"),
  (
    line-spacing: ("code", "line-spacing"),
    indentation: ("code", "indentation"),
    indent-size: ("code", "indent-size"),
    style: ("code", "style"),
    start: ("numbers", "start"),
    end: ("numbers", "end"),
    width: ("frame", "width"),
    breakable: ("frame", "breakable"),
    sharp-page-break: ("frame", "sharp-page-break"),
  )
    + pseudo-pre-default.general.keys().map(k => (k, ("general", k))).to-dict(),
  (),
)

#let normalize-settings(args, spec) = {
  let settings = (:)

  // The settings are applied in the order they are given (by category or flat), a later one overriding an earlier one (so that the settings given after a theme override it)
  for (name, value) in args {
    if name in spec.categories {
      let parameters = spec.categories.at(name)
      let value = (
        if type(value) == dictionary {
          value
        } else if type(value) == bool and "visible" in parameters {
          (visible: value)
        } else if "format" in parameters
          and (
            value in (none, auto) or type(value) in (function, str)
          ) {
          (format: value)
        } else if "content" in parameters {
          (content: value)
        } else {
          panic(
            "The `"
              + name
              + "` settings must be a dictionary"
              + if "format" in parameters {
                " or a format (`none` to hide it, `auto`, a function)"
              } else if "visible" in parameters {
                " or a bool (its visibility)"
              }
              + ".",
          )
        }
      )
      ut.check-keys(value, parameters, "`" + name + "`")
      settings.insert(name, settings.at(name, default: (:)) + value)
    } else if name == "diff" and spec != pseudo-spec {
      // The settings of diffs (as in a theme): they override the other ones for a diff, and are kept apart otherwise (for `set-uraw`)
      assert(
        type(value) == dictionary,
        message: "The `diff` settings must be a dictionary.",
      )
      let is-diff = "old" in spec.categories
      let target = if is-diff { settings } else {
        settings.at("diff", default: (:))
      }
      for (c, v) in normalize-settings(value, diff-spec) {
        target.insert(c, target.at(c, default: (:)) + v)
      }
      if is-diff { settings = target } else { settings.diff = target }
    } else if name in spec.additional {
      settings.insert(name, value)
    } else if name in spec.flat-names {
      let (section, key) = spec.flat-names.at(name)
      settings.insert(
        section,
        settings.at(section, default: (:)) + ((key): value),
      )
    } else {
      panic("Unknown uraw setting `" + name + "`.")
    }
  }

  settings
}

// -----------------------------------------------------------------------------
// Main functions
// -----------------------------------------------------------------------------

/// Get the current uraw configuration, specific to a language if one is mentioned. The context must be known to call this function.
///
/// #example(`
/// #context get-uraw("typ")
/// `)
///
/// - lang (arguments): The optional language name as a positional arguments.
///
/// -> dictionary
#let get-uraw(..lang) = (
  uraw-spec
    .categories
    .keys()
    .map(sec => (
      sec,
      uncontext-category-getter(sec, resolve-args(lang).first()),
    ))
    .to-dict()
)

/// Store some normalized settings of diffs, overriding the stored ones (the ones of a language if one is given).
#let update-diff(settings, lang) = {
  let add(diff) = {
    for (category, value) in settings {
      diff.insert(category, diff.at(category, default: (:)) + value)
    }
    diff
  }
  if lang == none {
    uraw-config-state.update(config => config + (diff: add(config.diff)))
  } else {
    uraw-lang-configs-state.update(lang-configs => {
      let configs = lang-configs.at(lang, default: (:))
      configs.diff = add(configs.at("diff", default: (:)))
      lang-configs + ((lang): configs)
    })
  }
}

/// Set the uraw configuration, specific to a language if one is mentioned. Here is an example changing the appearance for Typst raw blocks:
///
/// #example(`
/// #set-uraw("typ",
///   numbers: (format: "1.", align: top + left, sep: teal),
///   frame: (fill: teal.transparentize(95%), stroke: black),
///   lang-tag: (fill: teal.transparentize(75%), stroke: teal, name: "Typst"),
/// )
/// `)
///
/// The following two calls are equivalent:
///
/// #example(`
/// #set-uraw(code: (fill: purple.transparentize(80%)))
/// #set-uraw(code-fill: purple.transparentize(80%))
/// `)
///
/// To have a better view of all the possible parameters, it is recommanded to read the #link("https://github.com/JulesViennotFranca/ultraw/blob/main/docs/doc.pdf")[Docs].
///
/// - args (arguments): The optional language and the configuration settings. The language is given as a positional argument, the settings are given as named arguments. Here is the complete list of settings with their type and default value:
///
///   - *code*
///     - `line-spacing (length) = 0.65em` the space between lines
///     - `fill (function | color | gradient | tiling | none) = none` the background color of the code, with `none` it is the background color of the frame, a function returns the background color based on the line number (e.g., `n => if calc.even(n) {blue} else {red}`)
///     - `theme (bytes | str | auto | none) = auto` the theme used for the raw code, the same as the `theme` parameter of the `std.raw` function
///     - `color (function | color | gradient | tiling | auto | none) = auto` the color of the code, `auto` and `none` colorate the code with the document's text color, a function return the code's color based on the line number
///     - `indentation (length | color | gradient | stroke | tiling | none) = gray` the style of indentation guidelines, set to `none` for no guidelines
///     - `indeted-line-return (bool) = true` wether the code after a line return starts at the indentation level of the line or on the left
///     - `indent-size (int | auto) = auto` the size in blank spaces of indents, if set to `auto` it is detected automatically based on the most common indent size #(" ")
///   increase
///
///   - *numbers*
///     - `start (int | auto) = auto` the starting number of raw blocks, `auto` is 1 or inherits the correct line number of code provided with `read_code`
///     - `end (int | none) = none` the ending number of raw blocks, if different from `none` it overrides `start`
///     - `format (function | str | auto | none) = auto` controls how numbers are displayed: a function takes the number as input and returns an integer or some content (e.g., `n => strong(str(n))`); a string must contain a 1 which will be replaced by the actual number (e.g., `"1:"`); `auto` display the number directly; `none` hides the numbers
///     - `fill (function | color | gradient | tiling | auto | none) = auto` the background color of numbers, with `auto` it is the background color of the code, with `none` it is the one of the frame, a function returns the background color based on the number
///     - `color (function | color | gradient | tiling | auto | none) = auto` the color of numbers, `auto` means the same color as the code, `none` means the same color as the document's text, a function returns the numbers color based on the number
///     - `gutter (length | auto) = auto` the space between the numbers and the code, `auto` fix it to `frame.inset.left + frame.inset.right`
///     - `sep (length | color | gradient | stroke | tiling | none) = none` the separator line between the numbers and markers column and the code column
///     - `align (alignment) = top + right` the alignment of numbers in their #(" ")
///   cell
///
///   - *general*
///     - `coloring-follow-numbers (bool) = true` wether the coloring functions follow the line numbers or the absolute line position in the raw block
///     - `markers-over-numbers (bool) = false` wether markers appear over numbers or not, when a marker appears over a number the line can't be labeled
///     - `line-reference (function) = n => ", line " + str(n)` the text written after "Listing ..." when referencing a precise line
///     - `default-stroke-thickness (relative) = .5pt` the default thickness of strokes of raw #(" ")
///   blocks
///
///   - *header* and *footer* (they have the same parameters)
///     - `fill (color | gradient | tiling | auto | none) = none` the background color, with `auto` is the code background color at line `numbers.start - 1` (useful for striped code style), with `none` is the background color of the frame
///     - `color (color | gradient | tiling | auto | none) = auto` the color of headers and footers text, `auto` means the same color as the code, `none` means the same color as the document's text
///     - `repeat (bool) = false` wether the header or footer of a raw block should be repeated at page break or when chaining blocks with `follows` and `precedes`
///     - `sep (length | color | gradient | stroke | tiling | auto | none) = auto` the separator line between the header or footer and the code, `auto` is the same as the frame's stroke
///     - `height (relative | fraction | auto) = auto` the height of the header or footer block
///     - `inset (relative | dictionary) = 5pt` the inset of the header or footer block
///     - ` align (alignment) = left + horizon` controls the alignment of the content of the header or the footer
///     - `code-aligned (bool) = false` wether to align the header or footer content with the code (when numbers or markers are #(" ")
///   visible)
///
///   - *frame*
///     - `breakable (bool) = true` wether the raw block is breakable
///     - `sharp-page-break (bool) = true` at page breaks, when `false` the raw block is displayed within two frame blocks (normal Typst processing), when `true` the frame block appears cut in half (no border, no radius, no inset along the page break)
///     - `width (relative | auto) = auto` the total width of the raw block
///     - `fill (color | gradient | tiling | none) = none` the background color of the whole raw block
///     - `stroke (length | color | gradient | stroke | tiling | dictionary | none) = none` the border of the raw block
///     - `radius (relative | dictionary) = 1mm` the radius of the raw block
///     - `inset (relative | dictionary) = (x: 3pt)` the inset of the raw #(" ")
///   block
///
///   - *lang-tag*
///     - `visible (bool) = true` wether to show the lang tag or not
///     - `name (content | auto | none) = auto` the language name displayed in the lang tag, `auto` defaults to the raw block `lang`
///     - `icon (content | none) = none` the icon displayed in the lang tag
///     - `placement ("inline" | "code" | "header" | "top-left" | "top" | "top-right" | "bottom-left" | "bottom" | "bottom-right" | "left-top" | "left" | "left-bottom" | "right-top" | "right" | "right-bottom" | ) = "code"` controls where the lang tag is displayed: `"inline"` places it on the first line of code; `"code"` is like `"inline"` but the vertical space for the lang tag is reserved on all code's lines; `"header"` places it in the header and defaults to `"code"` when there is no header; the rest place it on the border of the frame, the first location indicates the frame side while the second indicates the placement on that side (no second location is like `center` or `horizon`)
///     - `spacing (relative) = 5pt` the spacing between the lang tag and the content when the placement is `"inline"`, `"code"` or `"header"`
///     - `fill (color | gradient | tiling | auto | none) = luma(230)` the background color of the lang tag, `auto` default to the frame's background color
///     - `color (color | gradient | tiling | auto | none) = auto` the color of the language name in the lang tag, `auto` is the same as the code's color, `none` is the same as the document's text color
///     - `stroke (length | color | gradient | stroke | tiling | dictionary | auto | none) = auto` the border of the lang tag, `auto` default to the frame's border
///     - `radius (relative | dictionary) = 2pt` the radius of the lang #(" ")
///   tag
///
///   - *highlight* default parameter for highlights
///     - `fill (color | gradient | tiling | none) = none` the background color of the highlight block
///     - `stroke (length | color | gradient | stroke | tiling | none) = none` the border of the highlight block
///     - `radius (relative | dictionary) = 3pt` the radius of the highlight block
///     - `code-style (function) = it => it` a style function to apply to the highlighted content
///     - `sticky (bool | auto) = auto` wether the highlight parts should merge from a line to the next (the stroke and radius are changed accordingly), `auto` sets this parameter automatically: a highlight defined with `line` is sticky while others not
///     - `expand (alignment | auto | none) = auto` indicates the side on which the highlight should expand when going from a line to the next (`none` = no expansion, `left` = left side, `right` = right side, `center` = both sides), `auto` sets this parameter automatically: a highlight defined with `line` expand on both side while others don't #(" ")
///   expand
///
///   - *comment* default styling parameter for comments
///     - `style (function) = text.with(style: "italic")` a basic style to apply to all comments contents
///     - `indent ("frame" | "code" | "line" | "guideline") = "frame"` `"frame"` to align with the left of the frame; `"code"` to start at the same left inset as the code; `"line"` to have the same indentation as the targeted line; `"guideline"` to further draw indentation lines in the comment
///     - `fill (color | gradient | tiling | none) = luma(245)`: the background color of the comment, `none` is the same as the frame's background color
///     - `sep (length | color | gradient | stroke | tiling | dictionary: (top: ..., bottom: ...) | none )`: the separators at the `top` or `bottom` between the code and other comments that don't have a separator on the shared side, if it is not a dictionary the style applies to both separators
///     - `marker (content | none) = none`: the marker of the comment
///     - `marker-fill (color | gradient | tiling | auto | none)`: the background color of the comment's marker, `auto` is the comment's background color, `none` is the numbers column background color
///     - `marker-placement ("numbers" | "markers") = "numbers"`: the placement of the marker inside the numbers #(" ")
///   column
///
///   - *jump* default styling parameter for jumps
///     - `comment (content | function | none) = none` the default comment content associated to jumps, a function takes the bounds of the jump `from` and `to` as arguments
///     - `style`, `indent`, `fill`, `sep`, `marker`, `marker-fill`, `marker-placement` as for `comment`, `auto` is the default value for all of these and it means taking the corresponding `comment` #(" ")
///   parameter
///
///   - *diff* the settings of diffs, as for `set-uraw-diff`
///
/// -> content
#let set-uraw(..args) = {
  let lang = args.pos()
  let settings = normalize-settings(args.named(), uraw-spec)
  for sec in uraw-spec.categories.keys() {
    if sec in settings {
      category-setter(sec, arguments(..lang, ..settings.at(sec)))
    }
  }
  if "diff" in settings {
    update-diff(settings.diff, resolve-args(arguments(..lang)).first())
  }
}

// TODO add header and footer content to `uraw` doc

/// Reset the uraw configuration to its default value, specific to a language if one is mentioned.
///
/// #example(`
/// #reset-uraw()
/// `)
///
/// - lang (arguments): The optional language name as a positional arguments.
///
/// -> content
#let reset-uraw(..lang) = {
  let lang = resolve-args(lang).first()
  if lang == none {
    uraw-config-state.update(initial-config)
  } else {
    uraw-lang-configs-state.update(lang-configs => {
      if lang in initial-lang-configs {
        lang-configs.insert(lang, initial-lang-configs.at(lang))
      } else {
        let _ = lang-configs.remove(lang, default: none)
      }
      lang-configs
    })
  }
}

// -----------------------------------------------------------------------------
// Pseudo code
// -----------------------------------------------------------------------------

#let initial-pseudo-config = {
  let config = pseudo-pre-default
  config.header += (content: none)
  config.footer += (content: none)
  config
}

#let uraw-pseudo-config-state = state(
  "uraw-pseudo-config-state",
  initial-pseudo-config,
)

/// The settings of a category of pseudo code, the given ones taking precedence over the configured ones (in a context).
///
/// - category (str):
/// - args (dictionary): The normalized settings (see `normalize-settings`).
/// -> dictionary
#let pseudo-category-parser(category, args) = ut.filter-add-dict(
  uraw-pseudo-config-state.get().at(category),
  args.at(category, default: (:)),
)

/// Get the settings of pseudo code (in a context).
///
/// -> dictionary
#let get-uraw-pseudo() = uraw-pseudo-config-state.get()

/// Set the settings of pseudo code, by category (**general**, **frame**, **header**, **footer**, **numbers**, **code**) or flat (`category-key`, with the shortcuts `width`, `breakable`, `sharp-page-break`, `start`, `end`, `line-spacing`, `indentation`, `indent-size`, `style`, the general settings, and `numbers: format` for the format of the numbers). They are the same as for raw code, except for the code settings **indent-size** (length): the width of an indentation level, **style** (none | function): the style of the lines (`none` for the style of the document, or a function applied to the content of each line), and the general setting **algorithm-figure** (bool): wether a figure containing pseudo code is an "Algorithm" (with its own number) instead of a "Figure".
/// -> content
#let set-uraw-pseudo(..args) = {
  assert(
    args.pos().len() == 0,
    message: "The settings of pseudo code do not depend on a language.",
  )
  let settings = normalize-settings(args.named(), pseudo-spec)
  uraw-pseudo-config-state.update(config => {
    for (category, value) in settings {
      config.at(category) = ut.filter-add-dict(config.at(category), value)
    }
    return config
  })
}

/// Reset the settings of pseudo code to their initial value.
/// -> content
#let reset-uraw-pseudo() = uraw-pseudo-config-state.update(
  initial-pseudo-config,
)

// -----------------------------------------------------------------------------
// Diff
// -----------------------------------------------------------------------------

/// The settings specific to diffs, by category (in a context): the global ones, overridden by the ones of the language if one is given.
///
/// - lang (none, str):
/// -> dictionary
#let uncontext-diff-getter(lang) = {
  let diff = uraw-config-state.get().diff
  let lang-diff = if lang == none { (:) } else {
    uraw-lang-configs-state
      .get()
      .at(lang, default: (:))
      .at("diff", default: (:))
  }
  for (category, value) in lang-diff {
    diff.insert(category, diff.at(category, default: (:)) + value)
  }
  diff
}

// The settings of diffs are the ones of uraw, overridden by the ones stored for diffs (global, then of the language)
#let diff-category-parser(category, args, lang) = ut.filter-add-dict(
  (
    if category in diff-categories { (:) } else {
      uncontext-category-getter(category, lang)
    }
      + uncontext-diff-getter(lang).at(category, default: (:))
  ),
  args.at(category, default: (:)),
)

/// Get the settings specific to diffs (in a context), the other ones being the ones of `uraw`, specific to a language if one is mentioned.
///
/// - lang (arguments): The optional language name as a positional argument.
/// -> dictionary
#let get-uraw-diff(..lang) = uncontext-diff-getter(resolve-args(lang).first())

/// Set the settings of diffs, specific to a language if one is mentioned (as a positional argument), by category or flat, overriding the ones of `uraw` for diffs: the ones of `uraw` (see `uraw-set`), and the ones specific to diffs: \ **diff-marker**: **visible** (bool, also given by `diff-marker: bool`), **unchanged** (content): the diff marker of the unchanged lines \ **old** and **new**: **diff-marker** (content): the diff marker of the changed lines, **numbers-color** and **numbers-fill**: the color and background of the numbers of the changed lines (`auto` for the ones of the numbers), **fill**: the background of the changes \ the general settings **line-reference** (function): how a reference to a line is displayed after "Listing n", a function of the number and of the version (`"old"` or `"new"`), **columns** (int | array): the widths of the codes, as for a grid: one column merges the codes, two columns separate them (`(auto, auto)` by default, which become `(1fr, 1fr)` when the codes are too large), **column-gutter** (relative): the space between the separated codes (with the separator at its center), **blank-fill**: the background of the space left by a line which is only in one version, **sep**: the separator between the separated codes.
/// -> content
#let set-uraw-diff(..args) = {
  let (lang, settings) = resolve-args(args)
  update-diff(normalize-settings(settings, diff-spec), lang)
}

/// Reset the settings of diffs to their initial value, the ones of a language if one is mentioned (removed).
/// -> content
#let reset-uraw-diff(..lang) = {
  let lang = resolve-args(lang).first()
  if lang == none {
    uraw-config-state.update(config => config + (diff: initial-config.diff))
  } else {
    uraw-lang-configs-state.update(lang-configs => {
      if lang in lang-configs {
        let _ = lang-configs.at(lang).remove("diff", default: none)
      }
      lang-configs
    })
  }
}

// -----------------------------------------------------------------------------
// Themes
// -----------------------------------------------------------------------------

#let flatten-theme(theme, spec) = {
  let flat = (:)
  for (category, settings) in theme {
    ut.check-keys(settings, spec.categories.at(category), "`" + category + "`")
    for (k, v) in settings {
      // (a name or icon of the lang tag `none` would hide the ones of the languages)
      if category == "lang-tag" and k in ("name", "icon") and v == none {
        continue
      }
      flat.insert(if k == "visible" { category } else { category + "-" + k }, v)
    }
  }
  flat
}

#let merge-categories(base, pre-theme) = (
  base
    + pre-theme
      .pairs()
      .map(((c, s)) => (c, base.at(c, default: (:)) + s))
      .to-dict()
)

#let complete-pre-theme(pre-theme) = {
  ut.check-keys(
    pre-theme,
    uraw-spec.categories.keys() + ("diff",),
    "a pre-theme",
  )
  ut.check-keys(
    pre-theme.at("diff", default: (:)),
    diff-spec.categories.keys(),
    "the `diff` of a pre-theme",
  )
  let diff = merge-categories(pre-default.diff, pre-theme.at(
    "diff",
    default: (:),
  ))
  merge-categories(pre-default, pre-theme) + (diff: diff)
}

/// Make a theme of `uraw` and `uraw-diff` from a pre-theme.
///
/// - pre-theme (dictionary): The pre-theme to format, look at `themes.pre-themes.pre-default` for an example.
/// -> dictionary
#let make(pre-theme) = {
  let pre-theme = complete-pre-theme(pre-theme)
  let diff = pre-theme.remove("diff")
  flatten-theme(pre-theme, uraw-spec) + (diff: flatten-theme(diff, diff-spec))
}

/// Make a theme of `uraw-pseudo` from a pre-theme.
///
/// - pre-theme (dictionary): The pre-theme to format, look at `themes.pre-themes.pseudo-pre-default` for an example.
/// -> dictionary
#let make-pseudo(pre-theme) = {
  ut.check-keys(pre-theme, pseudo-spec.categories.keys(), "a pre-theme")
  flatten-theme(merge-categories(pseudo-pre-default, pre-theme), pseudo-spec)
}
