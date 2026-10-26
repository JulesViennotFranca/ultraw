#import "utils.typ" as ut

/// The label of the figure being laid out, used to label the lines of the code it contains.
#let uraw-figure = state("uraw-figure", none)

/// The text styles outside of the raw environments (one per nested uraw call), used by the headers, footers, and comments.
#let uraw-text = state("uraw-text", ())

/// The text style of the header, footers, comments: the one outside of the raw environment (the current one before the state is known).
#let base-text() = {
  let styles = uraw-text.get()
  if styles.len() > 0 { styles.last() } else { (:) }
}

// -----------------------------------------------------------------------------
// Pseudo code marker
// -----------------------------------------------------------------------------

/// Mark pseudo code, so that the figures containing it can be detected.
///
/// - algorithm-figure (auto, bool): Wether the figure is an algorithm, `auto` to use the configured setting.
#let pseudo-marker(algorithm-figure) = metadata((
  uraw-pseudo: (algorithm-figure: algorithm-figure),
))

/// The value of the pseudo code marker in some content, `none` if there is none.
#let find-pseudo-marker(body) = {
  if type(body) != content { return none }
  if (
    body.func() == metadata
      and type(body.value) == dictionary
      and "uraw-pseudo" in body.value
  ) {
    return body.value.uraw-pseudo
  }
  if body.has("children") {
    for child in body.children {
      let m = find-pseudo-marker(child)
      if m != none { return m }
    }
    return none
  }
  if body.has("body") { return find-pseudo-marker(body.body) }
  if body.has("child") { return find-pseudo-marker(body.child) }
  none
}

// -----------------------------------------------------------------------------
// Jumps and line numbers
// -----------------------------------------------------------------------------

/// For each code block (raw or pseudo) in the document order, its kind and the number of its last line (`none` when its lines are not known yet). Each block adds itself with an update function, so that a whole chain of code blocks continuing each other's numbering is resolved at once.
#let uraw-blocks = state("uraw-blocks", ())

/// Mark the start of a code block, with the label of the figure containing it, and the data needed by the blocks of the same chain of continued blocks.
///
/// - kind (str): `"raw"` or `"pseudo"`.
/// - args (dictionary): The settings given to the block (inherited by the blocks following it).
/// - continues (none, label): The label of the block continued by this one.
/// - text (none, str): The text of the raw block (with its highlights delimiters).
/// - highlights (array): The manual highlights of the block.
/// - comments (array): The comments of the block.
/// - jumps (array): The jumps of the block.
/// -> content
#let block-start(
  kind: "raw",
  args: (:),
  continues: none,
  text: none,
  highlights: (),
  comments: (),
  jumps: (),
) = context [#metadata((
  figure: uraw-figure.get(),
  kind: kind,
  args: args,
  continues: continues,
  text: text,
  highlights: highlights,
  comments: comments,
  jumps: jumps,
))<uraw-block-start>]

/// The index (in the document order) of the code block labelled with `lbl`, or of the last code block in the figure labelled with `lbl`, `none` if it is not found yet.
///
/// - lbl (label): The label of the code or of the figure.
/// -> int, none
#let referenced-block(lbl) = {
  // Nothing is found before the first layout of the document
  let elements = query(lbl)
  if elements.len() == 0 { return none }
  assert(
    elements.len() == 1,
    message: "The label "
      + repr(lbl)
      + " given as the start of the numbering must be attached to exactly one code block or figure.",
  )

  let element = elements.first()
  if element.func() == figure {
    let starts = query(<uraw-block-start>)
    let i = starts.rev().position(m => m.value.figure == lbl)
    if i != none { starts.len() - 1 - i }
  } else {
    // The code blocks starting before the labelled element
    query(
      selector(<uraw-block-start>).before(
        element.location(),
        inclusive: false,
      ),
    ).len()
  }
}

