#import "content.typ" as ct
#import "utils.typ" as ut

// -----------------------------------------------------------------------------
// Checks
// -----------------------------------------------------------------------------

/// Check that the highlight range are correct.
#let check-highlight(hl) = if not hl.is-line {
  let (i_s, j_s) = hl.range.first()
  let (i_e, j_e) = hl.range.last()
  assert(
    i_s < i_e or (i_s == i_e and j_s < j_e),
    message: "There is a empty highlight.",
  )
}

/// Check that a pre-highlight has different left and right delimiters.
#let check-pre-highlight(hl) = {
  assert("ldel" in hl, message: "A highlight has no left delimiter.")
  assert("rdel" in hl, message: "A highlight has no right delimiter.")
  assert(
    hl.ldel != hl.rdel,
    message: "A highlight has the same left and right delimiters.",
  )
}

/// Check pre-highlight one by one and ensure that no pre-highlights share delimiters.
#let check-pre-highlights(hls) = {
  hls = hls.values()
  hls.map(check-pre-highlight)

  for i in range(hls.len()) {
    for j in range(i + 1, hls.len()) {
      assert(
        hls.at(i).ldel != hls.at(j).ldel or hls.at(i).rdel != hls.at(j).rdel,
        message: "Two highlights have the same left and right delimiters.",
      )
    }
  }
}

// -----------------------------------------------------------------------------
// Formatting
// -----------------------------------------------------------------------------

/// Convert the horizontal expansion of a highlight (`none`, `left`, `right` or `center`) to the expanded sides.
#let expand-sides(expand) = {
  assert(
    expand == none
      or (type(expand) == alignment and expand.axis() == "horizontal"),
    message: "The expansion of a highlight must be `none`, `left`, `right` or `center` (for both), use `lined` to make it occupy the height of the lines and connect it between lines.",
  )

  (
    left: expand in (left, start, center),
    right: expand in (right, end, center),
  )
}

#let format-pre-highlight(phl) = (
  ldel: phl.ldel,
  rdel: phl.rdel,
  expand: phl.at("expand", default: center),
  lined: phl.at("lined", default: false),
  radius: phl.at("radius", default: 0mm),
  sharp-break: phl.at("sharp-break", default: false),
  fill: phl.at("fill", default: none),
  code-style: phl.at("code-style", default: it => it),
)

/// Import the style of a manually defined highlight.
#let format-highlight-style(hl, hls) = if "style" in hl {
  assert(
    type(hl.style) == str and hl.style in hls,
    message: "The style of a highlight must be a string referring to the name of an existing highlight.",
  )
  hls.at(hl.style) + hl
} else {
  hl
}

/// Read the starting and end position of an highlight.
#let normalize-position(pos, name) = {
  if type(pos) == int {
    (pos, auto)
  } else if (
    type(pos) == array
      and pos.len() == 2
      and type(pos.first()) == int
      and type(pos.last()) == int
  ) {
    pos
  } else {
    panic(
      "A "
        + name
        + " of a highlight should be an integer or a pair of integers.",
    )
  }
}

/// Fix the range of the highlight.
#let format-highlight(hl) = {
  // A highlight on whole lines: `line: k` or `line: (k1, k2)`
  let is-line = "line" in hl
  let range = if is-line {
    let (k1, k2) = if type(hl.line) == int {
      (hl.line, hl.line)
    } else if (
      type(hl.line) == array
        and hl.line.len() == 2
        and hl.line.all(k => type(k) == int)
    ) {
      hl.line
    } else {
      panic(
        "The `line` of a highlight should be an integer or a pair of integers.",
      )
    }
    assert(
      k1 <= k2,
      message: "The first line of a highlight must be before the last one.",
    )
    ((k1, 0), (k2, auto))
  } else if "range" in hl {
    hl.range
  } else {
    assert("start" in hl, message: "A highlight has no starting point.")
    assert("end" in hl, message: "A highlight has no ending point.")

    let s = normalize-position(hl.start, "starting point")
    let e = normalize-position(hl.end, "ending point")

    (s, e)
  }

  let expand = expand-sides(hl.at("expand", default: center))
  (
    range: range,
    expand: expand,
    lined: hl.at("lined", default: is-line),
    is-line: is-line,
    // Highlights on whole lines have square corners
    radius: if is-line {
      (
        ut.full-radius(hl.at("radius", default: 0mm))
          + (if expand.left { (top-left: 0mm, bottom-left: 0mm) } else { (:) })
          + (
            if expand.right { (top-right: 0mm, bottom-right: 0mm) } else { (:) }
          )
      )
    } else { ut.full-radius(hl.at("radius", default: 0mm)) },
    sharp-break: hl.at("sharp-break", default: false),
    fill: hl.at("fill", default: none),
    code-style: hl.at("code-style", default: it => it),
  )
}

