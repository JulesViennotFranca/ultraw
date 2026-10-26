#import "highlight.typ" as hl
#import "../themes/icons.typ": icons
#import "../themes/main.typ": default
#import "utils.typ" as ut

/// The initial settings.
#let initial-config = {
  let config = default
  config.header += (content: none)
  config.footer += (content: none)
  config.highlights = ut.map-dict(config.highlights, hl.format-pre-highlight)
  config
}

/// The initial settings specific to languages.
#let initial-lang-configs = {
  // The languages are case insensitive
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
// Settings names
// -----------------------------------------------------------------------------

/// Describe the settings names: the sections with their keys, the general settings (not in a section) and the shortcuts (settings directly accessible by their name).
///
/// - defaults (dictionary): The default settings.
/// - section-names (array): The names of the sections.
/// - general (array): The names of the general settings.
/// - shortcuts (dictionary): For each shortcut, its section and key.
/// -> dictionary
#let settings-spec(defaults, section-names, general, shortcuts) = {
  let sections = (:)
  for name in section-names {
    sections.insert(
      name,
      defaults.at(name).keys()
        + if name in ("header", "footer") { ("content",) } else { () },
    )
  }

  // The flat names of the settings: `section-key`, except for the shortcuts and the visibility (given by `section: bool`)
  let flat-names = (:)
  for (section, keys) in sections {
    for key in keys {
      if key != "visible" and not (section, key) in shortcuts.values() {
        flat-names.insert(section + "-" + key, (section, key))
      }
    }
  }

  (
    sections: sections,
    general: general,
    flat-names: flat-names + shortcuts,
  )
}

/// The settings names of raw code.
#let raw-spec = settings-spec(
  default,
  (
    "frame",
    "header",
    "footer",
    "numbering",
    "code",
    "comment",
    "jump",
    "lang-tag",
  ),
  ("coloring-follow-numbering", "line-reference", "default-stroke-length"),
  (
    width: ("frame", "width"),
    height: ("frame", "height"),
    breakable: ("frame", "breakable"),
    start: ("numbering", "start"),
    end: ("numbering", "end"),
    line-spacing: ("code", "line-spacing"),
    indentation: ("code", "indentation"),
    indent-size: ("code", "indent-size"),
  ),
)

/// The general settings (not in a section).
#let general = raw-spec.general

/// The sections of the settings specific to diffs.
#let diff-sections = ("markers", "old", "new")

/// The general settings specific to diffs.
#let diff-general = (
  "line-reference",
  "columns",
  "column-gutter",
  "no-diff-marker",
  "blank-fill",
  "sep",
)

/// The settings names specific to diffs.
#let diff-only-spec = settings-spec(
  default.diff,
  diff-sections,
  diff-general,
  (:),
)

/// Convert the settings given as arguments (nested by section, or flat) to nested settings.
///
/// - args (dictionary): The named arguments.
/// - pass (array): Other arguments names to keep as they are.
/// - spec (dictionary): The settings names, see `settings-spec`.
/// -> dictionary
#let normalize-settings(args, pass: (), spec: raw-spec) = {
  let settings = (:)
  let flat = ()

  for (name, value) in args {
    if name in spec.sections {
      // Sections given by a single value
      let keys = spec.sections.at(name)
      settings.insert(name, if type(value) == dictionary {
        value
      } else if type(value) == bool and "visible" in keys {
        (visible: value)
      } else if "format" in keys
        and (
          value in (none, auto) or type(value) in (function, str)
        ) {
        (format: value)
      } else if "content" in keys {
        (content: value)
      } else {
        panic("The `" + name + "` settings must be a dictionary.")
      })
    } else if name in spec.general or name in pass {
      settings.insert(name, value)
    } else if name in spec.flat-names {
      flat.push((spec.flat-names.at(name), value))
    } else {
      panic("Unknown uraw setting `" + name + "`.")
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

/// Update the settings specific to diffs.
///
/// - args (dictionary): The settings, by section or flat.
/// -> content
#let update-diff(args) = {
  let settings = normalize-settings(args, spec: diff-only-spec)
  uraw-config-state.update(conf => {
    for (key, value) in settings {
      if key in diff-general {
        conf.diff.insert(key, value)
      } else {
        conf.diff.insert(key, ut.filter-add-dict(conf.diff.at(key), value))
      }
    }
    conf
  })
}

// -----------------------------------------------------------------------------
// General
// -----------------------------------------------------------------------------

/// Get a general setting, specific to a language if one is mentioned.
#let uraw-uncontext-get-general(lang, key) = {
  let value = uraw-config-state.get().at(key)
  if lang != none {
    uraw-lang-configs-state
      .get()
      .at(lower(lang), default: (:))
      .at(key, default: value)
  } else {
    value
  }
}

