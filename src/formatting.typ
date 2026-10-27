#import "common.typ" as cm
#import "content.typ" as ct
#import "highlight.typ" as hl
#import "lang-tag.typ" as lt
#import "utils.typ" as ut

// -----------------------------------------------------------------------------
// Frame
// -----------------------------------------------------------------------------

#let frame-width(frame, layout-size) = {
  if type(frame.width) == ratio {
    frame.width = layout-size.width * frame.width
  } else if type(frame.width) == relative {
    frame.width = layout-size.width * frame.width.ratio + frame.width.length
  }
  return frame
}

#let frame(frame, lang-tag, with-dst) = {
  frame.radius = ut.full-radius(frame.radius)
  if lang-tag.visible {
    if lang-tag.placement == "top-left" or lang-tag.placement == "left-top" {
      frame.radius.top-left = 0mm
    }
    if (
      lang-tag.placement == "bottom-left" or lang-tag.placement == "left-bottom"
    ) {
      frame.radius.bottom-left = 0mm
    }
    if lang-tag.placement == "top-right" or lang-tag.placement == "right-top" {
      frame.radius.top-right = 0mm
    }
    if (
      lang-tag.placement == "bottom-right"
        or lang-tag.placement == "right-bottom"
    ) {
      frame.radius.bottom-right = 0mm
    }
  }

  frame.stroke = with-dst(frame.stroke)
  frame.stroke = ut.full-stroke(frame.stroke)

  return frame
}

// -----------------------------------------------------------------------------
// Header & Footer
// -----------------------------------------------------------------------------

#let header-footer(
  header,
  footer,
  frame,
  code,
  lang-tag,
  base-style,
  nbr-lines,
  with-dst,
) = {
  header.insert(
    "tag",
    if lang-tag.visible and lang-tag.placement == "header" { lang-tag.block },
  )

  if header.content != none {
    header.content = cm.with-style(base-style(), header.content)
  }
  if footer.content != none {
    footer.content = cm.with-style(base-style(), footer.content)
  }

  header.fill = if header.fill == auto {
    (code.fill)(-1)
  } else {
    header.fill
  }
  footer.fill = if footer.fill == auto {
    (code.fill)(nbr-lines)
  } else {
    footer.fill
  }

  header.inset = ut.full-inset(header.inset)
  footer.inset = ut.full-inset(footer.inset)

  header.radius = (
    top-left: frame.radius.top-left,
    top-right: frame.radius.top-right,
  )
  footer.radius = (
    bottom-left: frame.radius.bottom-left,
    bottom-right: frame.radius.bottom-right,
  )

  header.sep = with-dst(header.sep)
  header.stroke = (
    top: frame.stroke.top,
    left: frame.stroke.left,
    right: frame.stroke.right,
    bottom: if header.sep == auto { frame.stroke.top } else { header.sep },
  )
  if header.content != none { let _ = header.remove("sep") }
  footer.sep = with-dst(footer.sep)
  footer.stroke = (
    top: if footer.sep == auto { frame.stroke.bottom } else { footer.sep },
    left: frame.stroke.left,
    right: frame.stroke.right,
    bottom: frame.stroke.bottom,
  )

  return (header, footer)
}

/// Align the header and the footer with the code when they are `code-aligned`.
///
/// - header (dictionary): The formatted header parameters.
/// - footer (dictionary): The formatted footer parameters.
/// - pre-width (length): The width of the columns before the code.
/// -> array: the header and the footer parameters
#let align-header-footer(header, footer, pre-width) = {
  if header.remove("code-aligned") { header.inset.left = pre-width }
  if footer.remove("code-aligned") { footer.inset.left = pre-width }
  return (header, footer)
}

// -----------------------------------------------------------------------------
// Numbering
// -----------------------------------------------------------------------------

#let number(number, nbr-lines, jumps, code, with-dst) = {
  assert(
    type(number.start) == int,
    message: "The `start` of the number must be an integer.",
  )
  number.start = if not number.visible {
    1
  } else if number.end != none {
    (
      number.end
        + 1
        - nbr-lines
        - jumps.map(j => j.to - j.from - 1).sum(default: 0)
    )
  } else {
    number.start
  }

  if number.inset == auto { number.inset = code.inset }
  number.inset = ut.line-inset(number.inset, code.line-spacing)

  number.sep = with-dst(number.sep)

  return number
}

#let add-line-label(n, line-reference, version: none) = {
  let figure-label = cm.uraw-figure.get()
  if figure-label != none and line-reference != none {
    [#metadata((
        uraw-line-ref: (
          figure: figure-label,
          number: n,
          reference: line-reference,
          version: version,
        ),
      ))#label(
        str(figure-label) + if version != none { "." + version } + "." + str(n),
      )]
  }
}

/// The shown line number, with the number format applied.
///
/// - number (dictionary): The number parameters.
/// - n (int): The line number.
/// -> str, content
#let shown-number(number, n) = if number.format == auto {
  str(n)
} else if type(number.format) == str {
  let k = number.format.position("1")
  assert(
    k != none,
    message: "A number format given as a string must contain a `1`, replaced by the line number (as \"1:\").",
  )
  number.format.slice(0, k) + str(n) + number.format.slice(k + 1)
} else {
  let n = (number.format)(n)
  if type(n) == int { str(n) } else { n }
}

