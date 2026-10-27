#import "highlight.typ" as hl
#import "content.typ" as ct
#import "utils.typ" as ut

/// Create the cell of a column of the gutter (beside the code): a number, a marker, a diff marker.
///
/// - body (content): The content of the cell.
/// - width (length): The width of the column.
/// - height (length): The height of the line.
/// - inset (inset):
/// - radius (radius):
/// - stroke (stroke):
/// - fill (color, none):
/// - sep (stroke, none): The separating stroke on the right of the column, none if there is none.
/// - alignment (alignment):
/// -> block
#let side-cell(
  body,
  width,
  height,
  inset,
  radius,
  stroke,
  fill,
  sep,
  alignment,
) = block(
  breakable: false,
  clip: true,
  width: width,
  height: height,
  inset: inset,
  radius: radius,
  stroke: stroke,
  fill: fill,
  {
    align(alignment, body)

    if sep != none or fill != none {
      let s = std.stroke(if sep != none { sep } else { fill })
      let thickness = if s.thickness == auto { 1pt } else { s.thickness }
      // The line is inside the cell, which clips its content
      place(right + top, dx: inset.right - thickness / 2, dy: -inset.top, line(
        start: (0mm, 0mm),
        end: (0mm, height),
        stroke: s,
      ))
    }
  },
)

/// Create the block of a code line whose highlights are computed.
///
/// - l (dictionary): The line, with its styled sub-lines.
/// - highlight-blocks (array): The highlight blocks, as `(sub-line, start, block)`.
/// - width (length): The width of the code.
/// - height (length): The height of the line.
/// - inset (inset):
/// - radius (radius):
/// - stroke (stroke):
/// - fill (color, none):
/// - lang-tag (block, none):
/// - char-width (length):
/// - char-height (length):
/// - indentation (stroke, none): The indentation strokes, none if there is no indentation.
/// -> block
#let code-block(
  l,
  highlight-blocks,
  width,
  height,
  inset,
  radius,
  stroke,
  fill,
  lang-tag,
  char-width,
  char-height,
  indentation,
  extra: (top: 0pt, bottom: 0pt),
) = block(
  breakable: false,
  width: inset.left + width + inset.right,
  height: height,
  inset: ut.grow-inset(inset, extra),
  radius: radius,
  stroke: stroke,
  fill: fill,
  align(left, {
    // Place highlights blocks
    for (k, s, hl-block) in highlight-blocks {
      place(
        left + top,
        dx: s * char-width,
        dy: -.24em + k * (inset.top + char-height + inset.bottom),
        hl-block,
      )
    }

    l.slines.map(sl => sl.body).join("\n", default: [])

    // Lang tag
    if lang-tag != none {
      place(
        right + top,
        dy: (-inset.top + char-height + inset.bottom - measure(lang-tag).height)
          / 2,
        lang-tag,
      )
    }

    // Indentation
    if indentation != none {
      for p in l.pos-indent.slice(0, -1) {
        let x = p * char-width
        place(left + top, line(
          start: (x, -inset.top - extra.top),
          end: (
            x,
            char-height
              + inset.bottom
              + if l.slines.len() == 1 { extra.bottom } else { 0pt },
          ),
          stroke: indentation,
        ))
      }
    }
  }),
)

/// Create a code cell.
///
/// - i (int): The index of the line.
/// - l (dictionary): The line.
/// - width (length): The width of the code.
/// - height (length): The height of the line.
/// - inset (inset):
/// - radius (radius):
/// - stroke (stroke):
/// - fill (color, none):
/// - lang-tag (block, none):
/// - char-width (length):
/// - char-height (length):
/// - indentation (stroke, none): The indentation strokes, none if there is no indentation.
/// - highlights (array): The list of highlights on the code.
/// -> block
#let code-cell(
  i,
  l,
  width,
  height,
  inset,
  radius,
  stroke,
  fill,
  lang-tag,
  char-width,
  char-height,
  indentation,
  highlights,
  extra: (top: 0pt, bottom: 0pt),
) = {
  let (new-slines, highlight-blocks) = hl.compute-highlights(
    i,
    l,
    width,
    inset,
    char-width,
    char-height,
    highlights,
  )
  l.slines = new-slines

  code-block(
    l,
    highlight-blocks,
    width,
    height,
    inset,
    radius,
    stroke,
    fill,
    lang-tag,
    char-width,
    char-height,
    indentation,
    extra: extra,
  )
}