/// Merge two settings dictionaries, the sections being merged key by key.
#let merge-settings(base, over) = {
  let merged = base
  for (key, value) in over {
    if (
      type(value) == dictionary
        and type(merged.at(key, default: none)) == dictionary
    ) {
      merged.insert(key, merged.at(key) + value)
    } else {
      merged.insert(key, value)
    }
  }
  merged
}

/// The structure of the chains of continued blocks, computed once per layout pass (the function has no argument, so that its result is cached): the start markers of the blocks (in the document order), and for each block the index of the block it continues (`none` if there is none) and the indexes of the blocks continuing it.
/// -> dictionary
#let chain-structure() = {
  let starts = query(<uraw-block-start>)
  let n = starts.len()
  let parent = starts.map(m => {
    let lbl = m.value.continues
    let ref = if lbl != none { referenced-block(lbl) }
    if ref != none and ref < n { ref }
  })
  let children = range(n).map(_ => ())
  for (k, p) in parent.enumerate() {
    if p != none { children.at(p).push(k) }
  }
  (starts: starts, parent: parent, children: children)
}

/// The indexes of the block of index `i` and of the blocks it continues, from the first one of the chain to it.
#let ancestors(structure, i) = {
  let chain = (i,)
  while structure.parent.at(chain.first()) != none {
    assert(
      chain.len() <= structure.starts.len(),
      message: "Some code blocks continue each other in a loop.",
    )
    chain.insert(0, structure.parent.at(chain.first()))
  }
  chain
}

/// The settings inherited by a code block following the code block labelled with `lbl`: its settings, and the ones of the blocks it follows.
///
/// - lbl (label): The label of the followed block.
/// -> dictionary
#let followed-settings(lbl) = {
  let structure = chain-structure()
  let ref = referenced-block(lbl)
  if ref == none or ref >= structure.starts.len() { return (:) }

  let settings = (:)
  for k in ancestors(structure, ref) {
    let followed = structure.starts.at(k).value
    if followed.kind != "raw" {
      panic(
        "The block labelled with "
          + repr(lbl)
          + " cannot be followed, only raw code can be.",
      )
    }
    settings = merge-settings(settings, followed.args)
  }
  settings
}

/// The indexes (in the document order) of the code blocks of the chain of continued blocks containing the block of index `i`, from the first one to the last one.
///
/// - i (int): The index of a code block.
/// -> array
#let block-chain(i) = {
  let structure = chain-structure()
  if i < 0 or i >= structure.starts.len() { return (i,) }

  // The first blocks of the chain, then the blocks continuing them
  let chain = ancestors(structure, i)
  while structure.children.at(chain.last()).len() > 0 {
    let next = structure.children.at(chain.last())
    assert(
      next.len() == 1,
      message: "A code block is continued by several blocks (labelled with "
        + repr(structure.starts.at(next.first()).value.continues)
        + ").",
    )
    assert(
      chain.len() <= structure.starts.len(),
      message: "Some code blocks continue each other in a loop.",
    )
    chain.push(next.first())
  }
  chain
}

/// Wether the code block of index `i` (in the document order) is followed by another one.
#let is-followed(i) = {
  let children = chain-structure().children
  i >= 0 and i < children.len() and children.at(i).len() > 0
}

/// The displayed line numbers, from the first one and the jumps.
#let line-numbers-from(start, nbr-lines, jumps-map) = {
  let line-numbers = ()
  for i in range(nbr-lines) {
    line-numbers.push(if i == 0 {
      start
    } else {
      let prev = line-numbers.last()
      if str(prev) in jumps-map { jumps-map.at(str(prev)).to } else { prev + 1 }
    })
  }
  line-numbers
}

/// The first number of a code block continuing the numbering of the code block of index `ref` (1 if it is not known yet).
#let start-after(blocks, ref) = if ref != none and ref < blocks.len() {
  let last = blocks.at(ref).last
  if last != none { last + 1 } else { 1 }
} else { 1 }

