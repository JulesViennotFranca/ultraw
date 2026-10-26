#import "highlight.typ" as hl
#import "content.typ" as ct
#import "utils.typ" as ut

/// Create a number cell.
///
/// - n (str): The number.
/// - width (length): The width of the numbering.
/// - height (length): The height of the line.
/// - inset (inset):
/// - radius (radius):
/// - stroke (stroke):
/// - fill (color, none):
/// - sep (stroke, none): The separating stroke between numbers and code, none if there is none.
/// - alignment (alignment):
/// -> block
#let number-cell(
  n,
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
    align(alignment, n)

    if sep != none or fill != none {
      place(right + top, dx: inset.right, dy: -inset.top, line(
        start: (0mm, 0mm),
        end: (0mm, height),
        stroke: if sep != none { sep } else { fill },
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
    indentation != none and c.in-code and c.indented and c.pos-indent.len() > 0
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
/// - numbering (dictionary): The numbering parameters.
/// -> grid.header, none
#let header-cell(header, frame, numbering) = if header.content != none {
  grid.header(
    repeat: header.repeat,
    grid.cell(
      colspan: 1 + int(numbering.visible),
      block(
        width: frame.width,
        height: header.height,
        radius: header.radius,
        inset: header.inset,
        stroke: header.stroke,
        fill: header.fill,
        breakable: false,
        {
          align(header.alignment, header.content)
          // The lang tag placed in the header
          if header.at("tag", default: none) != none {
            place(right + horizon, header.tag)
          }
        },
      ),
    ),
  )
}

/// Create a footer cell.
///
/// - footer (dictionary): The footer parameters.
/// - frame (dictionary): The frame parameters.
/// - numbering (dictionary): The numbering parameters.
/// -> grid.footer, none
#let footer-cell(footer, frame, numbering) = if footer.content != none {
  grid.footer(
    repeat: footer.repeat,
    grid.cell(
      colspan: 1 + int(numbering.visible),
      block(
        width: frame.width,
        height: footer.height,
        radius: footer.radius,
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
/// - numbering (dictionary): The numbering parameters.
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
/// - lines-range (none, array): The range `(start, end)` of the indexes of the lines shown, all the lines if `none`.
/// - line-cell (none, function): The function creating the cell of a line from its index, height, radius, stroke, fill and extra space (top and bottom), instead of a code cell.
/// -> grid
#let render(
  nl,
  numbering,
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
  lines-range: none,
) = {
  // Compute the number of columns and the associated widths

  let nbr-columns = 1 + int(numbering.visible)
  let column-widths = if numbering.visible { (numbers-width,) } else { () }
  column-widths.push(code.inset.left + code-width + code.inset.right)

  // Order the code lines and the comments

  // Only the lines of the range are shown (for a block of a chain of continued blocks), the comments before a line of the range being shown with the previous line
  let (first-line, end-line) = if lines-range == none { (0, nl) } else {
    lines-range
  }
  let rows = if first-line == 0 {
    comments.at(0).map(c => (kind: "comment", comment: c))
  } else { () }
  for i in range(first-line, end-line) {
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
      (numbering.visible and (numbering.fill)(row.i) != none)
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

  let numbers-radius(r) = if is-first(r) {
    (top-left: frame.radius.top-left)
  } else if is-last(r) {
    (bottom-left: frame.radius.bottom-left)
  } else { (:) }

  let numbers-stroke(r) = (
    top: if is-first(r) { frame.stroke.top },
    left: frame.stroke.left,
    bottom: if is-last(r) { frame.stroke.bottom },
  )

  let code-radius(r) = if is-first(r) {
    (
      (top-right: frame.radius.top-right)
        + if not numbering.visible { (top-left: frame.radius.top-left) }
    )
  } else if is-last(r) {
    (
      (bottom-right: frame.radius.bottom-right)
        + if not numbering.visible { (bottom-left: frame.radius.bottom-left) }
    )
  } else {
    (:)
  }

  let code-stroke(r) = (
    top: if is-first(r) { frame.stroke.top },
    left: if not numbering.visible { frame.stroke.left },
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

        if numbering.visible {
          (
            number-cell(
              (numbering.cell)(i),
              numbers-width,
              height,
              ut.grow-inset(numbering.inset, extra),
              numbers-radius(r),
              numbers-stroke(r),
              (numbering.fill)(i),
              numbering.sep,
              numbering.alignment,
            ),
            code-cell,
          )
        } else {
          (code-cell,)
        }
      } else {
        let c = row.comment
        c.inset = ut.grow-inset(c.inset, extra)

        if c.spans {
          (
            grid.cell(
              colspan: nbr-columns,
              comment-cell(
                c,
                height,
                full-radius(r),
                full-stroke(r),
                none,
                char-width,
              ),
            ),
          )
        } else if numbering.visible {
          (
            number-cell(
              if c.in-code {
                (numbering.coloring)(
                  if c.copy-before { c.gap - 1 } else { c.gap },
                  c.marker,
                )
              } else { c.marker },
              numbers-width,
              height,
              ut.grow-inset(numbering.inset, extra),
              numbers-radius(r),
              numbers-stroke(r),
              if c.in-code {
                (numbering.fill)(if c.copy-before { c.gap - 1 } else { c.gap })
              } else { c.fill },
              if c.in-code { numbering.sep } else { none },
              numbering.alignment,
            ),
            comment-cell(
              c,
              height,
              code-radius(r),
              code-stroke(r),
              code.indentation,
              char-width,
            ),
          )
        } else {
          (
            comment-cell(
              c,
              height,
              code-radius(r),
              code-stroke(r),
              code.indentation,
              char-width,
            ),
          )
        }
      }
    })
    .flatten()

  let header-cell = header-cell(header, frame, numbering)

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

  let footer-cell = footer-cell(footer, frame, numbering)

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

