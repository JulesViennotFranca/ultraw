#import "common.typ" as cm
#import "content.typ" as ct
#import "highlight.typ" as hl
#import "../src/lang-tag.typ" as lt
#import "measure.typ" as me
#import "rendering.typ" as re
#import "config.typ" as st
#import "../themes/uraw.typ": default
#import "utils.typ" as ut

// -----------------------------------------------------------------------------
// Settings
// -----------------------------------------------------------------------------

/// The settings names of diffs: the ones of `uraw` (without `coloring-follow-number`) and the ones specific to diffs.
#let diff-spec = (sections: (:), flat-names: (:), additional: ())

// sp.settings-spec(
//   default + default.diff,
//   (
//     "frame",
//     "header",
//     "footer",
//     "number",
//     "code",
//     "comment",
//     "jump",
//     "lang-tag",
//   )
//     + sp.diff-sections,
//   (
//     width: ("frame", "width"),
//     height: ("frame", "height"),
//     breakable: ("frame", "breakable"),
//     start: ("number", "start"),
//     end: ("number", "end"),
//     line-spacing: ("code", "line-spacing"),
//     indentation: ("code", "indentation"),
//   ),
// )

/// Get the settings specific to diffs (the other settings are the ones of `uraw`).
/// -> dictionary
#let uraw-diff-get() = context st.uraw-config-state.get().diff

/// Get the markers settings of diffs.
/// -> dictionary
#let uraw-diff-get-markers() = context st.uraw-config-state.get().diff.markers

/// Get the settings of the old code of diffs.
/// -> dictionary
#let uraw-diff-get-old() = context st.uraw-config-state.get().diff.old

/// Get the settings of the new code of diffs.
/// -> dictionary
#let uraw-diff-get-new() = context st.uraw-config-state.get().diff.new

/// Get the general settings of diffs (`line-reference`, `columns`, `no-diff-marker`, `blank-fill`, `sep`).
/// -> dictionary
#let uraw-diff-get-general() = context {
  let conf = st.uraw-config-state.get().diff
  st.diff-general.map(key => (key, conf.at(key))).to-dict()
}

/// Set the settings specific to diffs, by section or flat (`section-key`, and `markers: bool`): \ **markers**: **visible** (bool): wether the markers are shown, **inset** (auto | relative | dictionary): the inset of the markers (only left and right), `auto` for the inset of the number, **sep**: the separator between the markers and the code \ **old** and **new**: **marker** (content): the marker of the changed lines, **number-color** and **number-fill**: the color and background of the numbers of the changed lines (`auto` for the ones of the number), **fill**: the background of the changes \ the general settings **line-reference** (none | auto | function): how a reference to a line is displayed after "Listing n", a function of the number and of the version (`"old"` or `"new"`), **columns** (int | array): the widths of the code columns, as for a grid (`auto`, relative or fraction): one column merges the old and the new codes, two columns separate them (`(auto, auto)` by default, which become `(1fr, 1fr)` when the codes are too large), **column-gutter** (relative): the space between the old and the new codes when they are separated (each half continuing the coloring of the code next to it, the separator being at its center), **no-diff-marker** (content): the marker of the unchanged lines, **blank-fill**: the background of the space left by a line which only is in one version, **sep**: the separator between the old and the new code. \ The other settings of diffs are the ones of `uraw` (see `uraw-set`).
/// -> content
#let uraw-diff-set(..args) = st.update-diff(args.named())

/// Set the markers settings of diffs.
/// -> content
#let uraw-diff-set-markers(..args) = uraw-diff-set(markers: args.named())

/// Set the settings of the old code of diffs.
/// -> content
#let uraw-diff-set-old(..args) = uraw-diff-set(old: args.named())

/// Set the settings of the new code of diffs.
/// -> content
#let uraw-diff-set-new(..args) = uraw-diff-set(new: args.named())

/// Reset the settings specific to diffs to their initial value.
/// -> content
#let uraw-diff-reset() = st.uraw-config-state.update(conf => {
  conf.diff = st.initial-config.diff
  conf
})

// -----------------------------------------------------------------------------
// Diff computation
// -----------------------------------------------------------------------------

/// The longest common subsequence of two arrays, as operations: `("=", i, j)` for common elements, `("-", i, none)` for removed ones and `("+", none, j)` for added ones.
///
/// - a (array):
/// - b (array):
/// -> array
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

/// Split a line in tokens: words, spaces and symbols.
#let tokenize(s) = {
  s
    .matches(regex("\\w[\\w']*|\\s+|[^\\w\\s]+"))
    .map(m => (text: m.text, start: m.start, end: m.end))
}

/// The changed parts of a line, from its tokens and wether they are changed, the spaces between changed tokens being changed too.
///
/// -> array: the ranges `(start, end)` of the changed parts
#let changed-ranges(tokens, changed) = {
  let is-space(k) = tokens.at(k).text.trim() == ""
  let n = tokens.len()

  // The spaces between two changed tokens are changed
  let changed = changed
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
      // Do not highlight the spaces at the ends
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

/// The in-line difference between two lines, `none` if they are too different.
///
/// -> dictionary, none: the changed ranges of the `old` and the `new` line
#let line-diff(old-text, new-text) = {
  let (a, b) = (tokenize(old-text), tokenize(new-text))
  let ops = lcs-ops(a.map(t => t.text), b.map(t => t.text))

  // The similarity of the lines, on the characters which are not spaces
  let size(t) = t.text.replace(regex("\s"), "").len()
  let common = ops
    .filter(op => op.at(0) == "=")
    .map(op => size(a.at(op.at(1))))
    .sum(default: 0)
  let total = a.map(size).sum(default: 0) + b.map(size).sum(default: 0)
  if total == 0 or 2 * common / total < .5 { return none }

  let old-changed = a.map(_ => true)
  let new-changed = b.map(_ => true)
  for op in ops {
    if op.at(0) == "=" {
      old-changed.at(op.at(1)) = false
      new-changed.at(op.at(2)) = false
    }
  }

  (old: changed-ranges(a, old-changed), new: changed-ranges(b, new-changed))
}