/// Check the jumps, compute the first number and the displayed line numbers.
///
/// - jumps (array, dictionary): The jumps as given by the user.
/// - numbering (dictionary): The numbering parameters.
/// - nbr-lines (int): The number of lines.
/// - kind (str): The kind of code, `"raw"` or `"pseudo"`.
/// -> array: the numbering parameters, the jumps, the displayed line numbers, and the update adding the code block to `uraw-blocks` with some checks (to be placed in the code block)
/// - register (bool): Wether the code block is added to `uraw-blocks` (otherwise the update only does the checks).
#let format-jumps(jumps, numbering, nbr-lines, kind, register: true) = {
  // Jumps only have an effect when the numbers are visible
  let jumps = if numbering.visible { jumps } else { () }
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

  let jumps-map = (:)
  for j in jumps {
    assert(
      not str(j.from) in jumps-map,
      message: "Several jumps start from line " + str(j.from) + ".",
    )
    jumps-map.insert(str(j.from), j)
  }

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

  // The code block continued by this one, when the start is a label
  let ref = if numbering.visible and type(numbering.start) == label {
    referenced-block(numbering.start)
  }

  /// The first number, from the code blocks before this one.
  let first-number(blocks) = if not numbering.visible {
    1
  } else if numbering.end != none {
    (
      numbering.end
        + 1
        - nbr-lines
        - jumps.map(j => j.to - j.from - 1).sum(default: 0)
    )
  } else if type(numbering.start) == label {
    start-after(blocks, ref)
  } else {
    numbering.start
  }

  let blocks = uraw-blocks.get()
  let continued-kind = if ref != none and ref < blocks.len() {
    blocks.at(ref).kind
  }
  let start-label = numbering.start
  numbering.start = first-number(blocks)

  // Displayed line numbers

  let line-numbers = line-numbers-from(numbering.start, nbr-lines, jumps-map)

  // Add the code block, computing its last number from the previous ones
  let update = if register {
    uraw-blocks.update(blocks => {
      let start = first-number(blocks)
      let numbers = line-numbers-from(start, nbr-lines, jumps-map)
      blocks + ((kind: kind, last: numbers.at(-1, default: start - 1)),)
    })
  } else { [] }

  // The checks depending on the other code blocks are done apart, so that the code block is registered even when they fail before the document converges
  update += context {
    if continued-kind not in (none, kind) {
      panic(
        "The numbering of "
          + kind
          + " code cannot continue the one of "
          + continued-kind
          + " code (labelled with "
          + repr(start-label)
          + ").",
      )
    }
    for j in jumps {
      assert(
        j.from in line-numbers,
        message: "The jump from line "
          + str(j.from)
          + " does not start from a line of the code block.",
      )
    }
  }

  (numbering, jumps, line-numbers, update)
}

/// The index of the line displayed with the number `n`.
#let line-index(line-numbers, n) = {
  let i = line-numbers.position(d => d == n)
  assert(
    i != none,
    message: "The line " + str(n) + " is not displayed in the code block.",
  )
  i
}

// -----------------------------------------------------------------------------
// Formatting
// -----------------------------------------------------------------------------

/// Format the insets, radius and stroke of the different parts.
///
/// -> array: the frame, header, footer, numbering and code parameters
/// - stroke-length (length): The length of the strokes given without one.
#let format-insets(
  frame,
  header,
  footer,
  numbering,
  code,
  stroke-length: .05em,
) = {
  // The strokes without length have the default one
  frame.stroke = ut.with-default-length(frame.stroke, stroke-length)
  header.sep = ut.with-default-length(header.sep, stroke-length)
  footer.sep = ut.with-default-length(footer.sep, stroke-length)
  numbering.sep = ut.with-default-length(numbering.sep, stroke-length)
  code.indentation = ut.with-default-length(code.indentation, stroke-length)

  // An automatic numbering inset is the code one
  if numbering.inset == auto { numbering.inset = code.inset }
  numbering.inset = ut.line-inset(numbering.inset, code.line-spacing)
  // The vertical code inset is the space before the first row and after the last one
  let edge = ut.vertical-inset(code.inset)
  code.insert("edge", (
    top: edge.top.to-absolute(),
    bottom: edge.bottom.to-absolute(),
  ))
  code.inset = ut.line-inset(code.inset, code.line-spacing)
  header.inset = ut.full-inset(header.inset)
  footer.inset = ut.full-inset(footer.inset)

  frame.radius = ut.full-radius(frame.radius)
  frame.stroke = ut.full-stroke(frame.stroke)

  (frame, header, footer, numbering, code)
}