/// Create the cell of a line of pseudo code.
///
/// - l (dictionary): The line (see `pseudo-lines`).
/// - body (content): Its content (see `pseudo-line-body`).
/// - code (dictionary): The code parameters, with an absolute `indent-size`.
/// - width (length): The width of the code.
/// - height (length): The height of the line.
/// - radius (radius):
/// - stroke (stroke):
/// - fill (color, none):
/// - extra (dictionary): The space added above and below (on the first and last lines).
/// -> block
#let pseudo-line-cell(
  l,
  body,
  code,
  width,
  height,
  radius,
  stroke,
  fill,
  extra,
) = {
  let inset = ut.grow-inset(code.inset, extra)
  block(
    breakable: false,
    width: code.inset.left + width + code.inset.right,
    height: height,
    inset: inset,
    radius: radius,
    stroke: stroke,
    fill: fill,
    align(left, {
      // Indentation
      if code.indentation != none {
        for k in range(l.level) {
          let x = k * code.indent-size
          place(left + top, line(
            start: (x, -inset.top),
            end: (x, height - inset.top),
            stroke: code.indentation,
          ))
        }
      }

      body
    }),
  )
}

/// Create a comment cell.
///
/// - c (dictionary): The comment.
/// - height (length): The height of the row.
/// - radius (radius):
/// - stroke (stroke):
/// -> block
#let comment-cell(
  c,
  height,
  radius,
  stroke,
  indentation,
  char-width,
) = {
  block(
    breakable: false,
    width: c.width,
    height: height,
    inset: c.inset,
    radius: radius,
    stroke: stroke,
    fill: c.fill,
    align(horizon, c.body),
  )

  // Add indentation if needed
  if (
    indentation != none and c.to-indent and c.pos-indent.len() > 0
  ) {
    let x-offset = c.inset.left - c.pos-indent.last() * char-width
    for p in c.pos-indent.slice(0, -1) {
      let x = x-offset + p * char-width
      place(left + top, line(
        start: (x, 0mm),
        end: (x, c.height),
        stroke: indentation,
      ))
    }
  }
}

/// Create a header cell.
///
/// - header (dictionary): The header parameters.
/// - frame (dictionary): The frame parameters.
/// - nbr-columns (int): The number of columns of the grid.
/// The anchors of the first and last rows of a block, used to know on which pages they are.
///
/// - id (int): The identifier of the block.
/// - kind (str): `"start"` or `"end"`.
/// -> metadata
#let row-anchor(id, kind) = metadata((uraw-anchor: (id: id, kind: kind)))

/// Wether the current page is the one of an anchor of a block (`true` when there is no such anchor).
///
/// - id (int): The identifier of the block.
/// - kind (str): `"start"` or `"end"`.
/// -> bool
#let on-anchor-page(id, kind) = {
  let anchors = query(metadata.where(value: (uraw-anchor: (id: id, kind: kind))))
  anchors.len() == 0 or anchors.first().location().page() == here().page()
}

/// Create a header cell. Once repeated on another page, it has no top radius and no lang tag.
///
/// - header (dictionary): The header parameters.
/// - frame (dictionary): The frame parameters.
/// - nbr-columns (int): The number of columns of the grid.
/// - id (int): The identifier of the block.
/// -> grid.header, none
#let header-cell(header, frame, nbr-columns, id) = if header.content != none {
  grid.header(
    repeat: header.repeat,
    grid.cell(
      colspan: nbr-columns,
      context {
        let first = id == none or on-anchor-page(id, "start")
        block(
          width: frame.width,
          height: header.height,
          radius: if first { header.radius } else { (:) },
          inset: header.inset,
          stroke: header.stroke,
          fill: header.fill,
          breakable: false,
          {
            align(header.alignment, header.content)
            // The lang tag placed in the header
            if first and header.at("tag", default: none) != none {
              place(right + horizon, header.tag)
            }
          },
        )
      },
    ),
  )
}

/// Create a footer cell.
///
/// - footer (dictionary): The footer parameters.
/// - frame (dictionary): The frame parameters.
/// - nbr-columns (int): The number of columns of the grid.
/// - id (int): The identifier of the block.
/// -> grid.footer, none
#let footer-cell(footer, frame, nbr-columns, id) = if footer.content != none {
  grid.footer(
    repeat: footer.repeat,
    grid.cell(
      colspan: nbr-columns,
      // Repeated on another page than the last one, it has no bottom radius
      context block(
        width: frame.width,
        height: footer.height,
        radius: if id == none or on-anchor-page(id, "end") {
          footer.radius
        } else { (:) },
        inset: footer.inset,
        stroke: footer.stroke,
        fill: footer.fill,
        breakable: false,
        align(footer.alignment, footer.content),
      ),
    ),
  )
}