/// Compute the difference between two codes.
///
/// - old-texts (array): The lines of the old code.
/// - new-texts (array): The lines of the new code.
/// -> dictionary: the `items` (`(kind: "same", old: i, new: j)` or `(kind: "hunk", dels: .., adds: ..)`), and for each version the `status` of its lines (`"same"`, `"mod"` or `"whole"`) and the changed `ranges` of the modified lines
#let compute-diff(old-texts, new-texts) = {
  let ops = lcs-ops(old-texts, new-texts)

  let items = ()
  let (dels, adds) = ((), ())
  for op in ops {
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

  let old-status = old-texts.map(_ => "same")
  let new-status = new-texts.map(_ => "same")
  let old-ranges = old-texts.map(_ => ())
  let new-ranges = new-texts.map(_ => ())

  for item in items.filter(it => it.kind == "hunk") {
    for i in item.dels { old-status.at(i) = "whole" }
    for j in item.adds { new-status.at(j) = "whole" }

    // The lines replacing each other are compared
    for k in range(calc.min(item.dels.len(), item.adds.len())) {
      let (i, j) = (item.dels.at(k), item.adds.at(k))
      let d = line-diff(old-texts.at(i), new-texts.at(j))
      if d != none {
        old-status.at(i) = "mod"
        new-status.at(j) = "mod"
        old-ranges.at(i) = d.old
        new-ranges.at(j) = d.new
      }
    }
  }

  (
    items: items,
    old: (status: old-status, ranges: old-ranges),
    new: (status: new-status, ranges: new-ranges),
  )
}

// -----------------------------------------------------------------------------
// Lines
// -----------------------------------------------------------------------------

/// The formatted lines of a raw element.
/// - indent-size (auto, int): The number of spaces of an indentation level, `auto` for the tab size of the raw element.
#let raw-lines(it, indent-size) = {
  let indent-size = if indent-size == auto { it.tab-size } else { indent-size }
  let lines = it.lines.map(l => if ct.is-whitespace-line(l.text) {
    (line: [], text: "", pos-indent: (0,), line-end: 0)
  } else {
    let num-indent = ct.get-line-indent(l, indent-size)
    let pos-indent = range(num-indent + 1).map(i => i * indent-size)
    (line: l.body, text: l.text, pos-indent: pos-indent, line-end: l.text.len())
  })

  // Empty lines have the indentation of the next line
  let i = lines.len() - 2
  while 0 <= i {
    if lines.at(i).text.len() == 0 {
      lines.at(i).pos-indent = lines.at(i + 1).pos-indent
    }
    i -= 1
  }
  lines
}

/// Resolve the user highlights of a version: their line numbers become indexes, and the automatic columns are computed.
#let resolve-highlights(manual, delimited, lines, line-numbers) = {
  let manual = manual.map(h => {
    h.range.first().first() = cm.line-index(
      line-numbers,
      h.range.first().first(),
    )
    h.range.last().first() = cm.line-index(line-numbers, h.range.last().first())
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
      h
    })
  let _ = highlights.map(hl.check-highlight)
  highlights.rev()
}

// -----------------------------------------------------------------------------
// Rendering
// -----------------------------------------------------------------------------

/// Normalize the `columns` setting: an array of one (merged codes) or two (separated codes) widths.
#let normalize-columns(columns) = {
  let columns = if type(columns) == int {
    assert(
      columns in (1, 2),
      message: "The `columns` of a diff must be 1 or 2, or an array of one or two widths.",
    )
    range(columns).map(_ => auto)
  } else if type(columns) == array {
    columns
  } else {
    (columns,)
  }
  assert(
    columns.len() in (1, 2)
      and columns.all(c => (
        c == auto or type(c) in (length, ratio, relative, fraction)
      )),
    message: "The `columns` of a diff must be 1 or 2, or an array of one or two widths (auto, relative or fraction).",
  )
  columns
}

/// Resolve the widths of the code columns.
///
/// - columns (array): The widths as given by the user.
/// - natural (array): The natural widths of the codes.
/// - available (length): The width available for the codes.
/// - fill (bool): Wether the codes must fill the available width.
/// -> array
#let resolve-columns(columns, natural, available, fill) = {
  // Too large automatic codes share the available width
  if (
    columns.all(c => c == auto)
      and natural.sum() > available
      and columns.len() == 2
  ) {
    columns = (1fr, 1fr)
  }

  let resolve(c) = if type(c) == ratio { available * c } else if (
    type(c) == relative
  ) {
    available * c.ratio + c.length.to-absolute()
  } else { c.to-absolute() }

  let widths = columns.map(c => if c == auto or type(c) == fraction {
    none
  } else { resolve(c) })
  let fixed = widths.filter(w => w != none).sum(default: 0pt)

  // The automatic codes take their natural width
  let autos = columns
    .enumerate()
    .filter(((k, c)) => c == auto)
    .map(((k, c)) => k)
  for k in autos {
    widths.at(k) = calc.min(
      natural.at(k),
      calc.max(0pt, available - fixed),
    )
    fixed += widths.at(k)
  }

  // The fractions share the rest
  let fractions = columns.filter(c => type(c) == fraction)
  let total-fr = fractions.map(c => c / 1fr).sum(default: 0)
  let rest = calc.max(0pt, available - fixed)
  for (k, c) in columns.enumerate() {
    if type(c) == fraction { widths.at(k) = rest * (c / 1fr) / total-fr }
  }

  // The automatic codes share the rest of a fixed width
  if fill and fractions.len() == 0 and autos.len() > 0 {
    let rest = calc.max(0pt, available - widths.sum())
    for k in autos { widths.at(k) += rest / autos.len() }
  }

  widths
}

