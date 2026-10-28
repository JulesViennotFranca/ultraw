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

    l
      .slines
      .map(sl => h(sl.offset * char-width) + sl.body)
      .join("\n", default: [])

    // Lang tag
    if lang-tag != none {
      place(
        right + top,
        dy: (-inset.top + char-height + inset.bottom - measure(lang-tag).height)
          / 2,
        lang-tag,
      )
    }

    // Indentation (over the sub-lines shown at the indentation, only over the first one otherwise)
    if indentation != none {
      let rows = if l.slines.any(sl => sl.offset > 0) { l.slines.len() } else {
        1
      }
      for p in l.pos-indent.slice(0, -1) {
        let x = p * char-width
        place(left + top, line(
          start: (x, -inset.top - extra.top),
          end: (
            x,
            (rows - 1) * (inset.top + char-height + inset.bottom)
              + char-height
              + inset.bottom
              + if rows == l.slines.len() { extra.bottom } else { 0pt },
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
    align(left + horizon, c.body),
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
  let anchors = query(metadata.where(value: (
    uraw-anchor: (id: id, kind: kind),
  )))
  anchors.len() == 0 or anchors.first().location().page() == here().page()
}

// The cells of the rows (an array of cells per row), with anchors in the first and last rows to know the pages they are on
#let anchor-rows(row-cells, id) = {
  if id != none and row-cells.len() > 0 {
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
  row-cells.flatten()
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
      (has-side and (number.fill)(row.i) != none) or (code.fill)(row.i) != none
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
    place(left + top, line(
      start: (0pt, 0pt),
      end: (0pt, height),
      stroke: number.sep,
    ))
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

  row-cells = anchor-rows(row-cells, id)

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


// -----------------------------------------------------------------------------
// Diff
// -----------------------------------------------------------------------------

// A code cell with the highlights of one or two versions (`sources`: the index of the line in a version and the highlights of this line)
#let diff-code-cell(
  l,
  sources,
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
  extra,
) = {
  let blocks = ()
  for (i, highlights) in sources {
    let (slines, b) = hl.compute-highlights(
      i,
      l,
      width,
      inset,
      char-width,
      char-height,
      highlights,
    )
    l.slines = slines
    blocks += b
  }
  code-block(
    l,
    blocks,
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

#let render-diff(
  rows,
  versions,
  same-code,
  number,
  code,
  diff-marker,
  general,
  gutter,
  frame,
  header,
  footer,
  lang-tag-block,
  char-width,
  char-height,
  id,
) = {
  // The columns, by key: the number, marker and diff marker columns and the code of each version (only once for merged codes), and the gutter between separated codes
  let columns = ()
  for v in ("old", "new") {
    let side = (
      (number.visible, "number"),
      (versions.at(v).marker.visible, "marker"),
      (diff-marker.visible, "diff-marker"),
      (true, "code"),
    )
    if v == "new" and not same-code and gutter > 0pt {
      columns.push(("new-gutter", gutter))
    }
    for (visible, key) in side {
      let shared = same-code and key != "number"
      if visible and not (shared and v == "old") {
        columns.push((
          if shared { key } else { v + "-" + key },
          if key == "number" { versions.at(v).numbers-width } else if (
            key == "marker"
          ) { versions.at(v).markers-width } else if key == "diff-marker" {
            diff-marker.width
          } else {
            (
              versions.at(v).code.inset.left
                + versions.at(v).code-width
                + versions.at(v).code.inset.right
            )
          },
        ))
      }
    }
  }
  let keys = columns.map(c => c.first())
  let column-widths = columns.map(c => c.last())
  let key(v, name) = if same-code and name != "number" { name } else {
    v + "-" + name
  }
  let has(k) = k in keys
  let first-key(v) = keys.find(k => k.starts-with(v + "-") or same-code)
  let width-between(a, b) = column-widths
    .slice(keys.position(k => k == a), keys.position(k => k == b) + 1)
    .sum()
  let cell(a, b, body) = grid.cell(
    colspan: keys.position(k => k == b) - keys.position(k => k == a) + 1,
    body,
  )

  let nr = rows.len()

  // The parts of the frame of a cell of the row `r` in the columns `a`-`b`: the cells on the sides of the grid have its stroke and radius
  let is-first(r) = r == 0 and header.content == none
  let is-last(r) = r == nr - 1 and footer.content == none
  let framing(r, a, b) = {
    let sides = (
      left: a == keys.first(),
      right: b == keys.last(),
      top: is-first(r),
      bottom: is-last(r),
    )
    let corner(y, x) = if sides.at(y) and sides.at(x) {
      frame.radius.at(y + "-" + x)
    } else { 0pt }
    (
      radius: (
        top-left: corner("top", "left"),
        top-right: corner("top", "right"),
        bottom-left: corner("bottom", "left"),
        bottom-right: corner("bottom", "right"),
      ),
      stroke: sides
        .keys()
        .map(side => (side, if sides.at(side) { frame.stroke.at(side) }))
        .to-dict(),
    )
  }

  let edge(r) = (
    top: if r == 0 { code.edge.top } else { 0pt },
    bottom: if r == nr - 1 { code.edge.bottom } else { 0pt },
  )
  let line-height(v, i) = (
    versions.at(v).lines.at(i).slines.len() * (char-height + code.line-spacing)
  ).to-absolute()
  let row-heights = rows
    .enumerate()
    .map(((r, row)) => {
      let present = ("old", "new").filter(v => row.at(v) != none)
      let heights = if row.kind == "line" {
        present.map(v => line-height(v, row.at(v)))
      } else if "span" in row { (row.span.height,) } else {
        present.map(v => row.at(v).height)
      }
      calc.max(..heights) + edge(r).top + edge(r).bottom
    })

  // The separator between the gutter and the code, on the left of the first cell of the code side
  let gutter-visible(v) = number.visible or versions.at(v).marker.visible
  let with-sep(v, body, height) = if gutter-visible(v) and number.sep != none {
    body
    place(left + top, line(
      start: (0pt, 0pt),
      end: (0pt, height),
      stroke: number.sep,
    ))
  } else { body }

  let code-fill(v, i, k) = if versions.at(v).status.at(i) == "whole" {
    versions.at(v).conf.fill
  } else { (code.fill)(k) }

  let side(body, width, inset, fill, alignment, height, extra, f) = side-cell(
    body,
    width,
    height,
    ut.grow-inset(inset, extra),
    f.radius,
    f.stroke,
    fill,
    none,
    alignment,
  )

  let number-cell(v, i, k, height, extra, f) = {
    let conf = versions.at(v).conf
    let changed = i != none and versions.at(v).status.at(i) != "same"
    let body = if i == none { [] } else {
      let n = versions.at(v).number.cells.at(i)
      if changed and conf.number-color != auto {
        text(fill: conf.number-color, n)
      } else { (versions.at(v).number.color)(k, n) }
    }
    let fill = if i == none { general.blank-fill } else if (
      changed and conf.number-fill != auto
    ) { conf.number-fill } else { (versions.at(v).number.fill)(k) }
    side(
      body,
      versions.at(v).numbers-width,
      number.inset,
      fill,
      number.alignment,
      height,
      extra,
      f,
    )
  }

  let marker-cell(v, body, fill, height, extra, f) = side(
    if body != none { body } else { [] },
    versions.at(v).markers-width,
    versions.at(v).marker.inset,
    fill,
    number.alignment.y + right,
    height,
    extra,
    f,
  )

  // The cells of a line of a version (the code of a merged unchanged line having the highlights of both versions)
  let code-side-cells(v, row, k, r, height, extra) = {
    let i = row.at(v)
    let status = versions.at(v).status.at(i)
    let fill = code-fill(v, i, k)
    let cells = ()
    if diff-marker.visible {
      cells.push(side(
        if status == "same" { diff-marker.unchanged } else {
          versions.at(v).conf.diff-marker
        },
        diff-marker.width,
        diff-marker.inset,
        fill,
        center + number.alignment.y,
        height,
        extra,
        framing(r, key(v, "diff-marker"), key(v, "diff-marker")),
      ))
    }
    let f = framing(r, key(v, "code"), key(v, "code"))
    let sources = if same-code and row.old != none and row.new != none {
      (("old", row.old), ("new", row.new))
    } else { ((v, i),) }
    cells.push(diff-code-cell(
      versions.at(v).lines.at(i),
      sources.map(((sv, si)) => (si, versions.at(sv).highlights.at(si))),
      versions.at(v).code-width,
      height,
      versions.at(v).code.inset,
      f.radius,
      f.stroke,
      fill,
      if (if same-code { k == 0 } else { v == "new" and i == 0 }) {
        lang-tag-block
      },
      char-width,
      char-height,
      code.indentation,
      extra,
    ))
    cells.first() = with-sep(v, cells.first(), height)
    cells
  }

  // A blank cell (or the gutter of the separated new code when `fill` is given), separated from the old code
  let blank(a, b, r, height, fill: general.blank-fill) = {
    let f = framing(r, a, b)
    cell(a, b, block(
      width: width-between(a, b),
      height: height,
      radius: f.radius,
      stroke: f.stroke + if a == "new-gutter" { (left: general.sep) },
      fill: fill,
    ))
  }

  // The width of the gutter of a version
  let pre-width(v) = ("number", "marker")
    .map(name => key(v, name))
    .filter(has)
    .map(k => width-between(k, k))
    .sum(default: 0pt)

  // A comment in the columns of a version from `from` (with the gutter of the separated new code) to `to` (the code by default), its marker being in the gutter of the version, its text being shifted by `shift` (the gutter of the separated new code by default)
  let comment-cells(v, c, k, from, r, height, extra, to: auto, shift: auto) = {
    let to = if to == auto { key(v, "code") } else { to }
    let shift = if shift != auto { shift } else if from == "new-gutter" {
      gutter
    } else { 0pt }
    let c = c + (inset: ut.grow-inset(c.inset, extra))
    c.inset.left += shift
    if c.marker == none {
      let f = framing(r, from, to)
      c.width = width-between(from, to)
      return (
        cell(from, to, comment-cell(
          c,
          height,
          f.radius,
          f.stroke + if from == "new-gutter" { (left: general.sep) },
          code.indentation,
          char-width,
        )),
      )
    }

    let fill = if c.marker-fill == auto { c.fill } else if (
      c.marker-fill == none
    ) { (number.fill)(k) } else { c.marker-fill }
    let cells = ()
    if from == "new-gutter" {
      cells.push(blank("new-gutter", "new-gutter", r, height, fill: fill))
    }
    for gv in if same-code { ("old", "new") } else { (v,) } {
      if number.visible {
        cells.push(side(
          if gv == v and c.placement == "number" { c.marker } else { [] },
          versions.at(gv).numbers-width,
          number.inset,
          fill,
          number.alignment,
          height,
          extra,
          framing(r, key(gv, "number"), key(gv, "number")),
        ))
      }
    }
    if versions.at(v).marker.visible {
      cells.push(marker-cell(
        v,
        if c.placement == "marker" { c.marker },
        fill,
        height,
        extra,
        framing(r, key(v, "marker"), key(v, "marker")),
      ))
    }
    let first-code-key = if diff-marker.visible { key(v, "diff-marker") } else {
      key(v, "code")
    }
    let f = framing(r, first-code-key, to)
    c.width = width-between(first-code-key, to)
    cells.push(cell(first-code-key, to, with-sep(
      v,
      comment-cell(c, height, f.radius, f.stroke, code.indentation, char-width),
      height,
    )))
    cells
  }

  let k = 0
  let row-cells = ()
  for (r, row) in rows.enumerate() {
    let height = row-heights.at(r)
    let extra = edge(r)
    let cells = ()

    if row.kind == "line" {
      k = row.k
      if same-code {
        let v = if row.new != none { "new" } else { "old" }
        if number.visible {
          for nv in ("old", "new") {
            cells.push(number-cell(
              nv,
              row.at(nv),
              k,
              height,
              extra,
              framing(r, key(nv, "number"), key(nv, "number")),
            ))
          }
        }
        if versions.new.marker.visible {
          let m = ("new", "old")
            .filter(mv => row.at(mv) != none)
            .map(mv => versions.at(mv).markers.at(row.at(mv)))
            .find(m => m != none)
          cells.push(marker-cell(
            "new",
            m,
            (number.fill)(k),
            height,
            extra,
            framing(r, "marker", "marker"),
          ))
        }
        cells += code-side-cells(v, row, k, r, height, extra)
      } else {
        for v in ("old", "new") {
          let from = if v == "new" and has("new-gutter") { "new-gutter" } else {
            first-key(v)
          }
          if from == "new-gutter" and row.new != none {
            cells.push(blank(
              "new-gutter",
              "new-gutter",
              r,
              height,
              fill: code-fill("new", row.new, k),
            ))
          }
          if row.at(v) == none {
            cells.push(blank(from, key(v, "code"), r, height))
            continue
          }
          if number.visible {
            cells.push(number-cell(
              v,
              row.at(v),
              k,
              height,
              extra,
              framing(r, key(v, "number"), key(v, "number")),
            ))
          }
          if versions.at(v).marker.visible {
            cells.push(marker-cell(
              v,
              versions.at(v).markers.at(row.at(v)),
              (versions.at(v).number.fill)(k),
              height,
              extra,
              framing(r, key(v, "marker"), key(v, "marker")),
            ))
          }
          cells += code-side-cells(v, row, k, r, height, extra)
        }
      }
    } else if "span" in row {
      // A comment spanning over both separated codes (its marker being in the gutter of the old code), its text being at the same place as in its code
      let c = row.span
      cells += comment-cells(
        "old",
        c,
        k,
        first-key("old"),
        r,
        height,
        extra,
        to: keys.last(),
        shift: if c.version == "new" {
          (
            width-between(first-key("old"), "old-code")
              + gutter
              + if c.marker != none {
                pre-width("new") - pre-width("old")
              } else {
                0pt
              }
          )
        } else { 0pt },
      )
    } else if same-code {
      let v = if row.new != none { "new" } else { "old" }
      cells += comment-cells(v, row.at(v), k, keys.first(), r, height, extra)
    } else {
      for v in ("old", "new") {
        let from = if v == "new" and has("new-gutter") { "new-gutter" } else {
          first-key(v)
        }
        cells += if row.at(v) == none {
          (blank(from, key(v, "code"), r, height),)
        } else { comment-cells(v, row.at(v), k, from, r, height, extra) }
      }
    }
    row-cells.push(cells)
  }

  let cells = anchor-rows(row-cells, id)
  let heights = row-heights
  let header-cell = header-cell(header, frame, keys.len(), id)
  if header-cell != none {
    heights.insert(0, auto)
    cells.insert(0, header-cell)
  }
  let footer-cell = footer-cell(footer, frame, keys.len(), id)
  if footer-cell != none {
    heights.push(auto)
    cells.push(footer-cell)
  }

  grid(columns: column-widths, rows: heights, ..cells)
}

// -----------------------------------------------------------------------------
// Lang tag on the frame
// -----------------------------------------------------------------------------

/// Return the vertical alignment of the lang tag.
///
/// - lt (dictionary):
/// -> alignment
#let lang-tag-alignment(lt) = {
  if lt.placement == "top-left" or lt.placement == "bottom-left" {
    left
  } else if lt.placement == "top" or lt.placement == "bottom" {
    center
  } else if lt.placement == "top-right" or lt.placement == "bottom-right" {
    right
  }
}

/// Return a placed object containing the lang tag.
///
/// - lt (dictionary):
/// - lt-block (block):
/// -> place
#let place-frame-lang-tag(lt, lt-block) = {
  place(
    if lt.placement == "left-top" { left + top } else if lt.placement
      == "left" { left + horizon } else if lt.placement == "left-bottom" {
      left + bottom
    } else if lt.placement == "right-top" { right + top } else if lt.placement
      == "right" { right + horizon } else if lt.placement == "right-bottom" {
      right + bottom
    },

    dx: if (
      lt.placement == "left-top"
        or lt.placement == "left"
        or lt.placement == "left-bottom"
    ) { -1.1em } else { 1.1em },

    lt-block,
  )
}