/// Set a general setting, specific to a language if one is mentioned.
#let uraw-set-general(lang, key, value) = if lang == none {
  uraw-config-state.update(conf => {
    conf.insert(key, value)
    conf
  })
} else {
  let lang = lower(lang)
  uraw-lang-configs-state.update(confs => {
    if not lang in confs { confs.insert(lang, (:)) }
    confs.at(lang).insert(key, value)
    confs
  })
}

/// Get a general setting given as argument, or else the configured one.
#let parse-general(lang: none, key, ..args) = {
  args.named().at(key, default: uraw-uncontext-get-general(lang, key))
}

#let filter-add-lang-to-conf(conf, lang-confs, lang, k) = ut.filter-add-dict(
  conf.at(k),
  lang-confs.at(lang, default: (:)).at(k, default: (:)),
)

#let add-lang-to-conf(conf, lang-confs, lang, k) = (
  conf.at(k) + lang-confs.at(lang, default: (:)).at(k, default: (:))
)

/// Resolve the language, given either as the named argument `lang` or as the first positional (string) argument.
///
/// - lang (none, str): The value of the named `lang` argument.
/// - args (arguments): The remaining arguments.
/// -> array: the resolved language and the remaining positional arguments
#let resolve-lang(lang, args) = {
  let pos = args.pos()
  if lang == none and pos.len() > 0 and type(pos.first()) == str {
    (lower(pos.first()), pos.slice(1))
  } else {
    (if type(lang) == str { lower(lang) } else { lang }, pos)
  }
}

/// Return `default` if `lang` is `none` else execute `language` with input `lang`.
#let branch-config(lang, default, language) = {
  if lang == none {
    default
  } else if type(lang) == str {
    // The languages are case insensitive
    language(lower(lang))
  } else {
    panic(
      "To run this function on the default config, use it with no arguments. To run it on a language's config, provide the name of the language as argument.",
    )
  }
}

/// Get the general settings (`coloring-follow-numbering`, `line-reference`, `default-stroke-length`), specific to a language if one is mentioned. They are set with `uraw-set`.
///
/// - lang (none, str): The language name. If set to `none`, the default settings are returned.
/// -> dictionary
#let uraw-get-general(lang: none, ..args) = context {
  let lang = resolve-lang(lang, args).first()
  general.map(key => (key, uraw-uncontext-get-general(lang, key))).to-dict()
}

// -----------------------------------------------------------------------------
// Frame
// -----------------------------------------------------------------------------

#let uraw-uncontext-get-frame(lang) = branch-config(
  lang,
  uraw-config-state.get().frame,
  lang => filter-add-lang-to-conf(
    uraw-config-state.get(),
    uraw-lang-configs-state.get(),
    lang,
    "frame",
  ),
)

/// Get the frame configurations, specific to a language if one is mentioned.
///
/// - lang (none, str): The language name. If set to `none`, the default configurations are returned.
/// -> dictionary
#let uraw-get-frame(lang: none, ..args) = context uraw-uncontext-get-frame(
  resolve-lang(lang, args).first(),
)

/// Set the frame configurations, specific to a language if one is mentioned.
///
/// - lang (none, str): The language name. If set to `none`, the default configurations are updated.
/// - args (arguments): Frame settings (they are the same as the arguments of the `block` function): \ **breakable** (bool): wether the code block can be split accross pages \ **fill** (none | color | gradient | tiling): the background of the code block \ **height** (auto | relative | fraction) \ **radius** (relative | dictionary) \ **stroke** (none | length | color | gradient | stroke | tiling | dictionary) \ **width** (auto | relative)
/// -> content
#let uraw-set-frame(lang: none, ..args) = {
  let lang = resolve-lang(lang, args).first()
  let args = args.named()

  branch-config(
    lang,
    uraw-config-state.update(conf => {
      conf.frame = ut.filter-add-dict(conf.frame, args)
      conf
    }),
    lang => uraw-lang-configs-state.update(confs => {
      if not lang in confs { confs.insert(lang, (:)) }
      if not "frame" in confs.at(lang) { confs.at(lang).insert("frame", (:)) }
      confs.at(lang).frame += args
      confs
    }),
  )
}