#let render-diff(
  settings,
  old-it,
  new-it,
  user-highlights,
  user-comments,
  user-jumps,
  base-text,
) = layout(layout-size => {
  // Parsing

  let lang = if new-it.lang != none { new-it.lang } else { old-it.lang }
  let frame = st.parse-frame(lang: lang, ..settings)
  let header = st.parse-header(lang: lang, ..settings)
  let footer = st.parse-footer(lang: lang, ..settings)
  let number = st.parse-number(lang: lang, ..settings)
  let code = st.parse-code(lang: lang, ..settings)
  let lang-tag = st.parse-lang-tag(lang: lang, ..settings)
  let stroke-thickness = st.parse-general(
    lang: lang,
    "default-stroke-thickness",
    ..settings,
  )
  lang-tag.stroke = ut.with-default-thickness(lang-tag.stroke, stroke-thickness)
  let comment = st.parse-comment(lang: lang, ..settings)
  let jump = st.parse-jump(lang: lang, ..settings)

  let conf = st.uraw-config-state.get().diff
  let section(name) = ut.filter-add-dict(
    conf.at(name),
    settings.at(name, default: (:)),
  )
  let general(key) = settings.at(key, default: conf.at(key))
  let markers = section("markers")
  markers.sep = ut.with-default-thickness(markers.sep, stroke-thickness)
  let versions = (old: section("old"), new: section("new"))
  let columns-setting = normalize-columns(general("columns"))
  let same-code = columns-setting.len() == 1
  let line-reference = general("line-reference")

  assert(
    number.end == none,
    message: "The `end` of the number is not supported by diffs.",
  )
  assert(
    type(number.start) == int,
    message: "The `start` of the number of a diff must be an integer.",
  )

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

  // Lines and diff

  let lines = (
    old: raw-lines(old-it, code.indent-size),
    new: raw-lines(new-it, code.indent-size),
  )
  let diff = compute-diff(
    old-it.lines.map(l => l.text),
    new-it.lines.map(l => l.text),
  )

  // For each new line, the old line at the same place (-1 if there is none)
  let new-to-old = lines.new.map(_ => -1)
  let last-old = -1
  for item in diff.items {
    if item.kind == "same" {
      new-to-old.at(item.new) = item.old
      last-old = item.old
    } else {
      for (k, j) in item.adds.enumerate() {
        new-to-old.at(j) = item.dels.at(k, default: if item.dels.len() > 0 {
          item.dels.last()
        } else { last-old })
      }
      if item.dels.len() > 0 { last-old = item.dels.last() }
    }
  }

  // Numbers: the jumps of both versions are given on the new numbers, and jump the same number of lines in the old code

  let jumps-of(version) = user-jumps.filter(j => j.version == version)
  let format(version-jumps, version) = cm.format-jumps(
    version-jumps,
    number,
    lines.at(version).len(),
  )

  let both-jumps = jumps-of("both")
  let (_, new-jumps, new-numbers) = format(
    jumps-of("new") + both-jumps,
    "new",
  )

  let old-jumps = jumps-of("old")
  for j in both-jumps.sorted(key: j => j.from) {
    let oi = new-to-old.at(cm.line-index(new-numbers, j.from))
    if oi >= 0 {
      let old-numbers = format(old-jumps, "old").at(2)
      let from = old-numbers.at(oi)
      // Its comment is the one of the jump of the new code
      old-jumps.push((from: from, to: from + j.to - j.from, version: "both"))
    }
  }
  let (_, old-jumps, old-numbers) = format(old-jumps, "old")

  let numbers = (
    old: (jumps: old-jumps, line-numbers: old-numbers),
    new: (jumps: new-jumps, line-numbers: new-numbers),
  )

  // Insets & radius & stroke

  (frame, header, footer, number, code) = cm.format-insets(
    frame,
    header,
    footer,
    number,
    code,
    stroke-thickness: stroke-thickness,
  )

  // An automatic markers inset is the number one
  if markers.inset == auto { markers.inset = number.inset }
  markers.inset = ut.line-inset(markers.inset, code.line-spacing)

  // The separator column between the old and the new codes
  let sep = ut.with-default-thickness(general("sep"), stroke-thickness)

  // The gutter between the old and the new codes, with the separator at its center
  let frame-width = (
    if frame.width == auto {
      layout-size.width
    } else if type(frame.width) == ratio {
      layout-size.width * frame.width
    } else {
      frame.width
    }
  ).to-absolute()
  let sep-thickness = if sep != none {
    let t = stroke(sep).thickness
    (if t == auto { 1pt } else { t }).to-absolute()
  } else { 0pt }
  let gutter = general("column-gutter")
  gutter = if type(gutter) == ratio { frame-width * gutter } else if (
    type(gutter) == relative
  ) {
    frame-width * gutter.ratio + gutter.length.to-absolute()
  } else { gutter.to-absolute() }
  let sep-width = if same-code { 0pt } else {
    calc.max(gutter, sep-thickness)
  }

  // Update of the insets of code when there are two columns
  code.inset = (old: code.inset, new: code.inset)
  if not same-code {
    code.inset.old.right += sep-width / 2
  }

  // Colors (they follow the position of the rows)

  (number, code) = cm.format-colors(
    number,
    code,
    frame,
    numbers.new.line-numbers,
    calc.max(lines.old.len(), lines.new.len()),
    false,
    none,
  )

  // Lang tag

  lang-tag.visible = lang != none and lang-tag.format != none
  lang-tag.format = if lang-tag.format == auto { it => it } else {
    lang-tag.format
  }

  if lang-tag.visible {
    lt.check-lang-tag-mode(lang-tag.mode)
    lt.check-lang-tag-placement(lang-tag.placement)
  }

  // Without header, a lang tag placed in the header is placed in the code
  if lang-tag.placement == "header" and header.content == none {
    lang-tag.placement = "code"
  }

  if lang-tag.visible {
    if lang-tag.placement in ("top-left", "left-top") {
      frame.radius.top-left = 0mm
    }
    if lang-tag.placement in ("bottom-left", "left-bottom") {
      frame.radius.bottom-left = 0mm
    }
    if lang-tag.placement in ("top-right", "right-top") {
      frame.radius.top-right = 0mm
    }
    if lang-tag.placement in ("bottom-right", "right-bottom") {
      frame.radius.bottom-right = 0mm
    }
  }
  lang-tag.insert(
    "in-code",
    lang-tag.placement == "code" or lang-tag.placement == "inline",
  )
  lang-tag.insert(
    "on-frame",
    lang-tag.placement not in ("code", "inline", "header"),
  )

  let lang-tag-block = if lang-tag.visible {
    lt.lang-tag-block(lang, lang-tag, frame)
  } else { none }

  // The lang tag placed in the header
  header.insert(
    "tag",
    if lang-tag.visible and lang-tag.placement == "header" { lang-tag-block },
  )
  let (is-top, is-left, is-right, is-bottom) = if (
    lang-tag.visible and lang-tag.on-frame
  ) {
    lt.lang-tag-position(lang-tag)
  } else {
    (none, none, none, none)
  }
  lang-tag.insert(
    "width",
    if lang-tag.visible and lang-tag.in-code {
      measure(lang-tag-block).width + lang-tag.code-spacing.to-absolute()
    } else { 0mm },
  )

  // Header & footer formatting

  (header, footer) = cm.format-header-footer(
    header,
    footer,
    frame,
    code,
    calc.max(lines.old.len(), lines.new.len()),
  )
  if header.content != none {
    header.content = text(..base-text(), header.content)
  }
  if footer.content != none {
    footer.content = text(..base-text(), footer.content)
  }

  // Comments

  let comments = (:)
  for version in ("old", "new") {
    let format(c, gap, key) = {
      let c = cm.format-comment(
        c,
        gap,
        key,
        frame.fill,
        true,
        base-text,
      )
      c.insert("version", version)
      c
    }
    let line-numbers = numbers.at(version).line-numbers
    let version-jumps = numbers
      .at(version)
      .jumps
      .filter(j => j.at("version", default: version) == version)
    let all = (
      cm.jump-comments(version-jumps, jump, comment, line-numbers, format)
        + cm.parse-comments(
          user-comments.filter(c => c.version == version),
          comment,
          line-numbers,
          format,
        )
    )
    if version == "new" {
      // The comments of the jumps of both versions, which are not indented
      let both = cm
        .jump-comments(both-jumps, jump, comment, line-numbers, format)
        .map(c => c + (version: "both", indented: false))
      all = both + all
    }

    let by-gap = range(lines.at(version).len() + 1).map(_ => ())
    for c in all { by-gap.at(c.gap).push(c) }
    comments.insert(version, by-gap)
  }

  // Widths before the codes

  let char-width = measure("#").width
  let char-height = measure("#").height

  let numbers-width = (:)
  for version in ("old", "new") {
    numbers-width.insert(version, if number.visible {
      let numbers-width = me.numbers-width(
        numbers.at(version).line-numbers,
        format: n => cm.format-number(number.format, n),
        monotonic: type(number.format) != function,
      )
      let comments-markers-width = calc.max(
        0pt,
        ..comments
          .at(version)
          .flatten()
          .filter(c => c.marker != none)
          .map(c => measure(c.marker).width),
      )
      (
        number.inset.left
          + calc.max(numbers-width, comments-markers-width)
          + number.inset.right
      ).to-absolute()
    } else { 0pt })
  }

  let markers-width = (:)
  for version in ("old", "new") {
    let version-width = if same-code {
      calc.max(
        measure(versions.old.marker).width,
        measure(versions.new.marker).width,
      )
    } else { measure(versions.at(version).marker).width }
    markers-width.insert(version, if markers.visible {
      (
        markers.inset.left
          + calc.max(
            version-width,
            measure(general("no-diff-marker")).width,
          )
          + markers.inset.right
      ).to-absolute()
    } else { 0pt })
  }

  // The width before the code (of a version for separated codes)
  let pre-width(version) = if same-code {
    numbers-width.old + numbers-width.new + markers-width.new
  } else {
    numbers-width.at(version) + markers-width.at(version)
  }

  // The width available for the codes
  let code-insets = (
    old: (code.inset.old.left + code.inset.old.right).to-absolute(),
    new: (code.inset.new.left + code.inset.new.right).to-absolute(),
  )
  let available = if same-code {
    frame-width - pre-width("new") - code-insets.new
  } else {
    (
      frame-width
        - pre-width("old")
        - pre-width("new")
        - code-insets.old
        - code-insets.new
        - sep-width / 2
    )
  }

  // Indentation of comments.
  for version in ("old", "new") {
    comments.at(version) = comments
      .at(version)
      .map(cs => cs.map(c => {
        if c.indented and c.copy-before {
          c.insert("pos-indent", if c.gap > 0 {
            lines.at(version).at(c.gap - 1).pos-indent
          } else { () })
        } else if c.indented and not c.copy-before {
          c.insert("pos-indent", if c.gap < lines.at(version).len() {
            lines.at(version).at(c.gap).pos-indent
          } else { () })
        }
        c
      }))
  }

  /// The horizontal start of the text of a comment, relative to the start of its side.
  let comment-start(c) = {
    let version = if c.version == "both" { "old" } else { c.version }
    if c.in-code or c.indented {
      let indent = if c.indented and c.gap > 0 {
        c.pos-indent.last() * char-width
      } else { 0pt }
      pre-width(version) + code.inset.at(version).left.to-absolute() + indent
    } else if number.visible {
      number.inset.left.to-absolute()
    } else {
      markers.inset.left.to-absolute()
    }
  }

  /// The horizontal end of the text of a comment, relative to the end of its side.
  let comment-end(c) = {
    let version = if c.version == "both" { "new" } else { c.version }
    let addition = if not same-code and version == "old" { gutter / 2 } else {
      0pt
    }
    return code.inset.at(version).right + addition
  }

  // Natural widths of the codes

  let natural(version) = {
    let tag = version == "new" or same-code
    let widths = lines
      .at(version)
      .enumerate()
      .map(((i, l)) => (
        measure(l.line).width
          + if tag and lang-tag.visible and lang-tag.placement == "code" {
            lang-tag.width
          } else if (
            version == "new" and lang-tag.placement == "inline" and i == 0
          ) { lang-tag.width } else { 0pt }
      ))
    // The comments of the version must fit in it
    for c in comments.at(version).flatten().filter(c => c.version != "both") {
      widths.push(
        comment-start(c)
          + measure(c.body).width
          - pre-width(version)
          - code.inset.at(version).left.to-absolute(),
      )
    }
    calc.max(0pt, ..widths)
  }

  let code-width = if same-code {
    let w = resolve-columns(
      columns-setting,
      (calc.max(natural("old"), natural("new")),),
      available,
      frame.width != auto,
    ).first()
    (old: w, new: w)
  } else {
    let (o, n) = resolve-columns(
      columns-setting,
      (natural("old"), natural("new")),
      available,
      frame.width != auto,
    )
    (old: o, new: n)
  }

  let side-width(version) = (
    pre-width(version) + code-insets.at(version) + code-width.at(version)
  )
  let total-width = if same-code { side-width("new") } else {
    side-width("old") + sep-width / 2 + side-width("new")
  }

  // The header and the footer can enlarge the codes
  let hf-width = calc.max(
    if header.content != none {
      (
        measure(block(inset: header.inset, header.content)).width
          + if header.tag != none {
            measure(header.tag).width + lang-tag.code-spacing.to-absolute()
          } else { 0pt }
      )
    } else { 0pt },
    if footer.content != none {
      measure(block(inset: footer.inset, footer.content)).width
    } else { 0pt },
  )
  if hf-width > total-width {
    code-width.new += hf-width - total-width
    if same-code { code-width.old = code-width.new }
    total-width = hf-width
  }

  // Break lines in sub-lines (the lang tag is on the first new line)

  for version in ("old", "new") {
    let tag = version == "new" or same-code
    lines.at(version) = lines
      .at(version)
      .enumerate()
      .map(((i, l)) => {
        let slines = ct.format-line(
          l.line,
          code-width.at(version)
            - if tag and lang-tag.visible and lang-tag.placement == "code" {
              lang-tag.width
            } else { 0pt },
          char-width,
          l.line-end,
          if (
            version == "new" and lang-tag.placement == "inline" and i == 0
          ) { lang-tag.width },
        )
        l + (slines: slines)
      })
  }

  // Highlights: the changes of the modified lines, then the ones of the user

  let highlights = (:)
  for version in ("old", "new") {
    let version-lines = lines.at(version)
    let changes = ()
    for (i, ranges) in diff.at(version).ranges.enumerate() {
      for (s, e) in ranges {
        changes.push(hl.format-highlight((
          start: (i, s),
          end: (i, e),
          expand: none,
          lined: false,
          radius: 0mm,
          fill: versions.at(version).fill,
          code-style: it => it,
        )))
      }
    }
    let user = resolve-highlights(
      user-highlights.at(version).manual,
      user-highlights.at(version).delimited,
      version-lines,
      numbers.at(version).line-numbers,
    )

    let by-line = version-lines.map(_ => ())
    for h in changes + user {
      let h = (
        h
          + (
            touches: hl.compute-touches(
              h,
              version-lines,
              code-width.at(version),
              code.inset.at(version),
              char-width,
            ),
          )
      )
      for i in range(h.range.first().first(), h.range.last().first() + 1) {
        by-line.at(i).push(h)
      }
    }
    highlights.insert(version, by-line)
  }

  // Comments sizes: they span over the whole width, the text of a comment of the old code staying in the old code

  for version in ("old", "new") {
    comments.at(version) = comments
      .at(version)
      .map(cs => cs.map(c => {
        c.insert("inset", (
          left: comment-start(c),
          right: comment-end(c),
          top: code.inset.at(version).top,
          bottom: code.inset.at(version).bottom,
        ))
        c.insert("width", if c.version == "both" { total-width } else {
          side-width(c.version)
        })
        c.insert(
          "height",
          measure(block(width: total-width, inset: c.inset, c.body)).height,
        )
        c
      }))
  }

  // Rows

  let line-rows = ()
  for item in diff.items {
    if item.kind == "same" {
      line-rows.push((old: item.old, new: item.new))
    } else if same-code {
      line-rows += item.dels.map(i => (old: i, new: none))
      line-rows += item.adds.map(j => (old: none, new: j))
    } else {
      for k in range(calc.max(item.dels.len(), item.adds.len())) {
        line-rows.push((
          old: item.dels.at(k, default: none),
          new: item.adds.at(k, default: none),
        ))
      }
    }
  }

  let comment-rows(olds, news) = if same-code {
    let olds-after = olds.filter(c => c.copy-before)
    let olds-before = olds.filter(c => not c.copy-before)
    let news-after = news.filter(c => c.copy-before)
    let news-before = news.filter(c => not c.copy-before)

    (olds-after + news-after + olds-before + news-before).map(c => (comment: c))
  } else {
    let olds-after = olds.filter(c => c.copy-before)
    let olds-before = olds.filter(c => not c.copy-before)
    let news-after = news.filter(c => c.copy-before)
    let news-before = news.filter(c => not c.copy-before)

    let after-after = olds-after.zip(news-after).map(p => (comments: p))
    let olds-after = olds-after.slice(after-after.len())
    let news-after = news-after.slice(after-after.len())

    let before-before = olds-before
      .rev()
      .zip(news-before.rev())
      .map(p => (comments: p))
      .rev()
    let olds-before = olds-before.rev().slice(before-before.len()).rev()
    let news-before = news-before.rev().slice(before-before.len()).rev()

    if olds-after.len() == 0 and olds-before.len() == 0 {
      after-after += news-after.map(c => (comment: c))
      after-after += news-before.map(c => (comment: c))
    } else if news-after.len() == 0 and news-before.len() == 0 {
      after-after += olds-after.map(c => (comment: c))
      after-after += olds-before.map(c => (comment: c))
    } else if olds-after.len() == 0 and news-before.len() == 0 {
      if news-after.len() < olds-before.len() {
        let ab = news-after.zip(olds-before).map(p => (comments: p))
        after-after += ab
        after-after += olds-before.slice(ab.len()).map(c => (comment: c))
      } else {
        let ab = news-after
          .rev()
          .zip(olds-before.rev())
          .map(p => (comments: p))
          .rev()
        after-after += news-after
          .rev()
          .slice(ab.len())
          .map(c => (comment: c))
          .rev()
        after-after += ab
      }
    } else {
      if olds-after.len() < news-before.len() {
        let ab = olds-after.zip(news-before).map(p => (comments: p))
        after-after += ab
        after-after += news-before.slice(ab.len()).map(c => (comment: c))
      } else {
        let ab = olds-after
          .rev()
          .zip(news-before.rev())
          .map(p => (comments: p))
          .rev()
        after-after += olds-after
          .rev()
          .slice(ab.len())
          .map(c => (comment: c))
          .rev()
        after-after += ab
      }
    }

    return after-after + before-before
  }
  let rows = comment-rows(comments.old.at(0), comments.new.at(0))
  for row in line-rows {
    rows.push(row)
    rows += comment-rows(
      if row.old != none { comments.old.at(row.old + 1) } else { () },
      if row.new != none { comments.new.at(row.new + 1) } else { () },
    )
  }

  // The space before the first row and after the last one
  let edge(r) = (
    top: if r == 0 { code.edge.top } else { 0pt },
    bottom: if r == rows.len() - 1 { code.edge.bottom } else { 0pt },
  )

  // Heights

  let line-height(version, i) = (
    lines.at(version).at(i).slines.len() * (char-height + code.line-spacing)
  ).to-absolute()
  let row-height(row) = if "comments" in row {
    calc.max(row.comments.first().height, row.comments.last().height)
  } else if "comment" in row {
    row.comment.height
  } else if same-code {
    if row.new != none { line-height("new", row.new) } else {
      line-height("old", row.old)
    }
  } else {
    calc.max(
      if row.old != none { line-height("old", row.old) } else { 0pt },
      if row.new != none { line-height("new", row.new) } else { 0pt },
    )
  }

  // Cells

  /// The number cell of a line of a version, or an empty number cell.
  let number-cell(version, i, r, height, sep: number.sep) = {
    let changed = i != none and diff.at(version).status.at(i) != "same"
    let conf = versions.at(version)
    let content = if i != none {
      let n = numbers.at(version).line-numbers.at(i)
      let color = if changed and conf.number-color != auto {
        conf.number-color
      } else if number.color == auto {
        none
      } else if type(number.color) == function {
        (number.color)(number.start + r)
      } else {
        number.color
      }
      let number = cm.format-number(number.format, n)
      (
        if color != none { text(fill: color, number) } else { number }
          + cm.line-label(n, line-reference, version: version)
      )
    } else { [] }
    let fill = if i == none {
      general("blank-fill")
    } else if changed and conf.number-fill != auto {
      conf.number-fill
    } else {
      (number.fill)(r)
    }
    re.side-cell(
      content,
      numbers-width.at(version),
      height,
      ut.grow-inset(number.inset, edge(r)),
      (:),
      none,
      fill,
      sep,
      number.alignment,
    )
  }

  /// The marker cell of a line of a version (`none` for an unchanged line).
  let marker-cell(version, i, r, height) = {
    let status = if version != none { diff.at(version).status.at(i) } else {
      "same"
    }
    re.side-cell(
      if status == "same" { general("no-diff-marker") } else {
        versions.at(version).marker
      },
      if version != none { markers-width.at(version) } else {
        markers-width.new
      },
      height,
      ut.grow-inset(markers.inset, edge(r)),
      (:),
      none,
      if status == "whole" { versions.at(version).fill } else {
        (code.fill)(r)
      },
      markers.sep,
      center,
    )
  }

  /// The code cell of a line, with the highlights of the given versions.
  let code-cell(line-version, i, hls, r, height, width, tag) = {
    let l = lines.at(line-version).at(i)
    let blocks = ()
    for (version, k) in hls {
      let (slines, b) = hl.compute-highlights(
        k,
        l,
        width,
        code.inset.at(line-version),
        char-width,
        char-height,
        highlights.at(version).at(k),
      )
      l.slines = slines
      blocks += b
    }
    re.code-block(
      l,
      blocks,
      width,
      height,
      code.inset.at(line-version),
      (:),
      none,
      if diff.at(line-version).status.at(i) == "whole" {
        versions.at(line-version).fill
      } else {
        (code.fill)(r)
      },
      tag,
      char-width,
      char-height,
      code.indentation,
      extra: edge(r),
    )
  }

  /// A separator cell.
  let sep-cell(row-new, r, height) = re.side-cell(
    [],
    sep-width / 2,
    height,
    ut.full-inset(0mm),
    (:),
    (left: sep),
    if diff.new.status.at(row-new) == "whole" {
      versions.new.fill
    } else {
      (code.fill)(r)
    },
    none,
    top,
  )

  let tag-for(version, i, r) = if (
    lang-tag.visible
      and lang-tag.in-code
      and (if same-code { r == 0 } else { version == "new" and i == 0 })
  ) { lang-tag-block }

  let side-columns = int(number.visible) + int(markers.visible) + 1
  let all-columns = if same-code {
    2 * int(number.visible) + int(markers.visible) + 1
  } else { 2 * side-columns }

  /// The cells of a version for separated codes.
  let side-cells(version, row, r, height) = {
    let i = row.at(version)
    if i == none {
      (
        grid.cell(colspan: side-columns + int(version == "new"), block(
          width: side-width(version),
          height: height,
          fill: general("blank-fill"),
        )),
      )
    } else {
      let cells = ()
      if number.visible { cells.push(number-cell(version, i, r, height)) }
      if markers.visible { cells.push(marker-cell(version, i, r, height)) }
      cells.push(code-cell(
        version,
        i,
        ((version, i),),
        r,
        height,
        code-width.at(version),
        tag-for(version, i, r),
      ))
      cells
    }
  }

  let cells = ()
  let heights = ()
  for (r, row) in rows.enumerate() {
    let height = row-height(row) + edge(r).top + edge(r).bottom
    heights.push(height)

    if "comments" in row {
      let old-c = row.comments.first()
      let old-comment-cell = grid.cell(
        colspan: side-columns,
        re.comment-cell(
          old-c + (inset: ut.grow-inset(old-c.inset, edge(r))),
          height,
          (:),
          none,
          code.indentation,
          char-width,
        ),
      )
      let new-c = row.comments.last()
      new-c.inset.left += sep-width / 2
      new-c.width += sep-width / 2
      let new-comment-cell = grid.cell(
        colspan: side-columns + 1,
        re.comment-cell(
          new-c + (inset: ut.grow-inset(new-c.inset, edge(r))),
          height,
          (:),
          (left: sep),
          code.indentation,
          char-width,
        ),
      )
      cells.push(old-comment-cell)
      cells.push(new-comment-cell)
    } else if "comment" in row {
      if same-code or row.comment.version == "both" {
        cells.push(grid.cell(colspan: all-columns, re.comment-cell(
          row.comment + (inset: ut.grow-inset(row.comment.inset, edge(r))),
          height,
          (:),
          none,
          code.indentation,
          char-width,
        )))
      } else {
        let extra-comment-column = 0
        if row.comment.version == "new" and sep-width > 0pt {
          extra-comment-column = 1
          row.comment.inset.left += sep-width / 2
          row.comment.width += sep-width / 2
        }
        let comment-cell = grid.cell(
          colspan: side-columns + extra-comment-column,
          re.comment-cell(
            row.comment + (inset: ut.grow-inset(row.comment.inset, edge(r))),
            height,
            (:),
            if row.comment.version == "new" { (left: sep) },
            code.indentation,
            char-width,
          ),
        )
        let other-version = if row.comment.version == "old" { "new" } else {
          "old"
        }
        let extra-blank-column = int(other-version == "new" and sep-width > 0pt)
        let blank-cell = grid.cell(
          colspan: side-columns + extra-blank-column,
          block(
            width: side-width(other-version)
              + extra-blank-column * sep-width / 2,
            height: height,
            stroke: if other-version == "new" { (left: sep) },
            fill: general("blank-fill"),
          ),
        )
        cells.push(if row.comment.version == "old" { comment-cell } else {
          blank-cell
        })
        cells.push(if row.comment.version == "old" { blank-cell } else {
          comment-cell
        })
      }
    } else if same-code {
      let (i, j) = (row.old, row.new)
      if number.visible {
        cells.push(number-cell("old", i, r, height, sep: none))
        cells.push(number-cell("new", j, r, height))
      }
      let (version, k) = if j != none { ("new", j) } else { ("old", i) }
      if markers.visible {
        cells.push(marker-cell(
          if i != none and j != none { none } else { version },
          k,
          r,
          height,
        ))
      }
      let hls = if i != none and j != none { (("old", i), ("new", j)) } else {
        ((version, k),)
      }
      cells.push(code-cell(
        version,
        k,
        hls,
        r,
        height,
        code-width.new,
        tag-for(version, k, r),
      ))
    } else {
      cells += side-cells("old", row, r, height)
      if sep-width > 0pt and row.new != none {
        cells.push(sep-cell(row.new, r, height))
      }
      cells += side-cells("new", row, r, height)
    }
  }

  // Columns

  let code-column(version) = code-insets.at(version) + code-width.at(version)
  let columns = if same-code {
    (
      if number.visible { (numbers-width.old, numbers-width.new) } else {
        ()
      }
        + if markers.visible { (markers-width.new,) } else { () }
        + (code-column("new"),)
    )
  } else {
    let side(version) = (
      if number.visible { (numbers-width.at(version),) } else { () }
        + if markers.visible { (markers-width.at(version),) } else { () }
        + (code-column(version),)
    )
    (
      side("old")
        + if sep-width > 0pt { (sep-width / 2,) } else { () }
        + side("new")
    )
  }

  // Header and footer

  let header-cells = if header.content != none {
    heights.insert(0, auto)
    (
      grid.header(
        repeat: header.repeat,
        grid.cell(colspan: all-columns, block(
          width: total-width,
          height: header.height,
          inset: header.inset,
          fill: header.fill,
          stroke: (bottom: header.stroke.bottom),
          breakable: false,
          {
            align(header.alignment, header.content)
            // The lang tag placed in the header
            if header.tag != none { place(right + horizon, header.tag) }
          },
        )),
      ),
    )
  } else { () }
  let footer-cells = if footer.content != none {
    heights.push(auto)
    (
      grid.footer(
        repeat: footer.repeat,
        grid.cell(colspan: all-columns, block(
          width: total-width,
          height: footer.height,
          inset: footer.inset,
          fill: footer.fill,
          stroke: (top: footer.stroke.top),
          breakable: false,
          align(footer.alignment, footer.content),
        )),
      ),
    )
  } else { () }

  let frame-block = block(
    width: total-width,
    height: frame.height,
    breakable: frame.breakable,
    fill: frame.fill,
    stroke: frame.stroke,
    radius: frame.radius,
    clip: true,
    grid(
      columns: columns,
      rows: heights,
      ..header-cells,
      ..cells,
      ..footer-cells,
    ),
  )

  if lang-tag.visible and lang-tag.on-frame {
    if is-left or is-right {
      block({
        lt.place-frame-lang-tag(lang-tag, lang-tag-block)
        frame-block
      })
    } else {
      let tag = block(
        width: total-width,
        align(lt.lang-tag-alignment(lang-tag), lang-tag-block),
      )
      if is-top { stack(dir: ttb, tag, frame-block) } else {
        stack(dir: ttb, frame-block, tag)
      }
    }
  } else {
    frame-block
  }
})