/// The label of the line numbered `n` (`<figure-label.n>`, or `<figure-label.version.n>` for a version of a diff), as an invisible element to attach to its number, when the code is in a labelled figure and the lines can be referenced.
///
/// - n (int): The number of the line.
/// - line-reference (none, auto, function): The line reference setting.
/// - version (none, str): The version (`"old"` or `"new"`) for diffs.
/// -> content
#let line-label(n, line-reference, version: none) = {
  let figure-label = uraw-figure.get()
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

/// Format a line number with the `format` of the numbering: `auto` for the number, a string in which the first `1` is replaced by the number (as `"1:"`), or a function of the number returning some content.
#let format-number(format, n) = if format == auto or format == none {
  str(n)
} else if type(format) == str {
  let k = format.position("1")
  assert(
    k != none,
    message: "A numbering format given as a string must contain a `1`, replaced by the line number (as \"1:\").",
  )
  format.slice(0, k) + str(n) + format.slice(k + 1)
} else {
  let n = format(n)
  if type(n) == int { str(n) } else { n }
}

/// Format the numbers (labelled for line references) and the fill functions of the numbering and the code.
///
/// -> array: the numbering and the code parameters
#let format-colors(
  numbering,
  code,
  frame,
  line-numbers,
  nbr-lines,
  coloring-follow-numbering,
  line-reference,
) = {
  // The lines without number (`none`) have the number of the previous numbered line for the fill and color functions
  let numbered = line-numbers.filter(n => n != none)
  let previous-number(i) = {
    let k = i
    while k >= 0 and line-numbers.at(k) == none { k -= 1 }
    if k >= 0 { line-numbers.at(k) } else if numbered.len() > 0 {
      numbered.first() - 1
    } else { numbering.start - 1 }
  }

  /// The number given to the fill and color functions for the line of index `i` (the header is `-1` and the footer `nbr-lines`).
  let fill-number(i) = if (
    numbering.visible
      and coloring-follow-numbering
      and nbr-lines > 0
      and numbered.len() > 0
  ) {
    if i < 0 {
      numbered.first() + i
    } else if i >= nbr-lines {
      numbered.last() + i - nbr-lines + 1
    } else {
      previous-number(i)
    }
  } else { i + 1 }
  let number(i) = if line-numbers.at(i) == none { [] } else {
    format-number(numbering.format, line-numbers.at(i))
  }
  numbering.insert("coloring", (i, it) => if numbering.color == auto {
    it
  } else if type(numbering.color) == function {
    let c = (numbering.color)(fill-number(i))
    if c != none { text(fill: c, it) } else { it }
  } else {
    text(fill: numbering.color, it)
  })
  let numbering-format(i) = (numbering.coloring)(i, number(i))
  // Label the numbers as `<figure-label.n>` when the code is in a labelled figure (and the lines can be referenced)
  numbering.insert("cell", i => {
    numbering-format(i)
    if line-numbers.at(i) != none {
      line-label(line-numbers.at(i), line-reference)
    }
  })

  code.fill = if type(code.fill) == function {
    i => (code.fill)(fill-number(i))
  } else {
    _ => code.fill
  }

  numbering.fill = if type(numbering.fill) == function {
    i => {
      let b = (numbering.fill)(fill-number(i))
      if b == auto {
        (code.fill)(i)
      } else {
        b
      }
    }
  } else if numbering.fill == auto {
    code.fill
  } else {
    _ => numbering.fill
  }

  (numbering, code)
}