#let parse-frame(lang: none, ..args) = {
  let lang = resolve-lang(lang, args).first()
  let args = args.named()

  let frame-ref = uraw-uncontext-get-frame(lang)
  if "frame" in args {
    ut.filter-add-dict(frame-ref, args.frame)
  } else {
    frame-ref
  }
}

// -----------------------------------------------------------------------------
// Header
// -----------------------------------------------------------------------------

#let uraw-uncontext-get-header(lang) = branch-config(
  lang,
  uraw-config-state.get().header,
  lang => filter-add-lang-to-conf(
    uraw-config-state.get(),
    uraw-lang-configs-state.get(),
    lang,
    "header",
  ),
)


/// Get the header configurations, specific to a language if one is mentioned.
///
/// - lang (none, str): The language name. If set to `none`, the default configurations are returned.
/// -> dictionary
#let uraw-get-header(lang: none, ..args) = context uraw-uncontext-get-header(
  resolve-lang(lang, args).first(),
)

/// Set the header configurations, specific to a language if one is mentioned.
///
/// - lang (none, str): The language name. If set to `none`, the default configurations are updated.
/// - args (arguments): Header settings: \ **alignment** (alignment): the alignment of the content inside of the header \ **code-aligned** (bool): wether the header block should start at the same x-offset as the code \ **fill** (none | auto | color | gradient | tiling): the background of the header, if set to `auto` it is the same as the code background \ **height** (auto | relative | fraction) \ **inset** (relative | dictionary) \ **repeat** (bool) wether the header should be repeated when there is a page break \ **sep** (auto | none | length | color | gradient | stroke | tiling | dictionary): the separation line between the header and the rest of the code block, if set to `auto` it is the same as the frame's stroke
/// -> content
#let uraw-set-header(lang: none, ..args) = {
  let (lang, args-p) = resolve-lang(lang, args)
  let args = args.named() + if args-p.len() > 0 { (content: args-p.at(0)) }

  branch-config(
    lang,
    uraw-config-state.update(conf => {
      conf.header = ut.filter-add-dict(conf.header, args)
      conf
    }),

    lang => uraw-lang-configs-state.update(confs => {
      if not lang in confs { confs.insert(lang, (:)) }
      if not "header" in confs.at(lang) { confs.at(lang).insert("header", (:)) }
      confs.at(lang).header += args
      confs
    }),
  )
}

#let parse-header(lang: none, ..args) = {
  let lang = resolve-lang(lang, args).first()
  let args = args.named()

  let header-ref = uraw-uncontext-get-header(lang)
  if "header" in args and type(args.header) == content {
    ut.filter-add-dict(header-ref, (content: args.header))
  } else if "header" in args {
    ut.filter-add-dict(header-ref, args.header)
  } else {
    header-ref
  }
}

// -----------------------------------------------------------------------------
// Footer
// -----------------------------------------------------------------------------

#let uraw-uncontext-get-footer(lang) = branch-config(
  lang,
  uraw-config-state.get().footer,
  lang => filter-add-lang-to-conf(
    uraw-config-state.get(),
    uraw-lang-configs-state.get(),
    lang,
    "footer",
  ),
)

/// Get the footer configurations, specific to a language if one is mentioned.
///
/// - lang (none, str): The language name. If set to `none`, the default configurations are returned.
/// -> dictionary
#let uraw-get-footer(lang: none, ..args) = context uraw-uncontext-get-footer(
  resolve-lang(lang, args).first(),
)

/// Set the footer configurations, specific to a language if one is mentioned.
///
/// - lang (none, str): The language name. If set to `none`, the default configurations are updated.
/// - args (arguments): Footer settings: \ **alignment** (alignment): the alignment of the content inside of the footer \ **code-aligned** (bool): wether the footer block should start at the same x-offset as the code \ **fill** (none | auto | color | gradient | tiling): the background of the footer, if set to `auto` it is the same as the code background \ **height** (auto | relative | fraction) \ **inset** (relative | dictionary) \ **repeat** (bool) wether the footer should be repeated when there is a page break \ **sep** (auto | none | length | color | gradient | stroke | tiling | dictionary): the separation line between the footer and the rest of the code block, if set to `auto` it is the same as the frame's stroke
/// -> content
#let uraw-set-footer(lang: none, ..args) = {
  let (lang, args-p) = resolve-lang(lang, args)
  let args = args.named() + if args-p.len() > 0 { (content: args-p.at(0)) }

  branch-config(
    lang,
    uraw-config-state.update(conf => {
      conf.footer = ut.filter-add-dict(conf.footer, args)
      conf
    }),

    lang => uraw-lang-configs-state.update(confs => {
      if not lang in confs { confs.insert(lang, (:)) }
      if not "footer" in confs.at(lang) { confs.at(lang).insert("footer", (:)) }
      confs.at(lang).footer += args
      confs
    }),
  )
}

