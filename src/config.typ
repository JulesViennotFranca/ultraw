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
    "general",
    "frame",
    "header",
    "footer",
    "numbers",
    "code",
    "comment",
    "jump",
    "highlight",
    "lang-tag",
  ),
  (
    width: ("frame", "width"),
    breakable: ("frame", "breakable"),
    sharp-page-break: ("frame", "sharp-page-break"),
    start: ("numbers", "start"),
    end: ("numbers", "end"),
    line-spacing: ("code", "line-spacing"),
    indentation: ("code", "indentation"),
    indent-size: ("code", "indent-size"),
    theme: ("code", "theme"),
    indented-line-return: ("code", "indented-line-return"),
  )
    + pre-default.general.keys().map(k => (k, ("general", k))).to-dict(),
  ("markers", "comments", "jumps", "highlights", "follows", "precedes"),
)

#let diff-categories = ("diff-marker", "old", "new")

#let diff-spec = make-spec(
  pre-default
    + (general: pre-default.general + pre-default.diff.general)
    + diff-categories.map(c => (c, pre-default.diff.at(c))).to-dict(),
  uraw-spec.categories.keys() + diff-categories,
  (
    width: ("frame", "width"),
    breakable: ("frame", "breakable"),
    sharp-page-break: ("frame", "sharp-page-break"),
    start: ("numbers", "start"),
    end: ("numbers", "end"),
    line-spacing: ("code", "line-spacing"),
    indentation: ("code", "indentation"),
    indent-size: ("code", "indent-size"),
    theme: ("code", "theme"),
  )
    + (pre-default.general + pre-default.diff.general)
      .keys()
      .map(k => (k, ("general", k)))
      .to-dict(),
  ("follows", "precedes"),
)

#let pseudo-spec = make-spec(
  pseudo-pre-default,
  ("general", "frame", "header", "footer", "numbers", "code"),
  (
    width: ("frame", "width"),
    breakable: ("frame", "breakable"),
    sharp-page-break: ("frame", "sharp-page-break"),
    start: ("numbers", "start"),
    end: ("numbers", "end"),
    line-spacing: ("code", "line-spacing"),
    indentation: ("code", "indentation"),
    indent-size: ("code", "indent-size"),
    style: ("code", "style"),
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

/// Get the uraw configurations, specific to a language if one is mentioned.
///
/// - lang (none, str): The language name. If set to `none`, the default configurations are returned.
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

// Set the uraw configurations, specific to a language if one is mentioned.
///
/// - lang (none, str): The language name. If set to `none`, the default configurations are updated.
/// - args (arguments): uraw settings, by category: **frame**, **header**, **footer**, **numbers**, **marker** (`marker: bool` for its visibility), **code**, **comment**, **jump**, **lang-tag**, **diff** (the settings specific to diffs, see `uraw-diff-set`) (e.g. `header: (fill: red)`), or flat as `category-key` (e.g. `header-fill: red`), except for `width`, `breakable`, `sharp-page-break` (frame), `start`, `end` (numbers), `line-spacing`, `indentation`, `indent-size`, `theme` (code), the format of the numbers given by `numbers: format` (`none` to hide them) and the visibility of the lang tag given by `lang-tag: bool`. The lang tag settings include **color** (auto | color): the color of its text, `auto` for the color of the code of the first line. The frame settings include **sharp-page-break** (bool): wether the frame has no radius at page breaks: it is then drawn by its cells (the cells on its sides taking its stroke and radius, the cells without fill taking its fill), and otherwise by its block, which clips the cells (its fill, stroke and radius being repeated on each page). The code settings include **indent-size** (auto | int): the number of spaces of an indentation level, `auto` to infer it from the code (the most frequent increase of the leading spaces between consecutive lines, the tab size of the raw block when no line is indented) \ **indented-line-return** (bool): wether the parts of a line broken because it is too long start at the indentation of the line (when it leaves at least half of the width) rather than at the start of the code \ **theme** (auto | none | path | bytes): the syntax highlighting theme of the code (as for `raw`), `auto` for the one of the raw block \ **color** (auto | color | function): the color of the text of the code that the theme does not color (`auto` for the color of the text), or a function of the line number as for `fill`; the numbers, the comments (under their style), the header and the footer take it when their color is `auto`, and the markers (of the lines and of the comments) take the color of the numbers. And the general settings: **coloring-follow-numbers** (bool): when the numbers are visible, wether the fill and color functions (of the code and of the number) are applied to the displayed line number (which can jump) or to the position of the line \ **line-reference** (none | auto | function): how a reference to the line `k` of a labelled figure (`@label.k`) is displayed after "Listing n": `none` for no line references, `auto` for "Listing n.k", or a function of `k` giving the text to add (", line k" by default) \ **default-stroke-thickness** (length): the length of the strokes and separators given without one (as a color), `.05em` by default \ **markers-over-numbers** (bool): wether the line markers are shown over the numbers (in their column) rather than in a marker column
/// -> content
#let set-uraw(..args) = {
  // The language, if one is given
  let lang = args.pos()
  let settings = normalize-settings(args.named(), uraw-spec)
  for sec in uraw-spec.categories.keys() {
    if sec in settings {
      category-setter(sec, arguments(..lang, ..settings.at(sec)))
    }
  }
}

/// Reset the uraw configurations to their initial value, specific to a language if one is mentioned.
///
/// - lang (none, str): The language name. If set to `none`, the default configurations are reset (the configurations specific to languages are kept), otherwise the configurations of the language are reset.
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