/// Format the number cells, a marker of `number-markers` taking the place of the number of its line.
///
/// - number (dictionary): The number parameters.
/// - general (dictionary): The general parameters.
/// - number-markers (array): The markers shown in the number column, for each line (`none` if it has none).
/// - line-numbers (array): The displayed line numbers.
/// -> dictionary
#let number-cells(
  number,
  general,
  number-markers,
  line-numbers,
  version: none,
) = {
  number.cells = line-numbers
    .enumerate()
    .map(((i, n)) => if number-markers.at(i) != none {
      number-markers.at(i)
    } else if n == none or not number.visible { [] } else {
      shown-number(number, n)
      add-line-label(n, general.line-reference, version: version)
    })

  return number
}

#let line-numbers(number, nbr-lines, jumps, jumps-map) = {
  let line-numbers = ()
  for i in range(nbr-lines) {
    line-numbers.push(if i == 0 {
      number.start
    } else {
      let prev = line-numbers.last()
      if str(prev) in jumps-map { jumps-map.at(str(prev)).to } else { prev + 1 }
    })
  }

  for j in jumps {
    assert(
      j.from in line-numbers,
      message: "The jump from line "
        + str(j.from)
        + " does not start from a line of the code block.",
    )
  }

  let line-index(n) = {
    let i = line-numbers.position(d => d == n)
    assert(
      i != none,
      message: "The line " + str(n) + " is not displayed in the code block.",
    )
    i
  }

  return (line-numbers, line-index)
}

// -----------------------------------------------------------------------------
// Marker
// -----------------------------------------------------------------------------

#let marker(general, number, code) = {
  let marker = (:)
  marker.over-number = general.marker-over-number and number.visible

  marker.inset = if number.visible { number.inset } else { code.inset }
  marker.inset = ut.line-inset(marker.inset, code.line-spacing)

  return marker
}

/// Split the markers between the number column and the marker column, the marker column being visible when it has a marker.
///
/// - line-markers (array): The marker of each line (`none` if it has none).
/// - comments (array): The formatted comments, whose marker is placed in the column given by their `placement`.
/// - marker (dictionary): The marker column parameters.
/// -> array
#let markers(line-markers, comments, marker) = {
  let comment-markers(placement) = comments
    .filter(c => c.marker != none and c.placement == placement)
    .map(c => c.marker)

  // The markers in the number column (by line), and all of them
  let number-markers = line-markers.map(m => if marker.over-number { m })
  let all-number-markers = (
    number-markers.filter(m => m != none) + comment-markers("number")
  )
  // The markers in the marker column (by line), and all of them
  let markers = line-markers.map(m => if not marker.over-number { m })
  let all-markers = markers.filter(m => m != none) + comment-markers("marker")

  marker.visible = all-markers.len() > 0
  marker.number-markers = all-number-markers
  marker.markers = all-markers

  return (number-markers, markers, marker)
}

// -----------------------------------------------------------------------------
// Code
// -----------------------------------------------------------------------------

#let code(code, with-dst) = {
  code.indentation = with-dst(code.indentation)

  let edge = ut.vertical-inset(code.inset)
  code.edge = (
    top: edge.top.to-absolute(),
    bottom: edge.bottom.to-absolute(),
  )
  code.inset = ut.line-inset(code.inset, code.line-spacing)

  return code
}

// -----------------------------------------------------------------------------
// Coloring
// -----------------------------------------------------------------------------

#let apply-color(color, n, it) = if color == auto {
  it
} else if type(color) == function {
  let c = color(n)
  if c != none { text(fill: c, it) } else { it }
} else {
  text(fill: color, it)
}

#let coloring(
  number,
  code,
  general,
  frame,
  line-numbers,
  nbr-lines,
) = {
  number.true-number = i => if (
    number.visible
      and general.coloring-follow-number
      and nbr-lines > 0
      and line-numbers.len() > 0
  ) {
    if i < 0 {
      line-numbers.first() + i
    } else if i >= nbr-lines {
      line-numbers.last() + i - nbr-lines + 1
    } else {
      line-numbers.at(i)
    }
  } else { i + 1 }

  code.fill = if type(code.fill) == function {
    i => (code.fill)((number.true-number)(i))
  } else { i => code.fill }
  number.fill = if type(number.fill) == function {
    i => (number.fill)((number.true-number)(i))
  } else { i => number.fill }
  number.fill = i => {
    let c = (number.fill)(i)
    if c == auto { (code.fill)(i) } else { c }
  }

  number.color = if type(number.color) == function {
    i => (number.color)((number.true-number)(i))
  } else { i => number.color }
  number.color = (i, it) => {
    let c = (number.color)(i)
    if c == none { it } else { text(fill: c, it) }
  }

  return (number, code)
}

// -----------------------------------------------------------------------------
// Lang tag
// -----------------------------------------------------------------------------

