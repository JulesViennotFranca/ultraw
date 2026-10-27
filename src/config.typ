#import "highlight.typ" as hl
#import "../themes/icons.typ": icons
#import "../themes/uraw.typ": default
#import "../themes/pseudo.typ": default as pseudo-default
#import "utils.typ" as ut

// -----------------------------------------------------------------------------
// Initialization
// -----------------------------------------------------------------------------

#let initial-config = {
  let config = default
  config.header += (content: none)
  config.footer += (content: none)
  // The highlights are stored as given, their missing style fields take the `highlight` settings when displayed
  let _ = hl.check-pre-highlights(config.highlights, config.highlight.keys())
  config
}

#let initial-lang-configs = {
  let configs = (:)
  for (lang, lt) in icons { configs.insert(lower(lang), (lang-tag: lt)) }
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
  default,
  (
    "general",
    "frame",
    "header",
    "footer",
    "number",
    "code",
    "comment",
    "jump",
    "highlight",
    "lang-tag",
  ),
  (
    width: ("frame", "width"),
    height: ("frame", "height"),
    breakable: ("frame", "breakable"),
    start: ("number", "start"),
    end: ("number", "end"),
    line-spacing: ("code", "line-spacing"),
    indentation: ("code", "indentation"),
  )
    + default.general.keys().map(k => (k, ("general", k))).to-dict(),
  ("markers", "comments", "jumps", "highlights", "follows", "precedes"),
)

#let diff-categories = ("diff-marker", "old", "new")

#let diff-spec = make-spec(
  default
    + (general: default.general + default.diff.general)
    + diff-categories.map(c => (c, default.diff.at(c))).to-dict(),
  uraw-spec.categories.keys() + diff-categories,
  (
    width: ("frame", "width"),
    height: ("frame", "height"),
    breakable: ("frame", "breakable"),
    start: ("number", "start"),
    end: ("number", "end"),
    line-spacing: ("code", "line-spacing"),
    indentation: ("code", "indentation"),
  )
    + (default.general + default.diff.general)
      .keys()
      .map(k => (k, ("general", k)))
      .to-dict(),
  ("follows", "precedes"),
)

#let pseudo-spec = make-spec(
  pseudo-default,
  ("general", "frame", "header", "footer", "number", "code"),
  (
    width: ("frame", "width"),
    height: ("frame", "height"),
    breakable: ("frame", "breakable"),
    start: ("number", "start"),
    end: ("number", "end"),
    line-spacing: ("code", "line-spacing"),
    indentation: ("code", "indentation"),
    indent-size: ("code", "indent-size"),
    style: ("code", "style"),
  )
    + pseudo-default.general.keys().map(k => (k, ("general", k))).to-dict(),
  (),
)

#let normalize-settings(args, spec) = {
  let settings = (:)
  let flat = ()

  for (name, value) in args {
    if name in spec.categories {
      let parameters = spec.categories.at(name)

      settings.insert(name, if type(value) == dictionary {
        value
      } else if type(value) == bool and "visible" in parameters {
        (visible: value)
      } else if type(value) == bool and "format" in parameters {
        // `false` hides the element, `true` shows it with the default format
        (format: if value { auto } else { none })
      } else if "format" in parameters
        and (
          value in (none, auto) or type(value) in (function, str)
        ) {
        (format: value)
      } else if "content" in parameters {
        (content: value)
      } else {
        panic("The `" + name + "` settings must be a dictionary.")
      })
    } else if name in spec.additional {
      settings.insert(name, value)
    } else if name in spec.flat-names {
      flat.push((spec.flat-names.at(name), value))
    } else {
      panic("Unknown uraw setting `" + name + "`.")
    }
  }

  // The settings given by category must be known
  for (name, value) in settings {
    if name in spec.categories {
      ut.check-keys(value, spec.categories.at(name), "`" + name + "`")
    }
  }

  // The flat settings take precedence over the nested ones
  for ((section, key), value) in flat {
    settings.insert(
      section,
      settings.at(section, default: (:)) + ((key): value),
    )
  }

  settings
}

// -----------------------------------------------------------------------------
// Highlights
// -----------------------------------------------------------------------------

/// The highlights do not depend on the language of the code.
#let no-lang-highlights(args) = assert(
  args.pos().len() == 0,
  message: "The highlights do not depend on the language, they are given by name.",
)

/// Check and store the highlights.
#let update-highlights(pre-highlights) = {
  let _ = hl.check-pre-highlights(
    pre-highlights,
    uncontext-category-getter("highlight", none).keys(),
  )
  uraw-config-state.update(config => {
    config.highlights = pre-highlights
    return config
  })
}

/// The current highlights, by name.
///
/// -> dictionary
#let uraw-list-highlights() = context uncontext-category-getter(
  "highlights",
  none,
)

/// Add highlights.
///
/// - args (arguments): The added highlights as named arguments, the names given will be used to identify the corresponding highlights.
/// -> content
#let uraw-add-highlights(..args) = context {
  no-lang-highlights(args)
  update-highlights(
    uncontext-category-getter("highlights", none) + args.named(),
  )
}

/// Redefine existing highlights.
///
/// - args (arguments): The redefined highlights as named arguments, the names being the ones of existing highlights.
/// -> content
#let uraw-set-highlights(..args) = context {
  no-lang-highlights(args)
  let old = uncontext-category-getter("highlights", none)
  for name in args.named().keys() {
    assert(
      name in old,
      message: "There is no highlight named `"
        + name
        + "`, use `uraw-add-highlights` to add one.",
    )
  }
  update-highlights(old + args.named())
}