/// The text of a raw element without its highlights delimiters, and these highlights.
#let read-delimited(r, pre-highlights) = {
  let phls = pre-highlights.values()
  let (dels, lines) = hl.parse-delimiters(r.text.split("\n"), phls)
  (
    text: lines.join("\n", default: ""),
    highlights: dels
      .map(del => hl.make-highlight(phls.at(del.idx), del))
      .map(hl.format-highlight),
  )
}

/// The version of a highlight, a comment or a jump (`"new"` by default).
#let check-version(version, both: false) = {
  let allowed = ("old", "new") + if both { ("both",) } else { () }
  assert(
    version in allowed,
    message: "The version must be "
      + allowed.map(v => "\"" + v + "\"").join(", ", last: " or ")
      + ".",
  )
  version
}

/// Normalize the comments of a diff: `(line, content)`, `(version, line, content)` or a dictionary with an optional `version`.
#let normalize-comments(comments) = {
  let comments = if type(comments) == dictionary { (comments,) } else if (
    comments.len() in (2, 3) and type(comments.first()) in (int, str)
  ) { (comments,) } else { comments }
  comments.map(c => {
    if type(c) == array {
      assert(
        c.len() in (2, 3),
        message: "A comment given as an array must be of the form `(line, content)` or `(version, line, content)`.",
      )
      c = if c.len() == 2 { (after: c.at(0), content: c.at(1)) } else {
        (version: c.at(0), after: c.at(1), content: c.at(2))
      }
    }
    c + (version: check-version(c.at("version", default: "new")))
  })
}

