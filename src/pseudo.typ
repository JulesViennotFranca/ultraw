#import "config.typ" as cf
#import "formatting.typ" as formatting
#import "measure.typ" as me
#import "rendering.typ" as re
#import "utils.typ" as ut

// -----------------------------------------------------------------------------
// Helpers
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

/// Write lines of pseudo code without numbers (they are not counted).
///
/// - contents (arguments): The contents, each one starting a new line.
/// - indent (bool): Wether the lines are indented as the other lines (in the code), otherwise they span over the numbers and the code (from the left of the frame, without indentation).
/// -> content
#let no-number(..contents, indent: true) = {
  assert(
    contents.named().len() == 0 and contents.pos().len() > 0,
    message: "`no-number` takes the contents of the lines without numbers.",
  )
  assert(
    type(indent) == bool,
    message: "The `indent` of `no-number` must be a bool.",
  )
  metadata((uraw-no-number: contents.pos(), indent: indent))
}

// -----------------------------------------------------------------------------
// Rendering
// -----------------------------------------------------------------------------

#let pseudo-to-uraw(args, lines, jumps, base-style) = {
  // The blocks of uraw (including the one of `layout`) do not take the block settings of the document
  set block(
    above: auto,
    below: auto,
    width: auto,
    height: auto,
    fill: none,
    stroke: none,
    // (an empty dictionary would keep the sides set by the document)
    inset: 0pt,
    outset: 0pt,
    radius: 0pt,
  )

  // The identifier of the block, to find its first and last rows
  let id-counter = counter("uraw-block-id")
  id-counter.step()

  // The states (settings, identifier) are read outside of `layout`, whose content can be laid out without them (as when measuring an auto column of a grid)
  context {
    let id = id-counter.get().first()
    let general = cf.pseudo-category-parser("general", args)
    let with-default-thickness(stroke) = ut.with-default-thickness(
      stroke,
      general.default-stroke-thickness,
    )

    let frame = cf.pseudo-category-parser("frame", args)
    let header = cf.pseudo-category-parser("header", args)
    let footer = cf.pseudo-category-parser("footer", args)
    let number = cf.pseudo-category-parser("numbers", args)
    let code = cf.pseudo-category-parser("code", args)

    set par(leading: code.line-spacing)

    layout(layout-size => {
      let frame = formatting.frame-width(frame, layout-size)

      // The measures only take the settings above into account in a new context
      context {
        // (the settings are modified below)
        let (frame, header, footer, number, code) = (
          frame,
          header,
          footer,
          number,
          code,
        )

        // Basic formatting (pseudo code has no lang tag)
        let lang-tag = (visible: false, placement: none, in-code: false)
        frame = formatting.frame(frame, lang-tag, with-default-thickness)
        code = formatting.code(code, with-default-thickness)
        code.indent-size = code.indent-size.to-absolute()

        // Numbers (the lines without number are not counted)
        let nbr-lines = lines.len()
        let nbr-numbered = lines.filter(l => l.numbered).len()
        number.visible = number.format != none
        let (jumps, jumps-map) = formatting.jumps(
          jumps,
          number,
          skip-lines: none,
        )
        number = formatting.number(
          number,
          nbr-numbered,
          jumps,
          code,
          with-default-thickness,
        )
        let (line-numbers, coloring-numbers) = formatting.pseudo-line-numbers(
          lines,
          number,
          jumps,
          jumps-map,
        )

        // Pseudo code has no markers
        let marker = formatting.marker(
          general + (markers-over-numbers: false),
          number,
          code,
        )
        let (number-markers, markers, marker) = formatting.markers(
          lines.map(_ => none),
          (),
          marker,
        )
        number = formatting.number-cells(
          number,
          general,
          number-markers,
          line-numbers,
        )

        // Coloring
        (number, code) = formatting.coloring(
          number,
          code,
          general,
          frame,
          coloring-numbers,
          nbr-lines,
        )

        // Header & footer
        (header, footer) = formatting.header-footer(
          header,
          footer,
          frame,
          code,
          lang-tag,
          base-style,
          nbr-lines,
          with-default-thickness,
        )
        (frame, header, footer) = formatting.frame-block(frame, header, footer)

        // Lines
        let bodies = lines.map(l => formatting.pseudo-line-body(l, code))

        // Available width

        let (numbers-width, markers-width) = me.numbers-markers-width(
          number,
          marker,
          monotonic: type(number.format) != function,
        )

        // The width of the columns before the code
        let pre-width = numbers-width + markers-width

        let code-width = me.available-code-width(
          layout-size,
          frame,
          code,
          pre-width,
        )

        // Width

        (header, footer) = formatting.align-header-footer(
          header,
          footer,
          pre-width,
        )

        let header-width = if header.content != none {
          measure(block(inset: header.inset, header.content)).width
        } else { 0mm }
        let footer-width = if footer.content != none {
          measure(block(inset: footer.inset, footer.content)).width
        } else { 0mm }

        code-width = me.pseudo-code-width(
          frame,
          code-width,
          bodies,
          lines,
          pre-width,
        )
        code-width = me.hf-code-width(
          header-width,
          pre-width,
          code,
          code-width,
          footer-width,
        )
        if frame.width == auto {
          frame.width = (
            pre-width + code.inset.left + code-width + code.inset.right
          )
        }

        // Height

        let char-height = measure("#").height
        let lines-height = me.pseudo-lines-height(
          bodies,
          lines,
          code,
          code-width,
          pre-width,
          char-height,
        )

        // Rendering

        let line-cell(i, height, radius, stroke, fill, color, extra) = (
          re.pseudo-line-cell(
            lines.at(i),
            bodies.at(i),
            code,
            // (a spanning line is also over the columns before the code)
            code-width + if lines.at(i).spanning { pre-width } else { 0pt },
            height,
            radius,
            stroke,
            fill,
            color,
            extra,
          )
        )

        let frame-content = re.render(
          nbr-lines,
          number,
          numbers-width,
          code,
          (),
          code-width,
          lines-height,
          frame,
          header,
          footer,
          lang-tag,
          none,
          measure("#").width,
          char-height,
          range(nbr-lines).map(_ => ()),
          range(nbr-lines + 1).map(_ => ()),
          line-cell: line-cell,
          spanning: lines.map(l => l.spanning),
          marker: marker,
          markers-width: markers-width,
          markers: markers,
          id: id,
        )

        block(
          fill: frame.block.fill,
          radius: frame.block.radius,
          stroke: frame.block.stroke,
          clip: not frame.sharp-page-break,
          width: frame.width,
          height: frame.height,
          breakable: frame.breakable,
          frame-content,
        )
      }
    })
  }
}

/// Display pseudo code: lines of content, numbered and framed like raw code.
///
/// - args (arguments): The lines (each content starting a new line, indented with `indent`, without number with `no-number`), and the settings (see `uraw-pseudo-set`).
/// - jumps (array, dictionary): The jumps in the number, as `(from, to)` pairs or `(from: .., to: ..)` dictionaries. A single one can be given instead of an array.
/// -> content
#let uraw-pseudo(..args, jumps: ()) = {
  // Settings given by category or flat (e.g. `header-fill`)
  let settings = cf.normalize-settings(args.named(), cf.pseudo-spec)
  let lines = formatting.pseudo-lines(args.pos())

  // Mark the pseudo code, so that the figures containing it can be algorithms
  formatting.pseudo-marker(
    settings.at("general", default: (:)).at("algorithm-figure", default: auto),
  )

  // The style outside of the pseudo code, used by the headers and footers
  context {
    let style = cf.outside-style()
    pseudo-to-uraw(settings, lines, jumps, () => style)
  }
}