#let parse-footer(lang: none, ..args) = {
  let lang = resolve-lang(lang, args).first()
  let args = args.named()

  let footer-ref = uraw-uncontext-get-footer(lang)
  if "footer" in args and type(args.footer) == content {
    ut.filter-add-dict(footer-ref, (content: args.footer))
  } else if "footer" in args {
    ut.filter-add-dict(footer-ref, args.footer)
  } else {
    footer-ref
  }
}

// -----------------------------------------------------------------------------
// Numbering
// -----------------------------------------------------------------------------

#let uraw-uncontext-get-numbering(lang) = branch-config(
  lang,
  uraw-config-state.get().numbering,
  lang => filter-add-lang-to-conf(
    uraw-config-state.get(),
    uraw-lang-configs-state.get(),
    lang,
    "numbering",
  ),
)

/// Get the numbering configurations, specific to a language if one is mentioned.
///
/// - lang (none, str): The language name. If set to `none`, the default configurations are returned.
/// -> dictionary
#let uraw-get-numbering(
  lang: none,
  ..args,
) = context uraw-uncontext-get-numbering(
  resolve-lang(lang, args).first(),
)

/// Set the numbering configurations, specific to a language if one is mentioned.
///
/// - lang (none, str): The language name. If set to `none`, the default configurations are updated.
/// - args (arguments): Numbering settings: \ **format** (none | auto | str | function): the format of the numbers, `none` for no numbers, `auto` for the numbers, a string in which the first `1` is replaced by the number (as `"1:"`), or a function of the number returning some content (`numbering: format` is a short form) \ **start** (int | label): the first number of the code block, or the label of a previous code block (or of a figure containing it) to continue its numbering \ **end** (int | none): the last number of the code block, take precedence over the `start` parameter \ **alignment** (alignment): the alignment of numbers \ **color** (color | gradient | tiling | function): the color of the numbers, if set to `auto` it is the same as the rest of the text in the document, if it is a function it is the result of the function applied to the number \ **fill** (none | auto | color | gradient | tiling | function): the background of the number, if set to `auto` it is the same as the code's background, if it is a function it is the result of the function applied to the number \ **inset** (auto | relative | dictionary): only left and right insets, `auto` for the inset of the code \ **sep** (auto | none | length | color | gradient | stroke | tiling | dictionary): the separation line between the numbers and the code
/// -> content
#let uraw-set-numbering(lang: none, ..args) = {
  let lang = resolve-lang(lang, args).first()
  let args = args.named()

  branch-config(
    lang,
    uraw-config-state.update(conf => {
      conf.numbering = ut.filter-add-dict(conf.numbering, args)
      conf
    }),

    lang => uraw-lang-configs-state.update(confs => {
      if not lang in confs { confs.insert(lang, (:)) }
      if not "numbering" in confs.at(lang) {
        confs.at(lang).insert("numbering", (:))
      }
      confs.at(lang).numbering += args
      confs
    }),
  )
}

#let parse-numbering(lang: none, ..args) = {
  let lang = resolve-lang(lang, args).first()
  let args = args.named()

  let numbering-ref = uraw-uncontext-get-numbering(lang)
  let numbering = if "numbering" in args {
    ut.filter-add-dict(numbering-ref, args.numbering)
  } else {
    numbering-ref
  }
  numbering + (visible: numbering.format != none)
}

// -----------------------------------------------------------------------------
// Code
// -----------------------------------------------------------------------------

#let uraw-uncontext-get-code(lang) = branch-config(
  lang,
  uraw-config-state.get().code,
  lang => filter-add-lang-to-conf(
    uraw-config-state.get(),
    uraw-lang-configs-state.get(),
    lang,
    "code",
  ),
)