/// Sort two list of highlights by ending position.
#let merge-right-sort-highlights(hls1, hls2) = {
  let key(h) = (
    h.range.last().first(),
    if h.range.last().last() == auto { calc.inf } else {
      h.range.last().last()
    },
    h.range.first().first(),
    if h.range.first().last() == auto { -1 } else { h.range.first().last() },
  )

  return (hls1 + hls2).sorted(key: key)
}

// -----------------------------------------------------------------------------
// Parsing
// -----------------------------------------------------------------------------

/// Indicate wether a delimiter is inside a forbidden range.
#let in-forbid-list(del, forbidden) = {
  forbidden.any(r => (
    (r.first() <= del.start and del.end <= r.last())
      or (del.start <= r.first() and r.first() < del.end)
      or (del.start < r.last() and r.last() <= del.end)
      or (del.start <= r.first() and r.last() <= del.end)
  ))
}

/// Transform a position into a string into coordinates.
#let pos-to-coord(p, lines-len) = {
  let i = 0
  let s = 0
  while i < lines-len.len() and s <= p {
    s += lines-len.at(i)
    i += 1
  }
  i -= 1
  s -= lines-len.at(i)
  (i, p - s)
}

#let parse-delimiters(lines, phls) = {
  let bline = lines.join("\n", default: "")

  // Find left delimiters of highlights
  let ldels = phls
    .enumerate()
    .map(((idx, h)) => {
      bline.matches(h.ldel).map(m => (hl-idx: idx, start: m.start, end: m.end))
    })
  let ldels-sort = ldels.flatten().sorted(key: d => (d.start, -d.end))

  // Find right delimiters of highlits
  let rdels = phls
    .enumerate()
    .map(h => {
      bline.matches(h.last().rdel).map(m => (start: m.start, end: m.end))
    })
  let rdels-c = rdels.map(_ => 0)

  // Order left delimiters
  let dels-map = phls.map(_ => ())
  let dels-order = ()
  let il = 0
  let forbidden = ((-1, -1),)

  while il < ldels-sort.len() {
    let ldel = ldels-sort.at(il)

    // Check that we are not after already chosen left delimiters
    if not in-forbid-list(ldel, forbidden) {
      let i = ldel.hl-idx
      let ir = rdels-c.at(i)

      // Check that there remain corresponding right delimiters
      if ir < rdels.at(i).len() {
        let rdel = rdels.at(i).at(ir)

        // Check that the left delimiter is before the right one
        if ldel.end <= rdel.start and not in-forbid-list(rdel, forbidden) {
          dels-map.at(i).push((left: ldel, right: rdel))
          dels-order.push(i)
          forbidden.at(0).last() = ldel.end
          forbidden.push((rdel.start, rdel.end))

          il += 1
        }
        rdels-c.at(i) += 1
      } else { il += 1 }
    } else { il += 1 }
  }

  // Instanciate sorted left delimiters
  let ordered-dels = ()
  let dels-c = dels-map.map(_ => 0)
  for d in dels-order {
    ordered-dels.push(dels-map.at(d).at(dels-c.at(d)))
    dels-c.at(d) += 1
  }

  // Improve left delimiters with more information
  let dels-pos = ordered-dels
    .enumerate()
    .map(d => (
      (
        idx: d.first(),
        hl-idx: d.last().left.hl-idx,
        left: true,
        start: d.last().left.start,
        end: d.last().left.end,
      ),
      (
        idx: d.first(),
        left: false,
        start: d.last().right.start,
        end: d.last().right.end,
      ),
    ))
    .flatten()
    .sorted(key: d => d.start)

  // Reconstruct the text without delimiters
  let new-bline = ""
  let prev = 0
  for d in dels-pos {
    new-bline += bline.slice(prev, d.start)
    prev = d.end
  }
  new-bline += bline.slice(prev)

  // Reconstruct the lines without delimiters
  let new-lines = new-bline.split("\n")
  let new-lines-len = new-lines.map(l => l.len() + 1)

  // Compute the new positions of delimiters
  let removed = 0
  let pre-dels = ()
  for d in dels-pos {
    let pos = d.start - removed
    removed += d.end - d.start
    pre-dels.push(d + (pos: pos))
  }

  // Compute the final delimited text list
  let dels = range(int(pre-dels.len() / 2)).map(_ => (:))
  for d in pre-dels {
    let i = d.idx

    if "hl-idx" in d { dels.at(i).insert("idx", d.hl-idx) }

    let c = pos-to-coord(d.pos, new-lines-len)
    if d.left { dels.at(i).insert("start", c) } else {
      dels.at(i).insert("end", c)
    }
  }

  return (dels, new-lines)
}