#let lang-tag(lang-tag, lang, frame, header, with-dst) = {
  lang-tag.format = if lang-tag.format == auto { it => it } else {
    lang-tag.format
  }

  if lang-tag.visible {
    lt.check-lang-tag-mode(lang-tag.mode)
    lt.check-lang-tag-placement(lang-tag.placement)
  }

  if lang-tag.placement == "header" and header.content == none {
    lang-tag.placement = "code"
  }
  lang-tag.insert(
    "in-code",
    lang-tag.placement == "code" or lang-tag.placement == "inline",
  )
  lang-tag.insert(
    "on-frame",
    lang-tag.placement not in ("code", "inline", "header"),
  )

  lang-tag.stroke = with-dst(lang-tag.stroke)

  lang-tag.block = if lang-tag.visible {
    lt.lang-tag-block(lang, lang-tag, frame)
  } else { none }

  return lang-tag
}

// -----------------------------------------------------------------------------
// Lines
// -----------------------------------------------------------------------------

/// The lines of a raw element: their content, their text, the positions of their indentation levels (in characters) and their end.
///
/// - it (content): The raw element.
/// - code (dictionary): The code parameters.
/// -> array
#let lines(it, code) = {
  // The number of spaces of an indentation level is the tab size of the raw element
  let indent-size = it.tab-size

  let lines = it.lines.map(l => if ct.is-whitespace-line(l.text) {
    (line: [], text: "", pos-indent: (0,), line-end: 0)
  } else {
    let num-indent = ct.get-text-indent(l.text, indent-size)
    let pos-indent = range(num-indent + 1).map(i => i * indent-size)
    (
      line: l.body,
      text: l.text,
      pos-indent: pos-indent,
      line-end: ct.text-len(l.text),
    )
  })

  // The blank lines have the indentation of the next line
  let i = lines.len() - 2
  while 0 <= i {
    if lines.at(i).text.len() == 0 {
      lines.at(i).pos-indent = lines.at(i + 1).pos-indent
    }
    i -= 1
  }

  return lines
}

/// Break the lines in sub-lines fitting in the code width.
///
/// - lines (array): The lines (see `lines`).
/// - code-width (length): The width of the code.
/// - lang-tag (dictionary): The lang tag parameters, with its `width`.
/// - char-width (length):
/// -> array
#let break-lines(lines, code-width, lang-tag, char-width) = {
  lines
    .enumerate()
    .map(((i, l)) => (
      line: l.line,
      slines: ct.format-line(
        l.line,
        code-width
          + if lang-tag.visible and lang-tag.placement == "code" {
            -lang-tag.width
          },
        char-width,
        l.line-end,
        if lang-tag.placement == "inline" and i == 0 { lang-tag.width },
      ),
      pos-indent: l.pos-indent,
      line-end: l.line-end,
    ))
}

// -----------------------------------------------------------------------------
// Highlights
// -----------------------------------------------------------------------------

/// Resolve the highlights: the lines of the manual ones become indexes, the automatic columns are computed, and they are checked.
///
/// - manual (array): The manual highlights (on displayed line numbers).
/// - delimited (array): The highlights read from the delimiters (on line indexes).
/// - lines (array): The lines (see `lines`).
/// - line-index (function): The index of a displayed line number.
/// -> array: the highlights, the last ones first
#let highlights(manual, delimited, lines, line-index, with-dst) = {
  let manual = manual.map(h => {
    h.range.first().first() = line-index(h.range.first().first())
    h.range.last().first() = line-index(h.range.last().first())
    h
  })

  let highlights = hl
    .merge-right-sort-highlights(manual, delimited)
    .map(h => {
      if h.range.first().last() == auto {
        h.range.first().last() = lines
          .at(h.range.first().first())
          .pos-indent
          .last()
      }
      if h.range.last().last() == auto {
        h.range.last().last() = lines.at(h.range.last().first()).line-end
      }
      h.stroke = with-dst(h.stroke)
      h
    })

  let _ = highlights.map(hl.check-highlight)

  return highlights.rev()
}

/// Group the highlights by line, with the highlight blocks touching each other.
///
/// - highlights (array): The resolved highlights (see `highlights`).
/// - lines (array): The lines broken in sub-lines (see `break-lines`).
/// - code-width (length):
/// - code (dictionary): The code parameters.
/// - char-width (length):
/// -> array: for each line, its highlights
#let highlights-by-line(highlights, lines, code-width, code, char-width) = {
  let by-line = lines.map(_ => ())
  for h in highlights {
    let h = (
      h
        + (
          touches: hl.compute-touches(
            h,
            lines,
            code-width,
            code.inset,
            char-width,
          ),
        )
    )
    for i in range(h.range.first().first(), h.range.last().first() + 1) {
      by-line.at(i).push(h)
    }
  }
  return by-line
}

// -----------------------------------------------------------------------------
// Comments
// -----------------------------------------------------------------------------

