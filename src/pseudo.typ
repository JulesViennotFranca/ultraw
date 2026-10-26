#import "common.typ" as cm
#import "measure.typ" as me
#import "rendering.typ" as re
#import "state.typ" as st
#import "../themes/pseudo.typ": default
#import "utils.typ" as ut

// -----------------------------------------------------------------------------
// Indentation
// -----------------------------------------------------------------------------

/// Indent pseudo code by one level (nest it to indent by more levels).
///
/// - contents (arguments): The indented contents, each one starting a new line.
/// -> content
#let indent(..contents) = {
  assert(
    contents.named().len() == 0 and contents.pos().len() > 0,
    message: "`indent` takes the indented contents.",
  )
  metadata((uraw-indent: contents.pos()))
}

/// Write lines of pseudo code without numbers (they are not counted, but are indented as the other lines).
///
/// - contents (arguments): The contents, each one starting a new line.
/// -> content
#let no-number(..contents) = {
  assert(
    contents.named().len() == 0 and contents.pos().len() > 0,
    message: "`no-number` takes the contents of the lines without numbers.",
  )
  metadata((uraw-no-number: contents.pos()))
}

/// The contents of lines without numbers, `none` if it is not some.
#let unnumbered-contents(it) = if (
  type(it) == content
    and it.func() == metadata
    and type(it.value) == dictionary
    and "uraw-no-number" in it.value
) { it.value.uraw-no-number }

/// The contents of an indented block, `none` if it is not one.
#let indented-contents(it) = if (
  type(it) == content
    and it.func() == metadata
    and type(it.value) == dictionary
    and "uraw-indent" in it.value
) { it.value.uraw-indent }

// -----------------------------------------------------------------------------
// Settings
// -----------------------------------------------------------------------------

/// The settings names of pseudo code.
#let pseudo-spec = st.settings-spec(
  default,
  ("frame", "header", "footer", "numbering", "code"),
  (
    "coloring-follow-numbering",
    "line-reference",
    "algorithm-figure",
    "default-stroke-length",
  ),
  (
    width: ("frame", "width"),
    height: ("frame", "height"),
    breakable: ("frame", "breakable"),
    start: ("numbering", "start"),
    end: ("numbering", "end"),
    line-spacing: ("code", "line-spacing"),
    indentation: ("code", "indentation"),
    indent-size: ("code", "indent-size"),
    style: ("code", "style"),
  ),
)

/// The initial settings of pseudo code.
#let initial-pseudo-config = {
  let config = default
  config.header += (content: none)
  config.footer += (content: none)
  config
}

#let uraw-pseudo-state = state("uraw-pseudo-config", initial-pseudo-config)

/// Update a section of the pseudo code settings.
#let update-section(name, args) = uraw-pseudo-state.update(conf => {
  conf.insert(name, ut.filter-add-dict(conf.at(name), args))
  conf
})

/// The named arguments, with the first positional argument as `content`.
#let with-content(args) = {
  let pos = args.pos()
  args.named() + if pos.len() > 0 { (content: pos.at(0)) } else { (:) }
}

/// Get the frame settings of pseudo code.
/// -> dictionary
#let uraw-pseudo-get-frame() = context uraw-pseudo-state.get().frame

/// Get the header settings of pseudo code.
/// -> dictionary
#let uraw-pseudo-get-header() = context uraw-pseudo-state.get().header

/// Get the footer settings of pseudo code.
/// -> dictionary
#let uraw-pseudo-get-footer() = context uraw-pseudo-state.get().footer

/// Get the numbering settings of pseudo code.
/// -> dictionary
#let uraw-pseudo-get-numbering() = context uraw-pseudo-state.get().numbering

/// Get the code settings of pseudo code.
/// -> dictionary
#let uraw-pseudo-get-code() = context uraw-pseudo-state.get().code

/// Get the general settings of pseudo code (`coloring-follow-numbering`, `line-reference`, `algorithm-figure`, `default-stroke-length`).
/// -> dictionary
#let uraw-pseudo-get-general() = context {
  let conf = uraw-pseudo-state.get()
  pseudo-spec.general.map(key => (key, conf.at(key))).to-dict()
}

/// Get the settings of pseudo code.
/// -> dictionary
#let uraw-pseudo-get() = context uraw-pseudo-state.get()

/// Set the frame settings of pseudo code, the same as for raw code.
/// -> content
#let uraw-pseudo-set-frame(..args) = update-section("frame", args.named())

/// Set the header settings of pseudo code, the same as for raw code.
/// -> content
#let uraw-pseudo-set-header(..args) = update-section(
  "header",
  with-content(
    args,
  ),
)