/// Create a highlight from a pre-highlight and a delimitation from the raw text.
#let make-highlight(phl, del) = (
  ldel: phl.ldel,
  rdel: phl.rdel,
  range: (del.start, del.end),
  expand: phl.expand,
  lined: phl.lined,
  radius: phl.radius,
  sharp-break: phl.sharp-break,
  fill: phl.fill,
  code-style: phl.code-style,
)

/// Read the highlights in some raw text.
#let read-highlights(r, pre-highlights) = {
  let lines = r.lines.map(l => l.text)

  let (dels, lines) = parse-delimiters(lines, pre-highlights)
  let hls = dels.map(del => make-highlight(pre-highlights.at(del.idx), del))

  [
    #raw(lang: r.lang, lines.join("\n", default: "")) <uraw-code>
    #metadata(hls) <uraw-hl>
  ]
}

// -----------------------------------------------------------------------------
// Rendering
// -----------------------------------------------------------------------------

/// Determine wether a highlight span on a sub-line.
#let highlight-on-sub-line(i, line-end, sl, hl) = {
  if hl.is-line { return true }

  let valid-start = (
    hl.range.first().first() < i or hl.range.first().last() < sl.end
  )
  let valid-end = (
    hl.range.last().first() > i or hl.range.last().last() > sl.start
  )
  let is-empty = line-end == 0 and not hl.expand.right
  return valid-start and valid-end and not is-empty
}

/// Return the starting position of a sub-line.
#let sub-line-start-pos(i, pos-indent, k, sl, hl) = {
  if hl.is-line {
    if not hl.expand.left { pos-indent.last() } else { 0 }
  } else if hl.range.first().first() < i {
    if not hl.expand.left and k == 0 { pos-indent.last() } else { 0 }
  } else if hl.range.first().last() < sl.start {
    0
  } else {
    hl.range.first().last() - sl.start
  }
}

/// Return the ending position of a sub-line.
#let sub-line-end-pos(i, sl, hl, max-width, char-width) = {
  if hl.is-line {
    if not hl.expand.right { sl.end - sl.start } else { max-width / char-width }
  } else if hl.range.last().first() > i or hl.range.last().last() > sl.end {
    if hl.expand.right { max-width / char-width } else { sl.end - sl.start }
  } else {
    hl.range.last().last() - sl.start
  }
}

/// Check if a highlight is spanning at the start of the sub-line.
#let is-spaning-start(i, m, hl) = {
  hl.range.first().first() < i or 0 < m
}

/// Check if a highlight is spanning at the end of the sub-line.
#let is-spaning-end(i, m, sl-len, hl) = {
  i < hl.range.last().first() or m < sl-len - 1
}

/// The blocks of a highlight on a line, as `(k, start, end)` for each sub-line `k`.
#let line-spans(i, l, hl, width, inset, char-width) = {
  l
    .slines
    .enumerate()
    .filter(sl => highlight-on-sub-line(i, l.line-end, sl.last(), hl))
    .map(((k, sl)) => (
      k: k,
      sl: sl,
      start: sub-line-start-pos(i, l.pos-indent, k, sl, hl),
      end: sub-line-end-pos(
        i,
        sl,
        hl,
        width + inset.right.to-absolute(),
        char-width,
      ),
    ))
}

/// The key of the block of a highlight on the sub-line `k` of the line `i`.
#let block-key(i, k) = str(i) + "-" + str(k)

/// For each block of a lined highlight, the horizontal ranges of the blocks of the same highlight touching it from above and below.
///
/// - hl (dictionary): The highlight.
/// - lines (array): The formatted code lines.
/// - width (length): The code width.
/// - inset (dictionary): The code inset.
/// - char-width (length):
/// -> dictionary
#let compute-touches(hl, lines, width, inset, char-width) = {
  if not hl.lined { return (:) }

  let blocks = ()
  for i in range(hl.range.first().first(), hl.range.last().first() + 1) {
    let l = lines.at(i)
    for b in line-spans(i, l, hl, width, inset, char-width) {
      blocks.push((
        i: i,
        k: b.k,
        last: b.k == l.slines.len() - 1,
        start: b.start,
        end: b.end,
      ))
    }
  }

  let touches = (:)
  for b in blocks {
    touches.insert(block-key(b.i, b.k), (top: none, bottom: none))
  }

  for n in range(blocks.len() - 1) {
    let (b1, b2) = (blocks.at(n), blocks.at(n + 1))
    let adjacent = (
      (b1.i == b2.i and b2.k == b1.k + 1)
        or (
          b2.i == b1.i + 1 and b1.last and b2.k == 0
        )
    )

    if adjacent and b1.start < b2.end and b2.start < b1.end {
      touches.at(block-key(b1.i, b1.k)).bottom = (b2.start, b2.end)
      touches.at(block-key(b2.i, b2.k)).top = (b1.start, b1.end)
    }
  }

  touches
}