#let single-comment(comment, gap, key, number, base-style) = {
  let comment = comment + (gap: gap, key: key)

  assert(
    comment.indent in ("frame", "code", "line", "guideline"),
    message: "The `indent` of a comment must be \"frame\", \"code\", \"line\" or \"guideline\".",
  )
  assert(
    comment.placement in ("number", "marker"),
    message: "The `placement` of a comment marker must be \"number\" or \"marker\".",
  )
  // Without numbers, the marker is in the marker column
  if not number.visible { comment.placement = "marker" }
  // A comment with a marker starts after the gutter, so at the start of the code
  comment.in-code = comment.indent != "frame" or comment.marker != none
  comment.to-indent = comment.indent == "guideline"
  comment.indented = comment.indent in ("line", "guideline")

  let body = comment.content
  if comment.style != none {
    body = (comment.style)(body)
    if comment.marker != none {
      comment.marker = (comment.style)(comment.marker)
    }
  }
  // The comments look as they would outside of the raw block
  comment.body = cm.with-style(base-style(), body)
  if comment.marker != none {
    comment.marker = cm.with-style(base-style(), comment.marker)
  }

  return comment
}

// The comments of the jumps (the style of a comment being given by its content, a jump has no `comment-style`), with the `extra` keys of the jumps (with their default value)
#let jump-comments(jumps, jump, comment, line-index, format, extra: (:)) = {
  jumps
    .map(j => {
      ut.check-keys(
        j,
        jump.keys().filter(k => k != "comment-style")
          + ("from", "to")
          + extra.keys(),
        "a jump",
      )
      let jc = ut.filter-add-dict(jump, j)

      let settings = (:)
      for (k, v) in jc.pairs() {
        if k.starts-with("comment-") {
          let k = k.slice("comment-".len())
          settings.insert(k, if v == auto { comment.at(k) } else { v })
        }
      }

      let content = jc.comment
      if type(content) == function { content = content(j.from, j.to) }
      if content != none {
        format(
          settings
            + extra.keys().map(k => (k, j.at(k, default: extra.at(k)))).to-dict()
            + (
              content: content,
              copy-before: true,
            ),
          line-index(j.from) + 1,
          none,
        )
      }
    })
    .filter(c => c != none)
}

// The comments (the style of a comment being given by its content, a comment has no `style`), with their `extra` keys (with their default value)
#let comments(comments, comment, line-numbers, format, extra: (:)) = {
  ut
    .single-to-list(comments)
    .map(c => {
      let c = c
      if type(c) == array {
        assert(
          c.len() == 2,
          message: "A comment given as an array must be of the form `(line, content)`.",
        )
        c = (after: c.at(0), content: c.at(1))
      }
      assert(
        type(c) == dictionary
          and ("after" in c or "before" in c)
          and "content" in c,
        message: "A comment must have an `after` or `before` line and a `content`.",
      )
      ut.check-keys(
        c,
        comment.keys().filter(k => k != "style")
          + ("after", "before", "content")
          + extra.keys(),
        "a comment",
      )

      let after = "after" in c
      let n = if after { c.after } else { c.before }
      assert(
        type(n) == int,
        message: "The `after` or `before` line of a comment must be an integer.",
      )

      format(
        ut.filter-add-dict(comment, c)
          + extra.keys().map(k => (k, c.at(k, default: extra.at(k)))).to-dict()
          + (
            content: c.content,
            copy-before: after,
          ),
        line-numbers.filter(d => if after { d <= n } else { d < n }).len(),
        if after { 2 * n } else { 2 * n - 1 },
      )
    })
    .sorted(key: c => c.key)
}

/// Place the comments horizontally: their indentation and their insets.
///
/// - comments (array): The formatted comments.
/// - lines (array): The lines (see `lines`).
/// - number (dictionary): The number parameters.
/// - code (dictionary): The code parameters.
/// - numbers-width (length): The width of the number column.
/// - pre-width (length): The width of the gutter (the columns before the code: numbers and markers).
/// - gutter-inset (dictionary): The inset of the first column of the gutter.
/// - char-width (length):
/// - code-start (auto, length): The start of the code (after the diff markers of diffs), the end of the gutter by default.
/// -> array
#let comments-position(
  comments,
  lines,
  code,
  pre-width,
  gutter-inset,
  char-width,
  code-start: auto,
) = comments.map(c => {
  let code-start = if code-start == auto { pre-width } else { code-start }
  // An indented comment takes the indentation of the line before it (or after it for `before`)
  if c.indented {
    let k = if c.copy-before { c.gap - 1 } else { c.gap }
    c.pos-indent = if 0 <= k and k < lines.len() {
      lines.at(k).pos-indent
    } else { () }
  }

  // The comment cell starts after the gutter when it has a marker (the marker being in the gutter), at the left of the frame otherwise
  let cell-start = if c.marker != none { pre-width } else { 0mm }
  // The horizontal position of the code in the comment cell
  c.code-offset = code-start - cell-start
  let indent = if c.indented and c.pos-indent.len() > 0 {
    c.pos-indent.last() * char-width
  } else { 0mm }
  let left = if c.in-code {
    c.code-offset + code.inset.left + indent
  } else if code-start.to-absolute() > 0mm {
    gutter-inset.left
  } else { code.inset.left }
  c.inset = (
    left: left,
    right: code.inset.right,
    top: code.inset.top,
    bottom: code.inset.bottom,
  )
  c
})