/// Set the footer settings of pseudo code, the same as for raw code.
/// -> content
#let uraw-pseudo-set-footer(..args) = update-section(
  "footer",
  with-content(
    args,
  ),
)

/// Set the numbering settings of pseudo code, the same as for raw code.
/// -> content
#let uraw-pseudo-set-numbering(..args) = update-section(
  "numbering",
  args.named(),
)

/// Set the code settings of pseudo code.
///
/// - args (arguments): Code settings: \ **fill**, **inset**, **line-spacing**, **indentation**: the same as for raw code \ **indent-size** (length): the width of an indentation level \ **style** (none | function): the style of the lines, `none` for the style of the document, or a function applied to the content of each line
/// -> content
#let uraw-pseudo-set-code(..args) = update-section("code", args.named())

/// Set the settings of pseudo code, by section (**frame**, **header**, **footer**, **numbering**, **code**) or flat (`section-key`, with the shortcuts `width`, `height`, `breakable`, `start`, `end`, `line-spacing`, `indentation`, `indent-size`, `style`, and `numbering: format` for the format of the numbers), and the general settings **coloring-follow-numbering**, **line-reference**, **default-stroke-length** (see `uraw-set`) and **algorithm-figure** (bool): wether a figure containing pseudo code is an "Algorithm" (with its own numbering) instead of a "Figure".
/// -> content
#let uraw-pseudo-set(..args) = {
  let settings = st.normalize-settings(args.named(), spec: pseudo-spec)
  uraw-pseudo-state.update(conf => {
    for (key, value) in settings {
      if key in pseudo-spec.general {
        conf.insert(key, value)
      } else {
        conf.insert(key, ut.filter-add-dict(conf.at(key), value))
      }
    }
    conf
  })
}

/// Reset the settings of pseudo code to their initial value.
/// -> content
#let uraw-pseudo-reset() = uraw-pseudo-state.update(initial-pseudo-config)

// -----------------------------------------------------------------------------
// Lines
// -----------------------------------------------------------------------------

/// Wether an element is only white space.
#let is-space(it) = (
  it.func() == [ ].func() or (it.func() == text and it.text.trim() == "")
)

/// Split the arguments of pseudo code in lines, with their indentation level.
///
/// - args (array): The positional arguments: content, split on line and paragraph breaks (a paragraph break adding a blank line, as an empty argument), and on indented blocks (each content of an indented block starting a new line).
/// -> array: the lines, as dictionaries with a `body` (content, none for a blank line) and a `level` (int)
#let parse-lines(args) = {
  let lines = ()
  let current = ()
  for it in args {
    let contents = indented-contents(it)
    let unnumbered = unnumbered-contents(it)
    if contents != none {
      // The lines of an indented block (which is preceded by a line break)
      for l in parse-lines(contents) {
        lines.push(l + (level: l.level + 1))
      }
    } else if (
      type(it) == content
        and it.func() == metadata
        and type(it.value) == dictionary
        and "uraw-blank" in it.value
    ) {
      lines.push((body: none, level: 0, numbered: true))
    } else if unnumbered != none {
      // The lines without numbers (which are preceded by a line break)
      for l in parse-lines(unnumbered) {
        lines.push(l + (numbered: false))
      }
    } else {
      lines.push((body: it, level: 0, numbered: true))
    }
  }

  // Blank lines have the indentation of the next line
  let i = lines.len() - 2
  while 0 <= i {
    if lines.at(i).body == none { lines.at(i).level = lines.at(i + 1).level }
    i -= 1
  }

  lines
}

// -----------------------------------------------------------------------------
// Rendering
// -----------------------------------------------------------------------------