/// Get the code configurations, specific to a language if one is mentioned.
///
/// - lang (none, str): The language name. If set to `none`, the default configurations are returned.
/// -> dictionary
#let uraw-get-code(lang: none, ..args) = context uraw-uncontext-get-code(
  resolve-lang(lang, args).first(),
)

/// Set the code configurations, specific to a language if one is mentioned.
///
/// - lang (none, str): The language name. If set to `none`, the default configurations are updated.
/// - args (arguments): Code settings: \ **fill** (none | auto | color | gradient | tiling | function): the background of the number, if set to `auto` it is the same as the code's background, if it is a function it is the result of the function applied to the number \ **indent-size** (auto | int): the number of spaces of an indentation level (where the indentation lines are drawn), `auto` for the tab size of the raw block (2 by default) \ **indentation** (none | length | color | gradient | stroke | tiling | dictionary): the indentation lines in the code \ **inset** (relative | dictionary): only left and right insets \ **line-spacing** (length): the space between the lines of the code
/// -> content
#let uraw-set-code(lang: none, ..args) = {
  let lang = resolve-lang(lang, args).first()
  let args = args.named()

  branch-config(
    lang,
    uraw-config-state.update(conf => {
      conf.code = ut.filter-add-dict(conf.code, args)
      conf
    }),

    lang => uraw-lang-configs-state.update(confs => {
      if not lang in confs { confs.insert(lang, (:)) }
      if not "code" in confs.at(lang) { confs.at(lang).insert("code", (:)) }
      confs.at(lang).code += args
      confs
    }),
  )
}

#let parse-code(lang: none, ..args) = {
  let lang = resolve-lang(lang, args).first()
  let args = args.named()

  let code-ref = uraw-uncontext-get-code(lang)
  if "code" in args {
    ut.filter-add-dict(code-ref, args.code)
  } else {
    code-ref
  }
}

// -----------------------------------------------------------------------------
// Comment
// -----------------------------------------------------------------------------

#let uraw-uncontext-get-comment(lang) = branch-config(
  lang,
  uraw-config-state.get().comment,
  lang => filter-add-lang-to-conf(
    uraw-config-state.get(),
    uraw-lang-configs-state.get(),
    lang,
    "comment",
  ),
)

/// Get the comment configurations, specific to a language if one is mentioned.
///
/// - lang (none, str): The language name. If set to `none`, the default configurations are returned.
/// -> dictionary
#let uraw-get-comment(lang: none, ..args) = context uraw-uncontext-get-comment(
  resolve-lang(lang, args).first(),
)

/// Set the comment configurations, specific to a language if one is mentioned.
///
/// - lang (none, str): The language name. If set to `none`, the default configurations are updated.
/// - args (arguments): Comment settings: \ **in-code** (bool): when false the comment spans over the numbers and the code, when true only over the code and the number cell is left blank \ **indented** (bool): wether the comment starts at the indentation level of the previous code line \ **marker** (none | content | array | function): if set, the comment is displayed as a list item with this marker \ **fill** (none | color | gradient | tiling): the background of the comment, spanning over the full line \ **style** (none | function): a function applied to the comment (marker included)
/// -> content
#let uraw-set-comment(lang: none, ..args) = {
  let lang = resolve-lang(lang, args).first()
  let args = args.named()

  branch-config(
    lang,
    uraw-config-state.update(conf => {
      conf.comment = ut.filter-add-dict(conf.comment, args)
      conf
    }),

    lang => uraw-lang-configs-state.update(confs => {
      if not lang in confs { confs.insert(lang, (:)) }
      if not "comment" in confs.at(lang) {
        confs.at(lang).insert("comment", (:))
      }
      confs.at(lang).comment += args
      confs
    }),
  )
}

#let parse-comment(lang: none, ..args) = {
  let lang = resolve-lang(lang, args).first()
  let args = args.named()

  let comment-ref = uraw-uncontext-get-comment(lang)
  if "comment" in args {
    ut.filter-add-dict(comment-ref, args.comment)
  } else {
    comment-ref
  }
}

// -----------------------------------------------------------------------------
// Jump
// -----------------------------------------------------------------------------

#let uraw-uncontext-get-jump(lang) = branch-config(
  lang,
  uraw-config-state.get().jump,
  lang => filter-add-lang-to-conf(
    uraw-config-state.get(),
    uraw-lang-configs-state.get(),
    lang,
    "jump",
  ),
)