/// Size the comments (once the code width is known) and group them by gap (the gap `k` is before the line of index `k`).
///
/// - comments (array): The placed comments (see `comments-position`).
/// - code (dictionary): The code parameters.
/// - code-width (length):
/// - number (dictionary): The number parameters.
/// - numbers-width (length): The width of the number column.
/// - marker (dictionary): The marker column parameters.
/// - markers-width (length): The width of the marker column.
/// - nbr-lines (int):
/// -> array
#let comments-by-gap(
  comments,
  code,
  code-width,
  number,
  numbers-width,
  marker,
  markers-width,
  nbr-lines,
) = {
  let by-gap = range(nbr-lines + 1).map(_ => ())
  for c in comments {
    c.insert(
      "width",
      c.code-offset + code.inset.left + code-width + code.inset.right,
    )
    let body-height = measure(width: c.width, block(
      inset: c.inset,
      c.body,
    )).height
    // The marker of a comment is in the number or the marker column
    c.height = if c.marker != none {
      let (width, inset) = if c.placement == "number" {
        (numbers-width, number.inset)
      } else { (markers-width, marker.inset) }
      calc.max(
        body-height,
        measure(width: width, block(inset: inset, c.marker)).height,
      )
    } else { body-height }
    by-gap.at(c.gap).push(c)
  }
  return by-gap
}

// -----------------------------------------------------------------------------
// Jumps
// -----------------------------------------------------------------------------

#let jumps(jumps, number, nbr-lines) = {
  // Jumps only have an effect when the numbers are visible
  let jumps = if number.visible { jumps } else { () }
  jumps = ut
    .single-to-list(jumps)
    .map(j => {
      let j = j
      if type(j) == array {
        assert(
          j.len() == 2,
          message: "A jump given as an array must be of the form `(from, to)`.",
        )
        j = (from: j.at(0), to: j.at(1))
      }
      assert(
        type(j) == dictionary and "from" in j and "to" in j,
        message: "A jump must have a `from` and a `to` line.",
      )
      assert(
        type(j.from) == int and type(j.to) == int,
        message: "The `from` and `to` lines of a jump must be integers.",
      )
      assert(
        j.from < j.to,
        message: "The jump from line "
          + str(j.from)
          + " to line "
          + str(j.to)
          + " must go forward.",
      )
      j
    })

  // Store jumps at their starting line
  let jumps-map = (:)
  for j in jumps {
    assert(
      not str(j.from) in jumps-map,
      message: "Several jumps start from line " + str(j.from) + ".",
    )
    jumps-map.insert(str(j.from), j)
  }

  // Sort the jumps and verify than none overlap
  // TODO: overlapping are merged
  let sorted-jumps = jumps.sorted(key: j => j.from)
  for k in range(sorted-jumps.len() - 1) {
    let (j1, j2) = (sorted-jumps.at(k), sorted-jumps.at(k + 1))
    assert(
      j1.to <= j2.from,
      message: "The jump from line "
        + str(j1.from)
        + " to line "
        + str(j1.to)
        + " overlaps the jump from line "
        + str(j2.from)
        + " to line "
        + str(j2.to)
        + ".",
    )
  }

  return (jumps, jumps-map)
}

// -----------------------------------------------------------------------------
// Pseudo code
// -----------------------------------------------------------------------------

/// The contents given to a pseudo code helper (`indent` or `no-number`), `none` if it is not one.
///
/// - it (any): A positional argument of pseudo code.
/// - key (str): The key of the helper (`"uraw-indent"` or `"uraw-no-number"`).
/// -> array, none
#let pseudo-helper-contents(it, key) = if (
  type(it) == content
    and it.func() == metadata
    and type(it.value) == dictionary
    and key in it.value
) { it.value.at(key) }

/// Split the arguments of pseudo code in lines, with their indentation level.
///
/// - args (array): The positional arguments: each content starts a new line, the contents of indented blocks (`indent`) are indented by one level, and the ones of `no-number` have no number.
/// -> array: the lines, as dictionaries with a `body` (content), a `level` (int), and wether they are `numbered`
#let pseudo-lines(args) = {
  let lines = ()
  for it in args {
    let indented = pseudo-helper-contents(it, "uraw-indent")
    let unnumbered = pseudo-helper-contents(it, "uraw-no-number")
    if indented != none {
      for l in pseudo-lines(indented) { lines.push(l + (level: l.level + 1)) }
    } else if unnumbered != none {
      for l in pseudo-lines(unnumbered) { lines.push(l + (numbered: false)) }
    } else {
      lines.push((body: it, level: 0, numbered: true))
    }
  }
  return lines
}