/// Format the header and the footer.
///
/// -> array: the header and the footer parameters
#let format-header-footer(header, footer, frame, code, nbr-lines) = {
  header.fill = if header.fill == auto {
    (code.fill)(-1)
  } else {
    header.fill
  }

  header.stroke = (
    top: frame.stroke.top,
    left: frame.stroke.left,
    right: frame.stroke.right,
    bottom: if header.sep == auto { frame.stroke.top } else { header.sep },
  )

  header.radius = (
    top-left: frame.radius.top-left,
    top-right: frame.radius.top-right,
  )

  if header.content != none { let _ = header.remove("sep") }

  footer.fill = if footer.fill == auto {
    (code.fill)(nbr-lines)
  } else {
    footer.fill
  }

  footer.stroke = (
    top: if footer.sep == auto { frame.stroke.bottom } else { footer.sep },
    left: frame.stroke.left,
    right: frame.stroke.right,
    bottom: frame.stroke.bottom,
  )

  footer.radius = (
    bottom-left: frame.radius.bottom-left,
    bottom-right: frame.radius.bottom-right,
  )

  (header, footer)
}

// -----------------------------------------------------------------------------
// Comments
// -----------------------------------------------------------------------------

/// Format a comment whose settings are resolved.
///
/// - c (dictionary): The comment, with its settings and content.
/// - gap (int): The index of the code line following the comment.
/// - key (none, int): The sorting key of the comment.
/// - fill (none, color): The fill used when the comment has none (the frame fill).
/// - spans (bool): Wether the comment spans over the columns before the code when it is not in the code.
/// - comments-text (function): The function giving the text style of the comments (only called when there is a comment, so that blocks without comments do not depend on the state storing it).
/// -> dictionary
#let format-comment(c, gap, key, fill, spans, comments-text) = {
  let c = c + (gap: gap, key: key)
  if c.fill == none { c.fill = fill }
  c.insert("spans", not c.in-code and spans and c.marker == none)

  let body = c.content
  if c.style != none {
    body = (c.style)(body)
    if c.marker != none and not c.in-code { c.marker = (c.style)(c.marker) }
  }
  c.insert("body", text(..comments-text(), body))
  if c.marker != none and not c.in-code {
    c.marker = text(..comments-text(), c.marker)
  }
  c
}

/// The comments in place of the skipped lines of jumps.
///
/// - jumps (array): The formatted jumps.
/// - jump (dictionary): The jump settings.
/// - comment (dictionary): The comment settings.
/// - line-numbers (array): The displayed line numbers.
/// - format (function): Format a comment from its settings and content, its gap and its key.
/// -> array
#let jump-comments(jumps, jump, comment, line-numbers, format) = {
  jumps
    .map(j => {
      let jc = ut.filter-add-dict(jump, j)

      // The `comment-*` settings of the jump, `auto` ones are the comment settings
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
            + (
              content: content,
              span: j.at("span", default: false),
              copy-before: true,
            ),
          line-index(line-numbers, j.from) + 1,
          none,
        )
      }
    })
    .filter(c => c != none)
}

/// Parse the comments given by the user, sorted by the space between two consecutive line numbers they are in (`after: n` comes before `before: n + 1`).
///
/// - comments (array, dictionary): The comments as given by the user.
/// - comment (dictionary): The comment settings.
/// - line-numbers (array): The displayed line numbers.
/// - format (function): Format a comment from its settings and content, its gap and its key.
/// -> array
#let parse-comments(comments, comment, line-numbers, format) = {
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

      let after = "after" in c
      let n = if after { c.after } else { c.before }
      assert(
        type(n) == int,
        message: "The `after` or `before` line of a comment must be an integer.",
      )

      format(
        ut.filter-add-dict(comment, c)
          + (
            content: c.content,
            span: c.at("span", default: false),
            copy-before: after,
          ),
        line-numbers.filter(d => if after { d <= n } else { d < n }).len(),
        if after { 2 * n } else { 2 * n - 1 },
      )
    })
    .sorted(key: c => c.key)
}