/// Normalize the jumps of a diff: `(from, to)`, `(version, from, to)` or a dictionary with an optional `version`.
#let normalize-jumps(jumps) = {
  let jumps = if type(jumps) == dictionary { (jumps,) } else if (
    jumps.len() in (2, 3) and jumps.all(j => type(j) in (int, str))
  ) { (jumps,) } else { jumps }
  jumps.map(j => {
    if type(j) == array {
      assert(
        j.len() in (2, 3),
        message: "A jump given as an array must be of the form `(from, to)` or `(version, from, to)`.",
      )
      j = if j.len() == 2 { (from: j.at(0), to: j.at(1)) } else {
        (version: j.at(0), from: j.at(1), to: j.at(2))
      }
    }
    j + (version: check-version(j.at("version", default: "new"), both: true))
  })
}

/// Display the difference between two raw blocks of code.
///
/// - args (arguments): The old and the new raw blocks, and the settings: the ones of `uraw` (except `coloring-follow-number`) and the ones specific to diffs (see `uraw-diff-set`).
/// - highlights (array): The highlights, on the line numbers of their `version` (`"old"` or `"new"`, `"new"` by default).
/// - comments (array): The comments, as `(line, content)`, `(version, line, content)` or dictionaries with a `version` (`"old"` or `"new"`, `"new"` by default). When the codes are separated, they span over both codes, the text of the old comments staying in the old code.
/// - jumps (array): The jumps of the number, as `(from, to)`, `(version, from, to)` or dictionaries with a `version`: `"old"`, `"new"` (by default), or `"both"` for a jump given on the new numbers, which jumps the same number of lines in the old code (its comment spans over both codes and is not indented).
/// -> content
#let uraw-diff(
  ..args,
  highlights: (),
  comments: (),
  jumps: (),
) = {
  let pos = args.pos()
  assert(
    pos.len() == 2 and pos.all(r => type(r) == content and r.func() == raw),
    message: "`uraw-diff` takes the old and the new raw blocks of code.",
  )
  let (old, new) = pos
  let settings = st.normalize-settings(args.named(), spec: diff-spec)
  let comments = normalize-comments(comments)
  let jumps = normalize-jumps(jumps)
  let highlights = ut
    .single-to-list(highlights)
    .map(h => h + (version: check-version(h.at("version", default: "new"))))

  // The text style outside of the raw environments, used by the comments
  context {
    let style = (font: text.font, size: text.size)
    cm.uraw-text.update(styles => styles + (style,))
  }

  // The raw elements are shown, so that a figure containing a diff is a listing
  {
    show <uraw-diff-src>: _ => context {
      let pre-highlights = st.uraw-uncontext-get-highlights(none)
      let delimited = (
        old: read-delimited(old, pre-highlights),
        new: read-delimited(new, pre-highlights),
      )
      let user-highlights = (:)
      for version in ("old", "new") {
        user-highlights.insert(version, (
          delimited: delimited.at(version).highlights,
          manual: highlights
            .filter(h => h.version == version)
            .map(h => hl.format-highlight-style(h, pre-highlights))
            .map(hl.format-highlight),
        ))
      }
      let base-text = cm.base-text

      // The two codes are shown as raw elements, to get their highlighted lines
      set text(1.25em)
      show <uraw-diff-new>: new-it => {
        show <uraw-diff-old>: old-it => render-diff(
          settings,
          old-it,
          new-it,
          user-highlights,
          comments,
          jumps,
          base-text,
        )
        set text(1.25em)
        [#raw(delimited.old.text, lang: old.lang, block: true)<uraw-diff-old>]
      }
      [#raw(delimited.new.text, lang: new.lang, block: true)<uraw-diff-new>]
    }
    [#raw(new.text, lang: new.lang, block: true)<uraw-diff-src>]
  }

  cm.uraw-text.update(styles => styles.slice(0, -1))
}