/// The number of each line of pseudo code, the lines without numbers not being counted.
///
/// - lines (array): The lines (see `pseudo-lines`).
/// - number (dictionary): The number parameters.
/// - jumps (array): The jumps.
/// - jumps-map (dictionary): The jumps by starting line.
/// -> array: the numbers of the lines (`none` for the lines without number), and the numbers used to color them (the one of the previous numbered line for the lines without number)
#let pseudo-line-numbers(lines, number, jumps, jumps-map) = {
  let (numbers, _) = line-numbers(
    number,
    lines.filter(l => l.numbered).len(),
    jumps,
    jumps-map,
  )

  let line-numbers = ()
  let coloring-numbers = ()
  let k = 0
  for l in lines {
    if l.numbered {
      line-numbers.push(numbers.at(k))
      k += 1
    } else {
      line-numbers.push(none)
    }
    coloring-numbers.push(if k > 0 { numbers.at(k - 1) } else {
      number.start
    })
  }

  return (line-numbers, coloring-numbers)
}

/// The content of a line of pseudo code, indented and styled.
///
/// - l (dictionary): The line (see `pseudo-lines`).
/// - code (dictionary): The code parameters, with an absolute `indent-size`.
/// -> content
#let pseudo-line-body(l, code) = pad(
  left: l.level * code.indent-size,
  if code.style != none { (code.style)(l.body) } else { l.body },
)

// -----------------------------------------------------------------------------
// Diff
// -----------------------------------------------------------------------------

// The longest common subsequence of two arrays, as operations: `("=", i, j)` for common elements, `("-", i, none)` for removed ones and `("+", none, j)` for added ones
#let lcs-ops(a, b) = {
  let (n, m) = (a.len(), b.len())

  // The common prefix and suffix
  let p = 0
  while p < n and p < m and a.at(p) == b.at(p) { p += 1 }
  let q = 0
  while q < n - p and q < m - p and a.at(n - 1 - q) == b.at(m - 1 - q) {
    q += 1
  }

  let (a2, b2) = (a.slice(p, n - q), b.slice(p, m - q))
  let (n2, m2) = (a2.len(), b2.len())

  // The lengths of the longest common subsequences of the suffixes
  let w = m2 + 1
  let t = range((n2 + 1) * w).map(_ => 0)
  for i in range(n2 - 1, -1, step: -1) {
    for j in range(m2 - 1, -1, step: -1) {
      t.at(i * w + j) = if a2.at(i) == b2.at(j) {
        t.at((i + 1) * w + j + 1) + 1
      } else {
        calc.max(t.at((i + 1) * w + j), t.at(i * w + j + 1))
      }
    }
  }

  let ops = range(p).map(k => ("=", k, k))
  let (i, j) = (0, 0)
  while i < n2 or j < m2 {
    if i < n2 and j < m2 and a2.at(i) == b2.at(j) {
      ops.push(("=", p + i, p + j))
      i += 1
      j += 1
    } else if (
      j >= m2 or (i < n2 and t.at((i + 1) * w + j) >= t.at(i * w + j + 1))
    ) {
      ops.push(("-", p + i, none))
      i += 1
    } else {
      ops.push(("+", none, p + j))
      j += 1
    }
  }
  ops + range(q).map(k => ("=", n - q + k, m - q + k))
}

// The words, spaces and symbols of a line, with their positions in characters
#let tokenize(s) = (
  s
    .matches(regex("\\w[\\w']*|\\s+|[^\\w\\s]+"))
    .map(m => {
      let start = ct.text-len(s.slice(0, m.start))
      (text: m.text, start: start, end: start + ct.text-len(m.text))
    })
)

// The ranges of the changed tokens, the spaces between changed tokens being changed too, but not the ones at the ends
#let changed-ranges(tokens, changed) = {
  let is-space(k) = tokens.at(k).text.trim() == ""
  let n = tokens.len()

  for k in range(n) {
    if not changed.at(k) and is-space(k) {
      let prev = k > 0 and changed.at(k - 1)
      let next = k < n - 1 and changed.at(k + 1)
      if prev and next { changed.at(k) = true }
    }
  }

  let ranges = ()
  let k = 0
  while k < n {
    if changed.at(k) {
      let e = k
      while e + 1 < n and changed.at(e + 1) { e += 1 }
      let (s2, e2) = (k, e)
      while s2 <= e2 and is-space(s2) { s2 += 1 }
      while e2 >= s2 and is-space(e2) { e2 -= 1 }
      if s2 <= e2 { ranges.push((tokens.at(s2).start, tokens.at(e2).end)) }
      k = e + 1
    } else {
      k += 1
    }
  }
  ranges
}

// The changed ranges of two lines replacing each other, `none` if they are too different
#let line-diff(old-text, new-text) = {
  let (a, b) = (tokenize(old-text), tokenize(new-text))
  let ops = lcs-ops(a.map(t => t.text), b.map(t => t.text))

  // The similarity of the lines, on the characters which are not spaces
  let size(t) = ct.text-len(t.text.replace(regex("\s"), ""))
  let common = ops
    .filter(op => op.at(0) == "=")
    .map(op => size(a.at(op.at(1))))
    .sum(default: 0)
  let total = a.map(size).sum(default: 0) + b.map(size).sum(default: 0)
  if total == 0 or 2 * common / total < .5 { return none }

  let old-changed = a.map(_ => true)
  let new-changed = b.map(_ => true)
  for op in ops.filter(op => op.at(0) == "=") {
    old-changed.at(op.at(1)) = false
    new-changed.at(op.at(2)) = false
  }

  (old: changed-ranges(a, old-changed), new: changed-ranges(b, new-changed))
}