/// Get the jump configurations, specific to a language if one is mentioned.
///
/// - lang (none, str): The language name. If set to `none`, the default configurations are returned.
/// -> dictionary
#let uraw-get-jump(lang: none, ..args) = context uraw-uncontext-get-jump(
  resolve-lang(lang, args).first(),
)

/// Set the jump configurations, specific to a language if one is mentioned.
///
/// - lang (none, str): The language name. If set to `none`, the default configurations are updated.
/// - args (arguments): Jump settings: \ **comment** (none | content | function): the comment shown in place of the skipped lines, if it is a function it is applied to the bounds `(from, to)` of the jump \ **comment-in-code**, **comment-indented**, **comment-marker**, **comment-fill**, **comment-style**: the settings of the comment, the same as the comment settings `in-code`, `indented`, ..., if set to `auto` the comment settings are used
/// -> content
#let uraw-set-jump(lang: none, ..args) = {
  let lang = resolve-lang(lang, args).first()
  let args = args.named()

  branch-config(
    lang,
    uraw-config-state.update(conf => {
      conf.jump = ut.filter-add-dict(conf.jump, args)
      conf
    }),

    lang => uraw-lang-configs-state.update(confs => {
      if not lang in confs { confs.insert(lang, (:)) }
      if not "jump" in confs.at(lang) { confs.at(lang).insert("jump", (:)) }
      confs.at(lang).jump += args
      confs
    }),
  )
}

#let parse-jump(lang: none, ..args) = {
  let lang = resolve-lang(lang, args).first()
  let args = args.named()

  let jump-ref = uraw-uncontext-get-jump(lang)
  if "jump" in args {
    ut.filter-add-dict(jump-ref, args.jump)
  } else {
    jump-ref
  }
}

// -----------------------------------------------------------------------------
// Lang tag
// -----------------------------------------------------------------------------

#let uraw-uncontext-get-lang-tag(lang) = {
  let ucs = uraw-config-state.get()

  branch-config(lang, ucs.lang-tag, lang => filter-add-lang-to-conf(
    ucs,
    uraw-lang-configs-state.get(),
    lang,
    "lang-tag",
  ))
}

/// Get the lang tag configurations, specific to a language if one is mentioned.
///
/// - lang (none, str): The language name. If set to `none`, the default configurations are returned.
/// -> dictionary
#let uraw-get-lang-tag(
  lang: none,
  ..args,
) = context uraw-uncontext-get-lang-tag(
  resolve-lang(lang, args).first(),
)

/// Set the lang tag configurations, specific to a language if one is mentioned.
///
/// - lang (none, str): The language name. If set to `none`, the default configurations are updated.
/// - args (arguments): Lang tag settings: \ **visible** (bool): wether the lang tag is shown or not \ **code-spacing** (none | length): the spacing between the tag and the code (if applicable) \ **fill** (none | color | gradient | tiling | function): the background of the tag \ **stroke** (none | auto | color | stroke): the stroke of the tag, `auto` for the one of the frame, a color for a thin stroke of this color \ **size** (length): the size of the text of the tag, relative to the size of the code \ **icon** (none | content): the icon used in the tag \ **mode** ("icon" | "name" | "full"): wether to display only the icon, only the name, or both \ **name** (str): the name displayed on the tag \ **placement** ("inline" | "code" | "header" | "p1-p2"): "inline" place the tag on the first code line which is the only one affected by it, "code" place the tag on the first code line but reserve some horizontal space for it on all lines, "header" place the tag on the right of the header (as "code" when there is no header), "p1-p2" place the tag on border `p1` (top, left, right, or bottom) and move the tag along it according to `p2` (top, horizon, bottom, left, center, or right)
/// -> content
#let uraw-set-lang-tag(lang: none, ..args) = {
  let lang = resolve-lang(lang, args).first()
  let args = args.named()

  branch-config(
    lang,
    uraw-config-state.update(conf => {
      conf.lang-tag = ut.filter-add-dict(conf.lang-tag, args)
      conf
    }),

    lang => uraw-lang-configs-state.update(confs => {
      if not lang in confs { confs.insert(lang, (:)) }
      if not "lang-tag" in confs.at(lang) {
        confs.at(lang).insert("lang-tag", (:))
      }
      confs.at(lang).lang-tag += args
      confs
    }),
  )
}

#let parse-lang-tag(lang: none, ..args) = {
  let lang = resolve-lang(lang, args).first()
  let args = args.named()

  let lang-tag-ref = uraw-uncontext-get-lang-tag(lang)
  if "lang-tag" in args {
    ut.filter-add-dict(lang-tag-ref, args.lang-tag)
  } else {
    lang-tag-ref
  }
}