/// Render a whole block of raw code.
///
/// - nl (int): The number of lines.
/// - number (dictionary): The number parameters.
/// - numbers-width (length):
/// - code (dictionary): The code parameters.
/// - code-lines (array):
/// - code-width (length):
/// - lines-height (length):
/// - frame (dictionary): The frame parameters.
/// - header (dictionary): The header parameters.
/// - footer (dictionary): The footer parameters.
/// - lang-tag (dictionary): The lang tag parameters.
/// - lang-tag-block (block):
/// - char-width (length):
/// - char-height (length):
/// - highlights (array): The list of highlights per line.
/// - comments (array): The list of comments placed before the first line, then after each line.
/// - line-cell (none, function): The function creating the cell of a line from its index, height, radius, stroke, fill and extra space (top and bottom), instead of a code cell.
/// - marker (dictionary): The marker column parameters (formatted, see `format-marker`), only its visibility is needed when it is not visible.
/// - markers-width (length): The width of the marker column.
/// - markers (array): For each line, its marker (`none` if it has none).
/// - id (none, int): The identifier of the block, to find the pages of its first and last rows (for the repeated header and footer).
/// -> grid
#let render(
  nl,
  number,
  numbers-width,
  code,
  code-lines,
  code-width,
  lines-height,
  frame,
  header,
  footer,
  lang-tag,
  lang-tag-block,
  char-width,
  char-height,
  highlights,
  comments,
  line-cell: none,
  marker: (visible: false),
  markers-width: 0pt,
  markers: (),
  id: none,
) = {
  // Compute the number of columns and the associated widths: the numbers, the markers, the code

  let nbr-columns = 1 + int(number.visible) + int(marker.visible)
  let column-widths = ()
  if number.visible { column-widths.push(numbers-width) }
  if marker.visible { column-widths.push(markers-width) }
  column-widths.push(code.inset.left + code-width + code.inset.right)
  // Wether there are columns before the code (the first one takes the left side of the frame)
  let has-side = number.visible or marker.visible

  // Order the code lines and the comments

  let rows = comments.at(0).map(c => (kind: "comment", comment: c))
  for i in range(nl) {
    rows.push((kind: "code", i: i))
    rows += comments.at(i + 1).map(c => (kind: "comment", comment: c))
  }
  let nr = rows.len()

  let row-height(row) = if row.kind == "code" {
    lines-height.at(row.i)
  } else {
    row.comment.height
  }

  let is-filled(row) = if row.kind == "code" {
    (
      (has-side and (number.fill)(row.i) != none)
        or (code.fill)(row.i) != none
    )
  } else {
    row.comment.fill != none
  }

  // Compute effective line heights and row gutters

  let height-offset = .5pt

  let row-gutters = ()
  let row-heights = ()
  for r in range(nr - 1) {
    if is-filled(rows.at(r)) and is-filled(rows.at(r + 1)) {
      row-heights.push(row-height(rows.at(r)) + height-offset)
      row-gutters.push(-height-offset)
    } else {
      row-heights.push(row-height(rows.at(r)))
      row-gutters.push(0mm)
    }
  }
  row-heights.push(row-height(rows.at(nr - 1)))

  // The space before the first row and after the last one
  let edge(r) = (
    top: if r == 0 { code.edge.top } else { 0pt },
    bottom: if r == nr - 1 { code.edge.bottom } else { 0pt },
  )
  row-heights.at(0) += code.edge.top
  row-heights.at(nr - 1) += code.edge.bottom

  // Compute cells

  let is-first(r) = r == 0 and header.content == none
  let is-last(r) = r == nr - 1 and footer.content == none

  // The radius and stroke of a column beside the code, `leftmost` when it is the first column
  let side-radius(r, leftmost) = if not leftmost { (:) } else if is-first(r) {
    (top-left: frame.radius.top-left)
  } else if is-last(r) {
    (bottom-left: frame.radius.bottom-left)
  } else { (:) }

  let side-stroke(r, leftmost) = (
    top: if is-first(r) { frame.stroke.top },
    left: if leftmost { frame.stroke.left },
    bottom: if is-last(r) { frame.stroke.bottom },
  )

  let code-radius(r) = if is-first(r) {
    (
      (top-right: frame.radius.top-right)
        + if not has-side { (top-left: frame.radius.top-left) }
    )
  } else if is-last(r) {
    (
      (bottom-right: frame.radius.bottom-right)
        + if not has-side { (bottom-left: frame.radius.bottom-left) }
    )
  } else {
    (:)
  }

  let code-stroke(r) = (
    top: if is-first(r) { frame.stroke.top },
    left: if not has-side { frame.stroke.left },
    right: frame.stroke.right,
    bottom: if is-last(r) { frame.stroke.bottom },
  )

  let full-radius(r) = (
    (
      if is-first(r) {
        (top-left: frame.radius.top-left, top-right: frame.radius.top-right)
      } else { (:) }
    )
      + if is-last(r) {
        (
          bottom-left: frame.radius.bottom-left,
          bottom-right: frame.radius.bottom-right,
        )
      } else { (:) }
  )

  let full-stroke(r) = (
    top: if is-first(r) { frame.stroke.top },
    left: frame.stroke.left,
    right: frame.stroke.right,
    bottom: if is-last(r) { frame.stroke.bottom },
  )

  // The separator between the gutter and the code, drawn on the left edge of the code cell (above its content)
  let with-sep(cell, height) = if has-side and number.sep != none {
    cell
    place(left + top, line(start: (0pt, 0pt), end: (0pt, height), stroke: number.sep))
  } else { cell }

  // The cells of the gutter of a row: the number column then the marker column (when visible)
  let gutter-cells(r, height, extra, number-body, marker-body, fill) = {
    let cells = ()
    if number.visible {
      cells.push(side-cell(
        if number-body != none { number-body } else { [] },
        numbers-width,
        height,
        ut.grow-inset(number.inset, extra),
        side-radius(r, true),
        side-stroke(r, true),
        fill,
        none,
        number.alignment,
      ))
    }
    if marker.visible {
      cells.push(side-cell(
        if marker-body != none { marker-body } else { [] },
        markers-width,
        height,
        ut.grow-inset(marker.inset, extra),
        side-radius(r, not number.visible),
        side-stroke(r, not number.visible),
        fill,
        none,
        number.alignment.y + right,
      ))
    }
    cells
  }

  let row-cells = rows
    .enumerate()
    .map(((r, row)) => {
      let height = row-heights.at(r)
      let extra = edge(r)

      if row.kind == "code" {
        let i = row.i
        let code-cell = if line-cell != none {
          line-cell(
            i,
            height,
            code-radius(r),
            code-stroke(r),
            (code.fill)(i),
            extra,
          )
        } else {
          code-cell(
            i,
            code-lines.at(i),
            code-width,
            height,
            code.inset,
            code-radius(r),
            code-stroke(r),
            (code.fill)(i),
            if i == 0 and lang-tag.visible and lang-tag.in-code {
              lang-tag-block
            },
            char-width,
            char-height,
            code.indentation,
            highlights.at(i),
            extra: extra,
          )
        }

        (
          gutter-cells(
            r,
            height,
            extra,
            (number.color)(i, number.cells.at(i)),
            markers.at(i, default: none),
            (number.fill)(i),
          )
            + (with-sep(code-cell, height),)
        )
      } else {
        let c = row.comment
        c.inset = ut.grow-inset(c.inset, extra)

        if c.marker == none {
          // The comment spans over the gutter
          (
            grid.cell(
              colspan: nbr-columns,
              comment-cell(
                c,
                height,
                full-radius(r),
                full-stroke(r),
                code.indentation,
                char-width,
              ),
            ),
          )
        } else {
          let fill = if c.marker-fill == auto {
            c.fill
          } else if c.marker-fill == none {
            // The number fill of the commented line: the line before for a comment after it, the line after otherwise
            let k = if c.copy-before { c.gap - 1 } else { c.gap }
            (number.fill)(calc.clamp(k, 0, nl - 1))
          } else { c.marker-fill }
          let in-number = c.placement == "number"
          (
            gutter-cells(
              r,
              height,
              extra,
              if in-number { c.marker },
              if not in-number { c.marker },
              fill,
            )
              + (
                with-sep(
                  comment-cell(
                    c,
                    height,
                    code-radius(r),
                    code-stroke(r),
                    code.indentation,
                    char-width,
                  ),
                  height,
                ),
              )
          )
        }
      }
    })

  // Anchors in the first and last rows, to know the pages they are on
  if id != none {
    let anchored(cell, kind) = {
      let anchor = row-anchor(id, kind)
      if type(cell) == content and cell.func() == grid.cell {
        let fields = cell.fields()
        let body = fields.remove("body")
        grid.cell(..fields, [#body#anchor])
      } else { [#cell#anchor] }
    }
    row-cells.first().first() = anchored(row-cells.first().first(), "start")
    row-cells.last().last() = anchored(row-cells.last().last(), "end")
  }
  row-cells = row-cells.flatten()

  let header-cell = header-cell(header, frame, nbr-columns, id)

  let cells = if header-cell != none {
    let sep-thickness = if header.stroke.bottom == none {
      0mm
    } else if type(header.stroke.bottom) == stroke {
      header.stroke.bottom.thickness
    } else {
      1pt
    }

    row-heights.insert(0, header.height)
    row-gutters.insert(0, sep-thickness / 2)

    (header-cell,)
  } else { () }

  cells += row-cells

  let footer-cell = footer-cell(footer, frame, nbr-columns, id)

  if footer-cell != none {
    row-heights.push(footer.height)
    row-gutters.push(0mm)

    cells.push(footer-cell)
  }

  // Final grid

  grid(
    rows: row-heights,
    columns: column-widths,
    row-gutter: row-gutters,
    ..cells,
  )
}