// The difference between two codes: the `items` (`(kind: "same", old: i, new: j)` or `(kind: "hunk", dels: .., adds: ..)`), for each version the `status` of its lines (`"same"`, `"mod"` or `"whole"`) and the changed `ranges` of the modified lines, and for each new line the old line at the same place (`new-to-old`, -1 if there is none)
#let compute-diff(old-texts, new-texts) = {
  let items = ()
  let (dels, adds) = ((), ())
  for op in lcs-ops(old-texts, new-texts) {
    if op.at(0) == "=" {
      if dels.len() + adds.len() > 0 {
        items.push((kind: "hunk", dels: dels, adds: adds))
        (dels, adds) = ((), ())
      }
      items.push((kind: "same", old: op.at(1), new: op.at(2)))
    } else if op.at(0) == "-" {
      dels.push(op.at(1))
    } else {
      adds.push(op.at(2))
    }
  }
  if dels.len() + adds.len() > 0 {
    items.push((kind: "hunk", dels: dels, adds: adds))
  }

  let diff = (
    items: items,
    old: (status: old-texts.map(_ => "same"), ranges: old-texts.map(_ => ())),
    new: (status: new-texts.map(_ => "same"), ranges: new-texts.map(_ => ())),
    new-to-old: new-texts.map(_ => -1),
  )

  let last-old = -1
  for item in items {
    if item.kind == "same" {
      diff.new-to-old.at(item.new) = item.old
      last-old = item.old
      continue
    }
    for i in item.dels { diff.old.status.at(i) = "whole" }
    for (k, j) in item.adds.enumerate() {
      diff.new.status.at(j) = "whole"
      diff.new-to-old.at(j) = item.dels.at(k, default: if item.dels.len() > 0 {
        item.dels.last()
      } else { last-old })
    }
    if item.dels.len() > 0 { last-old = item.dels.last() }

    // The lines replacing each other are compared
    for k in range(calc.min(item.dels.len(), item.adds.len())) {
      let (i, j) = (item.dels.at(k), item.adds.at(k))
      let d = line-diff(old-texts.at(i), new-texts.at(j))
      if d != none {
        diff.old.status.at(i) = "mod"
        diff.new.status.at(j) = "mod"
        diff.old.ranges.at(i) = d.old
        diff.new.ranges.at(j) = d.new
      }
    }
  }

  diff
}

// The columns of a diff: an array of one (merged codes) or two (separated codes) widths
#let diff-columns(columns) = {
  let columns = if type(columns) == int {
    assert(
      columns in (1, 2),
      message: "The `columns` of a diff must be 1 or 2, or an array of one or two widths.",
    )
    range(columns).map(_ => auto)
  } else if type(columns) == array { columns } else { (columns,) }
  assert(
    columns.len() in (1, 2)
      and columns.all(c => (
        c == auto or type(c) in (length, ratio, relative, fraction)
      )),
    message: "The `columns` of a diff must be 1 or 2, or an array of one or two widths (auto, relative or fraction).",
  )
  columns
}

// The entries of a diff (comments, jumps, markers, highlights) with their version: arrays `(..keys)` or `(version, ..keys)`, or dictionaries with an optional `version` (`"new"` by default)
#let versioned(entries, keys, both: false) = {
  let entries = if (
    type(entries) == dictionary
      or (entries.len() > 0 and type(entries.first()) in (int, str))
  ) { (entries,) } else { entries }
  let versions = ("old", "new") + if both { ("both",) } else { () }

  entries.map(e => {
    if type(e) == array {
      assert(
        e.len() in (keys.len(), keys.len() + 1),
        message: "An entry of a diff given as an array must be of the form `("
          + keys.join(", ")
          + ")` or `(version, "
          + keys.join(", ")
          + ")`.",
      )
      let version = if e.len() > keys.len() { e.remove(0) } else { "new" }
      e = keys.zip(e).to-dict() + (version: version)
    }
    let version = e.at("version", default: "new")
    assert(
      version in versions,
      message: "The version of an entry of a diff must be "
        + versions.map(v => "\"" + v + "\"").join(", ", last: " or ")
        + ".",
    )
    e + (version: version)
  })
}

#let of-version(entries, version) = (
  entries
    .filter(e => e.version == version)
    .map(e => {
      let _ = e.remove("version")
      e
    })
)