/// The touches of a block not touching any other block.
#let no-touches = (top: none, bottom: none)

/// The space added above the code of a highlight block, lined highlights occupy the whole height of the line.
#let block-top-pad(hl, inset) = if hl.lined { inset.top } else { .24em }

/// The space added below the code of a highlight block, lined highlights occupy the whole height of the line.
#let block-bottom-pad(hl, inset) = if hl.lined { inset.bottom + .2pt } else {
  .25em
}

/// Compute the radius of the highlight block.
#let compute-radius(radius, sharp-start, sharp-end) = (
  radius
    + if sharp-start { (top-left: 0mm, bottom-left: 0mm) } else { (:) }
    + if sharp-end { (top-right: 0mm, bottom-right: 0mm) } else { (:) }
)

/// Construct the highlight block.
#let highlight-block(
  hl,
  spaning-start,
  spaning-end,
  start,
  end,
  inset,
  char-width,
  char-height,
  touches,
) = {
  let (touch-top, touch-bottom) = (touches.top, touches.bottom)

  // The open ends are closed when the highlight sticks to the next part on this side
  let sharp-start = hl.sharp-break and spaning-start
  let sharp-end = hl.sharp-break and spaning-end
  let radius = compute-radius(hl.radius, sharp-start, sharp-end)

  // Remove the radius of the corners touching other blocks of the highlight
  if touch-top != none {
    let (s, e) = touch-top
    if s <= start and start < e { radius.top-left = 0mm }
    if s < end and end <= e { radius.top-right = 0mm }
  }
  if touch-bottom != none {
    let (s, e) = touch-bottom
    if s <= start and start < e { radius.bottom-left = 0mm }
    if s < end and end <= e { radius.bottom-right = 0mm }
  }

  block(
    radius: radius,
    fill: hl.fill,
    outset: (
      left: if (spaning-start or hl.is-line) and hl.expand.left {
        inset.left
      } else { 0mm },
    ),
    width: (end - start) * char-width,
    height: (
      block-top-pad(hl, inset) + char-height + block-bottom-pad(hl, inset)
    ),
  )
}

/// Construct highlights block for the sub-lines of a line.
#let compute-highlights(
  i,
  l,
  width,
  inset,
  char-width,
  char-height,
  highlights,
) = {
  let highlight-blocks = ()
  for hl in highlights {
    // Select sub-lines affected by this highlight
    let slines = l
      .slines
      .enumerate()
      .filter(sl => highlight-on-sub-line(i, l.line-end, sl.last(), hl))

    // Create a highlight block per sub-line
    for (m, (k, sl)) in slines.enumerate() {
      // Look if the highlight is spaning on this sub-line
      let spaning-start = is-spaning-start(i, m, hl)
      let spaning-end = is-spaning-end(i, m, slines.len(), hl)

      // Get the start and end position of the highlight on this sub-line
      let start = sub-line-start-pos(i, l.pos-indent, k, sl, hl)
      let end = sub-line-end-pos(
        i,
        sl,
        hl,
        width + inset.right.to-absolute(),
        char-width,
      )

      // Style the highlighted part of the sub-line
      let (pre-hl, rest) = ct.content-split-pos(sl.body, start)
      let (in-hl, post-hl) = if type(end) != int {
        (rest, [])
      } else {
        ct.content-split-pos(rest, end - start)
      }
      l.slines.at(k).body = (
        pre-hl + ct.content-map-text(in-hl, hl.code-style) + post-hl
      )

      let touches = hl
        .at("touches", default: (:))
        .at(block-key(i, k), default: no-touches)

      let hl-block = move(
        dy: .24em - block-top-pad(hl, inset),
        highlight-block(
          hl,
          spaning-start,
          spaning-end,
          start,
          end,
          inset,
          char-width,
          char-height,
          touches,
        ),
      )

      highlight-blocks.push((k, start, hl-block))
    }
  }

  return (l.slines, highlight-blocks)
}