#let pseudo-to-uraw(settings, lines, jumps) = layout(layout-size => {
  // Parsing

  let conf = uraw-pseudo-state.get()
  let section(name) = ut.filter-add-dict(
    conf.at(name),
    settings.at(name, default: (:)),
  )
  let general(key) = settings.at(key, default: conf.at(key))

  let frame = section("frame")
  let header = section("header")
  let footer = section("footer")
  let numbering = section("numbering")
  numbering.insert("visible", numbering.format != none)
  let code = section("code")

  set par(leading: code.line-spacing)

  set block(
    above: auto,
    below: auto,
    width: auto,
    height: auto,
    fill: none,
    stroke: none,
    inset: (:),
    outset: (:),
    radius: (:),
  )

  let nbr-lines = lines.len()

  // Jumps (the lines without number are not counted)

  let (numbering, jumps, numbers, blocks-update) = cm.format-jumps(
    jumps,
    numbering,
    lines.filter(l => l.numbered).len(),
    "pseudo",
  )

  // The number of each line, `none` for the lines without number
  let line-numbers = ()
  let k = 0
  for l in lines {
    line-numbers.push(if l.numbered {
      k += 1
      numbers.at(k - 1)
    })
  }

  // Insets & radius & stroke

  (frame, header, footer, numbering, code) = cm.format-insets(
    frame,
    header,
    footer,
    numbering,
    code,
    stroke-length: general("default-stroke-length"),
  )

  // Color formatting

  (numbering, code) = cm.format-colors(
    numbering,
    code,
    frame,
    line-numbers,
    nbr-lines,
    general("coloring-follow-numbering"),
    general("line-reference"),
  )

  // Header & footer formatting

  (header, footer) = cm.format-header-footer(
    header,
    footer,
    frame,
    code,
    nbr-lines,
  )

  // Lines

  let indent-size = code.indent-size.to-absolute()
  let char-height = measure("#").height

  let line-body(l) = pad(left: l.level * indent-size, if l.body == none {
    []
  } else if code.style != none {
    (code.style)(l.body)
  } else {
    l.body
  })

  // Width

  let numbers-width = me.numbers-width(
    line-numbers.filter(n => n != none),
    format: n => cm.format-number(numbering.format, n),
    // Only the formats given by functions can be wider for other numbers
    monotonic: type(numbering.format) != function,
  )
  numbers-width = if numbering.visible {
    numbering.inset.left + numbers-width + numbering.inset.right
  } else { 0mm }

  let code-width = me.available-code-width(
    layout-size,
    frame,
    code,
    numbers-width,
  )

  if header.remove("code-aligned") { header.inset.left = numbers-width }
  if footer.remove("code-aligned") { footer.inset.left = numbers-width }

  let header-width = if header.content != none {
    measure(block(inset: header.inset, header.content)).width
  } else { 0mm }
  let footer-width = if footer.content != none {
    measure(block(inset: footer.inset, footer.content)).width
  } else { 0mm }

  if frame.width == auto {
    code-width = calc.min(
      code-width,
      calc.max(0mm, ..lines.map(l => measure(line-body(l)).width)),
    )
  }
  code-width = me.hf-code-width(
    header-width,
    numbers-width,
    code,
    code-width,
    footer-width,
  )

  if frame.width == auto {
    frame.width = (
      numbers-width + code.inset.left + code-width + code.inset.right
    )
  }

  // Height

  let lines-height = lines.map(l => (
    calc.max(
      char-height,
      measure(block(width: code-width, line-body(l))).height,
    )
      + code.line-spacing
  ))

  // Rendering

  let line-cell(i, height, radius, stroke, fill, extra) = {
    let l = lines.at(i)
    let inset = ut.grow-inset(code.inset, extra)
    block(
      breakable: false,
      width: code.inset.left + code-width + code.inset.right,
      height: height,
      inset: inset,
      radius: radius,
      stroke: stroke,
      fill: fill,
      align(left, {
        // Indentation
        if code.indentation != none {
          for k in range(l.level) {
            let x = k * indent-size
            place(left + top, line(
              start: (x, -inset.top),
              end: (x, height - inset.top),
              stroke: code.indentation,
            ))
          }
        }

        line-body(l)
      }),
    )
  }

  let frame-content = re.render(
    nbr-lines,
    numbering,
    numbers-width,
    code,
    (),
    code-width,
    lines-height,
    frame,
    header,
    footer,
    (visible: false, in-code: false),
    none,
    measure("#").width,
    char-height,
    range(nbr-lines).map(_ => ()),
    range(nbr-lines + 1).map(_ => ()),
    line-cell: line-cell,
  )

  // Register the code block, to continue its numbering
  blocks-update

  block(
    width: frame.width,
    height: frame.height,
    breakable: frame.breakable,
    frame-content,
  )
})

/// Display pseudo code: lines of content, numbered and framed like raw code.
///
/// - args (arguments): The lines: content (split on line breaks and paragraph breaks, a paragraph break adding a blank line, each argument starting a new line), indented with `indent`, and the settings (see `uraw-pseudo-set`).
/// - jumps (array): The jumps in the numbering, as `(from, to)` pairs or `(from: .., to: ..)` dictionaries.
/// -> content
#let uraw-pseudo(..args, jumps: ()) = {
  let settings = st.normalize-settings(args.named(), spec: pseudo-spec)
  let lines = parse-lines(args.pos())

  // Mark the pseudo code, so that the figures containing it can be algorithms
  cm.pseudo-marker(settings.at("algorithm-figure", default: auto))
  cm.block-start(kind: "pseudo")
  pseudo-to-uraw(settings, lines, jumps)
}