// The numbers of both versions: the jumps of both versions are given on the new numbers, and jump the same number of lines in the old code
#let diff-numbers(diff-number, diff-jumps, nbr-lines, new-to-old, code, with-dst) = {
  let numbers-of(version, version-jumps) = {
    let (version-jumps, jumps-map) = jumps(
      version-jumps,
      diff-number,
      nbr-lines.at(version),
    )
    let version-number = number(
      diff-number,
      nbr-lines.at(version),
      version-jumps,
      code,
      with-dst,
    )
    let (version-line-numbers, line-index) = line-numbers(
      version-number,
      nbr-lines.at(version),
      version-jumps,
      jumps-map,
    )
    (
      number: version-number,
      jumps: version-jumps,
      line-numbers: version-line-numbers,
      line-index: line-index,
    )
  }

  let both = of-version(diff-jumps, "both")
  let new = numbers-of("new", of-version(diff-jumps, "new") + both)

  let old-jumps = of-version(diff-jumps, "old")
  for j in both.sorted(key: j => j.from) {
    let i = new-to-old.at((new.line-index)(j.from))
    if i >= 0 {
      let from = numbers-of("old", old-jumps).line-numbers.at(i)
      old-jumps.push((from: from, to: from + j.to - j.from))
    }
  }

  (old: numbers-of("old", old-jumps), new: new)
}

// The changed ranges of a version, as highlights
#let diff-changes(diff, version, conf, defaults) = (
  diff
    .at(version)
    .ranges
    .enumerate()
    .map(((i, ranges)) => ranges.map(((s, e)) => hl.format-highlight(
      (
        start: (i, s),
        end: (i, e),
        expand: none,
        sticky: false,
        radius: 0mm,
        fill: conf.fill,
        stroke: none,
      ),
      defaults,
    )))
    .flatten()
)

// The rows of a diff: the lines (`(kind: "line", old: i, new: j)`, one of them being `none` for a line in one version only) and the comments (`(kind: "comment", old: c, new: c)`, one of them being `none` for a comment of one version only, both being set for separated codes)
#let diff-rows(diff, comments, same-code) = {
  let comment-rows(olds, news) = {
    let after(cs) = cs.filter(c => c.copy-before)
    let before(cs) = cs.filter(c => not c.copy-before)
    // The comments spanning over both separated codes are alone in their rows, the ones after the lines first
    let is-span(c) = c.span and not same-code
    let spans = (olds + news).filter(is-span)
    let (olds, news) = (olds, news).map(cs => cs.filter(c => not is-span(c)))
    let span-rows(cs) = cs.map(c => (
      kind: "comment",
      old: none,
      new: none,
      span: c,
    ))
    let single(version, cs) = cs.map(c => (
      kind: "comment",
      old: if version == "old" { c },
      new: if version == "new" { c },
    ))
    let pairs(olds, news) = olds
      .zip(news)
      .map(((o, n)) => (kind: "comment", old: o, new: n))

    if same-code {
      return (
        single("old", after(olds))
          + single("new", after(news))
          + single("old", before(olds))
          + single("new", before(news))
      )
    }
    let (spans-after, spans-before) = (after(spans), before(spans))

    // The comments of both versions are paired: the ones after the lines from the top, the ones before the lines from the bottom
    let (oa, ob, na, nb) = (after(olds), before(olds), after(news), before(news))
    let top = pairs(oa, na)
    let bottom = pairs(ob.rev(), nb.rev()).rev()
    let (oa, na) = (oa.slice(top.len()), na.slice(top.len()))
    let (ob, nb) = (
      ob.slice(0, ob.len() - bottom.len()),
      nb.slice(0, nb.len() - bottom.len()),
    )

    // The remaining comments of one version after the lines are paired with the ones of the other version before the lines
    let (first, firsts) = if oa.len() > 0 { ("old", oa) } else { ("new", na) }
    let (second, seconds) = if ob.len() > 0 { ("old", ob) } else { ("new", nb) }
    let n = if first == second { 0 } else {
      calc.min(firsts.len(), seconds.len())
    }
    let middle = (
      single(first, firsts.slice(0, firsts.len() - n))
        + firsts
          .slice(firsts.len() - n)
          .zip(seconds.slice(0, n))
          .map(((a, b)) => (kind: "comment", (first): a, (second): b))
        + single(second, seconds.slice(n))
    )
    span-rows(spans-after) + top + middle + bottom + span-rows(spans-before)
  }

  let rows = comment-rows(comments.old.at(0), comments.new.at(0))
  let line-rows = ()
  for item in diff.items {
    if item.kind == "same" {
      line-rows.push((kind: "line", old: item.old, new: item.new))
    } else if same-code {
      line-rows += item.dels.map(i => (kind: "line", old: i, new: none))
      line-rows += item.adds.map(j => (kind: "line", old: none, new: j))
    } else {
      for k in range(calc.max(item.dels.len(), item.adds.len())) {
        line-rows.push((
          kind: "line",
          old: item.dels.at(k, default: none),
          new: item.adds.at(k, default: none),
        ))
      }
    }
  }
  for (k, row) in line-rows.enumerate() {
    rows.push(row + (k: k))
    rows += comment-rows(
      if row.old != none { comments.old.at(row.old + 1) } else { () },
      if row.new != none { comments.new.at(row.new + 1) } else { () },
    )
  }
  rows
}