// The settings of diffs are the ones of uraw, overridden by the ones stored for diffs
#let diff-category-parser(category, args, lang) = ut.filter-add-dict(
  (
    if category in diff-categories { (:) } else {
      uncontext-category-getter(category, lang)
    }
      + uraw-config-state.get().diff.at(category, default: (:))
  ),
  args.at(category, default: (:)),
)

/// Get the settings specific to diffs (in a context), the other ones being the ones of `uraw`.
/// -> dictionary
#let get-uraw-diff() = uraw-config-state.get().diff

/// Set the settings of diffs, by category or flat, overriding the ones of `uraw` for diffs: the ones of `uraw` (see `uraw-set`), and the ones specific to diffs: \ **diff-marker**: **visible** (bool, also given by `diff-marker: bool`), **inset** (auto | relative | dictionary, only left and right, `auto` for the inset of the numbers), **unchanged** (content): the diff marker of the unchanged lines \ **old** and **new**: **diff-marker** (content): the diff marker of the changed lines, **numbers-color** and **numbers-fill**: the color and background of the numbers of the changed lines (`auto` for the ones of the numbers), **fill**: the background of the changes \ the general settings **line-reference** (function): how a reference to a line is displayed after "Listing n", a function of the number and of the version (`"old"` or `"new"`), **columns** (int | array): the widths of the codes, as for a grid: one column merges the codes, two columns separate them (`(auto, auto)` by default, which become `(1fr, 1fr)` when the codes are too large), **column-gutter** (relative): the space between the separated codes (with the separator at its center), **blank-fill**: the background of the space left by a line which is only in one version, **sep**: the separator between the separated codes.
/// -> content
#let set-uraw-diff(..args) = {
  assert(
    args.pos().len() == 0,
    message: "The settings of diffs do not depend on a language.",
  )
  let settings = normalize-settings(args.named(), diff-spec)
  uraw-config-state.update(config => {
    for (category, value) in settings {
      config.diff.insert(
        category,
        config.diff.at(category, default: (:)) + value,
      )
    }
    return config
  })
}

/// Reset the settings of diffs to their initial value.
/// -> content
#let reset-uraw-diff() = uraw-config-state.update(config => {
  config.diff = initial-config.diff
  return config
})

// -----------------------------------------------------------------------------
// Themes
// -----------------------------------------------------------------------------

/// The flat settings (`category-key`) of the categories of a theme.
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

/// The settings by category of `base` overridden by the ones of `pre-theme` (a setting is replaced, not merged with the one of `base`).
#let merge-categories(base, pre-theme) = (
  base
    + pre-theme
      .pairs()
      .map(((c, s)) => (c, base.at(c, default: (:)) + s))
      .to-dict()
)

/// A pre-theme of `uraw` completed with the default settings (`pre-default`), the ones of `diff` included.
#let complete-pre-theme(pre-theme) = {
  ut.check-keys(
    pre-theme,
    uraw-spec.categories.keys() + ("diff",),
    "a pre-theme",
  )
  let diff = merge-categories(pre-default.diff, pre-theme.at(
    "diff",
    default: (:),
  ))
  merge-categories(pre-default, pre-theme) + (diff: diff)
}

/// Make a theme of `uraw` from a pre-theme (the settings by category which differ from the default ones, as the ones of `pre-themes`, with the settings specific to diffs in `diff`), given with `uraw(..theme)` or `set-uraw(..theme)`: its flat settings (all of them, the missing ones being the default ones, so that a theme does not depend on the settings set before), without the settings of diffs, and the `none` name and icon of the lang tag (so that the ones of the languages apply). The settings given after the theme override it (`uraw(..theme, header: [Title])` keeps the other header settings of the theme).
///
/// - pre-theme (dictionary):
/// -> dictionary
#let make-theme(pre-theme) = {
  let pre-theme = complete-pre-theme(pre-theme)
  let theme = pre-theme
    .pairs()
    .filter(((k, _)) => k in uraw-spec.categories)
    .to-dict()
  flatten-theme(theme, uraw-spec)
}

/// Make a theme of `uraw-diff` from a pre-theme (see `make-theme`), given with `uraw-diff(..theme)` or `set-uraw-diff(..theme)`: its flat settings, the ones of its `diff` overriding the other ones.
///
/// - pre-theme (dictionary):
/// -> dictionary
#let make-diff-theme(pre-theme) = {
  let pre-theme = complete-pre-theme(pre-theme)
  let theme = pre-theme
    .pairs()
    .filter(((k, _)) => k in uraw-spec.categories)
    .to-dict()
  for (k, v) in pre-theme.at("diff", default: (:)) {
    theme.insert(k, theme.at(k, default: (:)) + v)
  }
  flatten-theme(theme, diff-spec)
}

/// Make a theme of `uraw-pseudo` from a pre-theme of pseudo code (the settings by category which differ from `pseudo-pre-default`), given with `uraw-pseudo(..theme)` or `set-uraw-pseudo(..theme)`: its flat settings (all of them, the missing ones being the default ones).
///
/// - pre-theme (dictionary):
/// -> dictionary
#let make-pseudo-theme(pre-theme) = {
  ut.check-keys(pre-theme, pseudo-spec.categories.keys(), "a pre-theme")
  flatten-theme(merge-categories(pseudo-pre-default, pre-theme), pseudo-spec)
}