// -----------------------------------------------------------------------------
// Highlights
// -----------------------------------------------------------------------------

#let uraw-uncontext-get-highlights(lang) = branch-config(
  lang,
  uraw-config-state.get().highlights,
  lang => add-lang-to-conf(
    uraw-config-state.get(),
    uraw-lang-configs-state.get(),
    lang,
    "highlights",
  ),
)

/// Get the highlights, specific to a language if one is mentioned.
///
/// - lang (none, str): The language name. If set to `none`, the default highlights are returned.
/// -> dictionary
#let uraw-get-highlights(
  lang: none,
  ..args,
) = context uraw-uncontext-get-highlights(
  resolve-lang(lang, args).first(),
)

/// List the names of the current highlights, specific to a language if one is mentioned.
///
/// - lang (none, str): The language name. If set to `none`, the default highlights are listed.
/// -> array
#let uraw-list-highlights(lang: none, ..args) = context {
  uraw-uncontext-get-highlights(resolve-lang(lang, args).first()).keys()
}

/// Add the highlights, specific to a language if one is mentioned.
///
/// - lang (none, str): The language name. If set to `none`, the highlights are added to the default ones.
/// - args (arguments): The added highlights as named arguments, the names given will be used to identify the corresponding highlights.
/// -> content
#let uraw-add-highlights(lang: none, ..args) = {
  let lang = resolve-lang(lang, args).first()
  let args = args.named()
  let new-pre-highlights = ut.map-dict(args, hl.format-pre-highlight)

  branch-config(
    lang,
    uraw-config-state.update(conf => {
      let old-pre-highlights = conf.highlights
      conf.highlights = old-pre-highlights + new-pre-highlights
      hl.check-pre-highlights(conf.highlights)
      return conf
    }),

    lang => uraw-lang-configs-state.update(confs => {
      if not lang in confs { confs.insert(lang, (:)) }
      if not "highlights" in confs.at(lang) {
        confs.at(lang).insert("highlights", (:))
      }

      let old-pre-highlights = confs.at(lang).highlights
      confs.at(lang).highlights = old-pre-highlights + new-pre-highlights
      hl.check-pre-highlights(confs.at(lang).highlights)
      return confs
    }),
  )
}

// Set the highlights, specific to a language if one is mentioned.
///
/// - lang (none, str): The language name. If set to `none`, the default configurations are updated.
/// - args (arguments): The highlights set as named arguments, the names given will be used to identify the corresponding highlights.
/// -> content
#let uraw-set-highlights(lang: none, ..args) = {
  let lang = resolve-lang(lang, args).first()
  let args = args.named()
  let new-pre-highlights = ut.map-dict(args, hl.format-pre-highlight)
  hl.check-pre-highlights(new-pre-highlights)

  return branch-config(
    lang,
    uraw-config-state.update(conf => {
      conf.highlights = new-pre-highlights
      conf
    }),

    lang => uraw-lang-configs-state.update(confs => {
      if not lang in confs { confs.insert(lang, (:)) }
      confs.at(lang).insert("highlights", new-pre-highlights)
      confs
    }),
  )
}

/// Remove the highlights, specific to a language if one is mentioned.
///
/// - lang (none, str): The language name. If set to `none`, the highlights are removed from the default ones.
/// - args (arguments): The names of the removed highlights.
/// -> content
#let uraw-remove-highlights(lang: none, ..args) = {
  let to-remove = args.pos()

  branch-config(
    lang,
    uraw-config-state.update(conf => {
      for h in to-remove { conf.highlights.remove(h) }
      return conf
    }),

    lang => uraw-lang-configs-state.update(confs => {
      if not lang in confs { confs.insert(lang, (:)) }
      if not "highlights" in confs.at(lang) {
        confs.at(lang).insert("highlights", (:))
      }
      for h in to-remove { confs.at(lang).highlights.remove(h) }
      return confs
    }),
  )
}

/// Reset the highlights to their initial value, specific to a language if one is mentioned.
///
/// - lang (none, str): The language name. If set to `none`, the default highlights are restored, otherwise the highlights specific to the language are removed.
/// -> content
#let uraw-reset-highlights(lang: none, ..args) = branch-config(
  resolve-lang(lang, args).first(),
  uraw-config-state.update(conf => {
    conf.highlights = initial-config.highlights
    conf
  }),
  lang => uraw-lang-configs-state.update(confs => {
    if lang in confs and "highlights" in confs.at(lang) {
      let _ = confs.at(lang).remove("highlights")
    }
    confs
  }),
)