/// Remove highlights.
///
/// - args (arguments): The names of the removed highlights.
/// -> content
#let uraw-remove-highlights(..args) = {
  uraw-config-state.update(config => {
    for h in args.pos() { let _ = config.highlights.remove(h, default: none) }
    return config
  })
}

/// Reset the highlights to their initial value.
///
/// -> content
#let uraw-reset-highlights() = {
  uraw-config-state.update(config => {
    config.highlights = initial-config.highlights
    return config
  })
}

// -----------------------------------------------------------------------------
// Main functions
// -----------------------------------------------------------------------------

/// Get the uraw configurations, specific to a language if one is mentioned.
///
/// - lang (none, str): The language name. If set to `none`, the default configurations are returned.
/// -> dictionary
#let uraw-get(..lang) = (
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
/// - args (arguments): uraw settings, by category: **frame**, **header**, **footer**, **number**, **marker** (`marker: bool` for its visibility), **code**, **comment**, **jump**, **lang-tag**, **highlights**, **diff** (the settings specific to diffs, see `uraw-diff-set`) (e.g. `header: (fill: red)`), or flat as `category-key` (e.g. `header-fill: red`), except for `width`, `height`, `breakable` (frame), `start`, `end` (number), `line-spacing`, `indentation` (code), the format of the numbers given by `number: format`, and the visibility of the lang tag given by `lang-tag: bool`, and the general settings: **coloring-follow-number** (bool): when the numbers are visible, wether the fill and color functions (of the code and of the number) are applied to the displayed line number (which can jump) or to the position of the line \ **line-reference** (none | auto | function): how a reference to the line `k` of a labelled figure (`@label.k`) is displayed after "Listing n": `none` for no line references, `auto` for "Listing n.k", or a function of `k` giving the text to add (", line k" by default) \ **default-stroke-thickness** (length): the length of the strokes and separators given without one (as a color), `.05em` by default
/// -> content
#let uraw-set(..args) = {
  // The language, if one is given
  let lang = args.pos()
  let settings = normalize-settings(args.named(), uraw-spec)
  for sec in uraw-spec.categories.keys() {
    if sec in settings {
      category-setter(sec, arguments(..lang, ..settings.at(sec)))
    }
  }
  if "highlights" in settings {
    uraw-set-highlights(..lang, ..settings.highlights)
  }
}

/// Reset the uraw configurations to their initial value, specific to a language if one is mentioned.
///
/// - lang (none, str): The language name. If set to `none`, the default configurations are reset (the configurations specific to languages are kept), otherwise the configurations of the language are reset.
/// -> content
#let uraw-reset(..lang) = {
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
  let config = pseudo-default
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
#let uraw-pseudo-get() = uraw-pseudo-config-state.get()

/// Set the settings of pseudo code, by category (**general**, **frame**, **header**, **footer**, **number**, **code**) or flat (`category-key`, with the shortcuts `width`, `height`, `breakable`, `start`, `end`, `line-spacing`, `indentation`, `indent-size`, `style`, the general settings, and `number: format` for the format of the numbers). They are the same as for raw code, except for the code settings **indent-size** (length): the width of an indentation level, **style** (none | function): the style of the lines (`none` for the style of the document, or a function applied to the content of each line), and the general setting **algorithm-figure** (bool): wether a figure containing pseudo code is an "Algorithm" (with its own number) instead of a "Figure".
/// -> content
#let uraw-pseudo-set(..args) = {
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
#let uraw-pseudo-reset() = uraw-pseudo-config-state.update(initial-pseudo-config)

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
#let uraw-diff-get() = uraw-config-state.get().diff

/// Set the settings of diffs, by category or flat, overriding the ones of `uraw` for diffs: the ones of `uraw` (see `uraw-set`), and the ones specific to diffs: \ **diff-marker**: **visible** (bool, also given by `diff-marker: bool`), **inset** (auto | relative | dictionary, only left and right, `auto` for the inset of the numbers), **unchanged** (content): the diff marker of the unchanged lines \ **old** and **new**: **diff-marker** (content): the diff marker of the changed lines, **number-color** and **number-fill**: the color and background of the numbers of the changed lines (`auto` for the ones of the numbers), **fill**: the background of the changes \ the general settings **line-reference** (function): how a reference to a line is displayed after "Listing n", a function of the number and of the version (`"old"` or `"new"`), **columns** (int | array): the widths of the codes, as for a grid: one column merges the codes, two columns separate them (`(auto, auto)` by default, which become `(1fr, 1fr)` when the codes are too large), **column-gutter** (relative): the space between the separated codes (with the separator at its center), **blank-fill**: the background of the space left by a line which is only in one version, **sep**: the separator between the separated codes.
/// -> content
#let uraw-diff-set(..args) = {
  assert(
    args.pos().len() == 0,
    message: "The settings of diffs do not depend on a language.",
  )
  let settings = normalize-settings(args.named(), diff-spec)
  uraw-config-state.update(config => {
    for (category, value) in settings {
      config.diff.at(category) = config.diff.at(category, default: (:)) + value
    }
    return config
  })
}

/// Reset the settings of diffs to their initial value.
/// -> content
#let uraw-diff-reset() = uraw-config-state.update(config => {
  config.diff = initial-config.diff
  return config
})