// -----------------------------------------------------------------------------
// General
// -----------------------------------------------------------------------------

/// Get the uraw configurations, specific to a language if one is mentioned.
///
/// - lang (none, str): The language name. If set to `none`, the default configurations are returned.
/// -> dictionary
#let uraw-get(lang: none, ..args) = context {
  let lang = resolve-lang(lang, args).first()
  (
    frame: uraw-uncontext-get-frame(lang),
    header: uraw-uncontext-get-header(lang),
    footer: uraw-uncontext-get-footer(lang),
    numbering: uraw-uncontext-get-numbering(lang),
    code: uraw-uncontext-get-code(lang),
    comment: uraw-uncontext-get-comment(lang),
    jump: uraw-uncontext-get-jump(lang),
    lang-tag: uraw-uncontext-get-lang-tag(lang),
    ..general
      .map(key => (key, uraw-uncontext-get-general(lang, key)))
      .to-dict(),
    diff: uraw-config-state.get().diff,
  )
}

// Set the uraw configurations, specific to a language if one is mentioned.
///
/// - lang (none, str): The language name. If set to `none`, the default configurations are updated.
/// - args (arguments): uraw settings, by section: **frame**, **header**, **footer**, **numbering**, **code**, **comment**, **jump**, **lang-tag**, **highlights**, **diff** (the settings specific to diffs, see `uraw-diff-set`) (e.g. `header: (fill: red)`), or flat as `section-key` (e.g. `header-fill: red`), except for `width`, `height`, `breakable` (frame), `start`, `end` (numbering), `line-spacing`, `indentation` (code), the format of the numbers given by `numbering: format`, and the visibility of the lang tag given by `lang-tag: bool`, and the general settings: **coloring-follow-numbering** (bool): when the numbers are visible, wether the fill and color functions (of the code and of the numbering) are applied to the displayed line number (which can jump) or to the position of the line \ **line-reference** (none | auto | function): how a reference to the line `k` of a labelled figure (`@label.k`) is displayed after "Listing n": `none` for no line references, `auto` for "Listing n.k", or a function of `k` giving the text to add (", line k" by default) \ **default-stroke-length** (length): the length of the strokes and separators given without one (as a color), `.05em` by default
/// -> content
#let uraw-set(lang: none, ..args) = {
  let lang = resolve-lang(lang, args).first()
  let args = normalize-settings(args.named(), pass: ("highlights", "diff"))
  if "frame" in args { uraw-set-frame(lang: lang, ..args.frame) }
  if "header" in args { uraw-set-header(lang: lang, ..args.header) }
  if "footer" in args { uraw-set-footer(lang: lang, ..args.footer) }
  if "numbering" in args { uraw-set-numbering(lang: lang, ..args.numbering) }
  if "code" in args { uraw-set-code(lang: lang, ..args.code) }
  if "comment" in args { uraw-set-comment(lang: lang, ..args.comment) }
  if "jump" in args { uraw-set-jump(lang: lang, ..args.jump) }
  if "lang-tag" in args { uraw-set-lang-tag(lang: lang, ..args.lang-tag) }
  if "highlights" in args {
    uraw-set-highlights(lang: lang, ..args.highlights)
  }
  for key in general {
    if key in args { uraw-set-general(lang, key, args.at(key)) }
  }
  if "diff" in args {
    assert(
      lang == none,
      message: "The settings specific to diffs cannot be specific to a language.",
    )
    update-diff(args.diff)
  }
}

/// Reset the uraw configurations to their initial value, specific to a language if one is mentioned.
///
/// - lang (none, str): The language name. If set to `none`, the default configurations are reset (the configurations specific to languages are kept), otherwise the configurations of the language are reset.
/// -> content
#let uraw-reset(lang: none, ..args) = branch-config(
  resolve-lang(lang, args).first(),
  uraw-config-state.update(initial-config),
  lang => uraw-lang-configs-state.update(confs => {
    if lang in initial-lang-configs {
      confs.insert(lang, initial-lang-configs.at(lang))
    } else if lang in confs {
      let _ = confs.remove(lang)
    }
    confs
  }),
)
