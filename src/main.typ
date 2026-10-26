#import "common.typ" as cm
#import "content.typ" as ct
#import "highlight.typ" as hl
#import "../src/lang-tag.typ" as lt
#import "measure.typ" as me
#import "pseudo.typ" as ps
#import "rendering.typ" as re
#import "state.typ" as st
#import "utils.typ" as ut

#let uraw-text = cm.uraw-text

#let uraw-figure = cm.uraw-figure

/// Wether a figure is turned into an algorithm: it is a figure of image kind (the kind of figures whose kind cannot be detected) containing pseudo code with the `algorithm-figure` setting.
#let is-algorithm-figure(fig, at: none) = {
  if fig.func() != figure or fig.kind != image { return false }
  let marker = cm.find-pseudo-marker(fig.body)
  if marker == none { return false }
  if marker.algorithm-figure != auto { return marker.algorithm-figure }
  let conf = if at == none { ps.uraw-pseudo-state.get() } else {
    ps.uraw-pseudo-state.at(at)
  }
  conf.algorithm-figure
}

/// The algorithm figure replacing a figure, or the figure itself.
#let resolve-figure(fig) = if is-algorithm-figure(fig, at: fig.location()) {
  query(figure.where(kind: "algorithm").after(fig.location())).first()
} else {
  fig
}

#let raw-to-uraw(
  ..args,
  manual-highlights,
  highlights,
  comments,
  jumps,
  continues,
  base-text,
  it,
  lines-range: none,
  chain-id: none,
  chain-texts: none,
) = layout(layout-size => {
  let args = args.named()

  // The blocks of a chain of continued blocks share the smallest width available to them
  if chain-id != none {
    [#metadata((chain: chain-id, width: layout-size.width))<uraw-chain-width>]
  }
  let layout-size = if chain-id != none {
    (
      width: calc.min(
        layout-size.width,
        ..query(<uraw-chain-width>)
          .filter(m => m.value.chain == chain-id)
          .map(m => m.value.width),
      ),
      height: layout-size.height,
    )
  } else { layout-size }

  // Wether this block is followed by another one
  let followed = cm.is-followed(
    query(selector(<uraw-block-start>).before(here())).len() - 1,
  )

  // Parsing

  let frame = st.parse-frame(lang: it.lang, ..args)
  // A relative width is resolved on the available width (shared by the blocks of a chain)
  if type(frame.width) == ratio {
    frame.width = layout-size.width * frame.width
  } else if type(frame.width) == relative {
    frame.width = layout-size.width * frame.width.ratio + frame.width.length
  }
  let header = st.parse-header(lang: it.lang, ..args)
  let footer = st.parse-footer(lang: it.lang, ..args)
  let numbering = st.parse-numbering(lang: it.lang, ..args)
  let code = st.parse-code(lang: it.lang, ..args)
  let lang-tag = st.parse-lang-tag(lang: it.lang, ..args)
  let stroke-length = st.parse-general(
    lang: it.lang,
    "default-stroke-length",
    ..args,
  )
  lang-tag.stroke = ut.with-default-length(lang-tag.stroke, stroke-length)
  let comment = st.parse-comment(lang: it.lang, ..args)
  let jump = st.parse-jump(lang: it.lang, ..args)
  let coloring-follow-numbering = st.parse-general(
    lang: it.lang,
    "coloring-follow-numbering",
    ..args,
  )
  let line-reference = st.parse-general(
    lang: it.lang,
    "line-reference",
    ..args,
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

  // In a chain of continued blocks, the raw element only has the lines of this block, the texts of all the lines being given
  let nbr-lines = if chain-texts != none { chain-texts.len() } else {
    it.lines.len()
  }

  // Jumps

  let (numbering, jumps, line-numbers, blocks-update) = cm.format-jumps(
    jumps,
    numbering,
    nbr-lines,
    "raw",
    register: lines-range == none,
  )
  // A block of a chain of continued blocks registers its own last line
  if lines-range != none {
    let last = line-numbers.at(lines-range.last() - 1)
    blocks-update += cm.uraw-blocks.update(blocks => (
      blocks + ((kind: "raw", last: last),)
    ))
  }
  let line-index = n => cm.line-index(line-numbers, n)

  // Insets & radius & stroke

  (frame, header, footer, numbering, code) = cm.format-insets(
    frame,
    header,
    footer,
    numbering,
    code,
    stroke-length: stroke-length,
  )

  // Color formatting

  (numbering, code) = cm.format-colors(
    numbering,
    code,
    frame,
    line-numbers,
    nbr-lines,
    coloring-follow-numbering,
    line-reference,
  )

  // The frame is open between a block and the one following it, as at a page break,
  // except where a header or a footer is repeated
  if continues != none and not (header.repeat and header.content != none) {
    frame.stroke.top = none
    frame.radius.top-left = 0pt
    frame.radius.top-right = 0pt
    header.content = none
  }
  if followed and not (footer.repeat and footer.content != none) {
    frame.stroke.bottom = none
    frame.radius.bottom-left = 0pt
    frame.radius.bottom-right = 0pt
    footer.content = none
  }

  // Lang tag formatting

  lang-tag.visible = it.lang != none and lang-tag.format != none
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

  // In a chain of following blocks, the lang tag is on the first block, or on the last one when it is at the bottom
  let at-bottom = (
    lang-tag.placement
      in (
        "bottom-left",
        "bottom",
        "bottom-right",
        "left-bottom",
        "right-bottom",
      )
  )
  // (a lang tag in a repeated header is repeated with it)
  let in-repeated-header = (
    lang-tag.placement == "header" and header.content != none and header.repeat
  )
  if (
    at-bottom and followed
      or not at-bottom and continues != none and not in-repeated-header
  ) {
    lang-tag.visible = false
  }

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

  lang-tag.insert(
    "in-code",
    lang-tag.placement == "code" or lang-tag.placement == "inline",
  )
  lang-tag.insert(
    "on-frame",
    lang-tag.placement not in ("code", "inline", "header"),
  )

  let lang-tag-block = if lang-tag.visible {
    lt.lang-tag-block(it.lang, lang-tag, frame)
  } else { none }

  // The lang tag placed in the header
  header.insert(
    "tag",
    if lang-tag.visible and lang-tag.placement == "header" { lang-tag-block },
  )

  let (is-top, is-left, is-right, is-bottom) = {
    if lang-tag.visible and lang-tag.on-frame {
      lt.lang-tag-position(lang-tag)
    } else {
      (none, none, none, none)
    }
  }

  // Header & footer formatting

  (header, footer) = cm.format-header-footer(
    header,
    footer,
    frame,
    code,
    nbr-lines,
  )
  if header.content != none {
    header.content = text(..base-text(), header.content)
  }
  if footer.content != none {
    footer.content = text(..base-text(), footer.content)
  }

  // Lines formatting

  // The number of spaces of an indentation level
  let indent-size = if code.indent-size == auto { it.tab-size } else {
    code.indent-size
  }

  // The lines, as their text and their content (an empty content for the lines of the other blocks of a chain)
  let raw-lines = if chain-texts != none {
    chain-texts
      .enumerate()
      .map(((i, t)) => {
        let k = i - lines-range.first()
        if 0 <= k and k < it.lines.len() {
          (text: t, body: it.lines.at(k).body)
        } else { (text: t, body: []) }
      })
  } else {
    it.lines.map(l => (text: l.text, body: l.body))
  }

  let it-lines = raw-lines.map(l => if ct.is-whitespace-line(l.text) {
    (line: [], text: "", pos-indent: (0,), line-end: 0)
  } else {
    let num-indent = ct.get-text-indent(l.text, indent-size)
    let pos-indent = range(num-indent + 1).map(i => i * indent-size)
    (line: l.body, text: l.text, pos-indent: pos-indent, line-end: l.text.len())
  })

  let i = it-lines.len() - 2
  while 0 <= i {
    if it-lines.at(i).text.len() == 0 {
      it-lines.at(i).pos-indent = it-lines.at(i + 1).pos-indent
    }
    i -= 1
  }

  // Comments formatting

  let format-comment(c, gap, key) = cm.format-comment(
    c,
    gap,
    key,
    frame.fill,
    numbering.visible,
    base-text,
  )

  // Comments in place of the skipped lines
  let jump-comments = cm.jump-comments(
    jumps,
    jump,
    comment,
    line-numbers,
    format-comment,
  )

  let comments = cm.parse-comments(
    comments,
    comment,
    line-numbers,
    format-comment,
  )

  // Jump comments come first
  comments = jump-comments + comments

  // Highlight formatting

  let manual-highlights = manual-highlights.map(hl => {
    hl.range.first().first() = line-index(hl.range.first().first())
    hl.range.last().first() = line-index(hl.range.last().first())
    hl
  })

  let highlights = hl.merge-right-sort-highlights(manual-highlights, highlights)

  highlights = highlights.map(hl => {
    if hl.range.first().last() == auto {
      let i = hl.range.first().first()
      hl.range.first().last() = it-lines.at(i).pos-indent.last()
    }

    if hl.range.last().last() == auto {
      let i = hl.range.last().first()
      hl.range.last().last() = it-lines.at(i).line-end
    }

    hl
  })

  let _ = highlights.map(hl.check-highlight)

  highlights = highlights.rev()

  // Available width

  let char-width = measure("#").width

  let numbers-width = if numbering.visible {
    let numbers-width = me.numbers-width(
      line-numbers,
      format: n => cm.format-number(numbering.format, n),
      // Only the formats given by functions can be wider for other numbers
      monotonic: type(numbering.format) != function,
    )
    let comments-markers-width = calc.max(
      0pt,
      ..comments
        .filter(c => c.marker != none)
        .map(c => measure(c.marker).width),
    )
    (
      numbering.inset.left
        + calc.max(numbers-width, comments-markers-width)
        + numbering.inset.right
    )
  } else { 0mm }

  lang-tag.insert(
    "width",
    if lang-tag.visible and lang-tag.in-code {
      measure(lang-tag-block).width + lang-tag.code-spacing.to-absolute()
    },
  )

  let code-width = me.available-code-width(
    layout-size,
    frame,
    code,
    numbers-width,
  )
  let max-code-width = code-width

  // Comments indentation and insets

  comments = comments.map(c => {
    if c.indented and c.copy-before {
      c.insert("pos-indent", if c.gap > 0 {
        it-lines.at(c.gap - 1).pos-indent
      } else { () })
    } else if c.indented and not c.copy-before {
      c.insert("pos-indent", if c.gap < it-lines.len() {
        it-lines.at(c.gap).pos-indent
      } else { () })
    }
    c
  })
  comments = comments.map(c => {
    let left = if c.indented {
      let indent = if c.pos-indent.len() > 0 {
        c.pos-indent.last() * char-width
      } else { 0mm }
      code.inset.left + indent + if c.spans { numbers-width } else { 0mm }
    } else if c.spans {
      numbering.inset.left
    } else {
      code.inset.left
    }

    c.insert("inset", (
      left: left,
      right: code.inset.right,
      top: code.inset.top,
      bottom: code.inset.bottom,
    ))
    c
  })

  // Break lines in sub-lines

  // In a chain of continued blocks, only the lines of this block are broken, the width of the other lines being estimated from their length (the code is monospaced)
  let own(i) = (
    lines-range == none or (lines-range.first() <= i and i < lines-range.last())
  )

  it-lines = it-lines
    .enumerate()
    .map(l => {
      let slines = if not own(l.first()) {
        (
          (
            start: 0,
            body: [],
            end: l.last().line-end,
            estimated-width: l.last().line-end * char-width,
          ),
        )
      } else {
        ct.format-line(
          l.last().line,
          code-width
            + if lang-tag.visible and lang-tag.placement == "code" {
              -lang-tag.width
            },
          char-width,
          l.last().line-end,
          if lang-tag.placement == "inline" and l.first() == 0 {
            lang-tag.width
          },
        )
      }
      (
        line: l.last().line,
        slines: slines,
        pos-indent: l.last().pos-indent,
        line-end: l.last().line-end,
      )
    })

  // Width

  if header.remove("code-aligned") { header.inset.left = numbers-width }
  if footer.remove("code-aligned") { footer.inset.left = numbers-width }

  let header-width = if header.content != none {
    (
      measure(block(inset: header.inset, header.content)).width
        + if header.tag != none {
          measure(header.tag).width + lang-tag.code-spacing.to-absolute()
        } else { 0pt }
    )
  } else { 0mm }
  let footer-width = if footer.content != none {
    measure(block(inset: footer.inset, footer.content)).width
  } else { 0mm }

  code-width = me.tight-code-width(frame, code-width, lang-tag, it-lines)
  code-width = me.hf-code-width(
    header-width,
    numbers-width,
    code,
    code-width,
    footer-width,
  )
  code-width = me.comments-code-width(
    frame,
    comments,
    numbers-width,
    code,
    code-width,
    max-code-width,
  )

  if frame.width == auto {
    frame.width = (
      numbers-width + code.inset.left + code-width + code.inset.right
    )
  }

  // Height

  let char-height = measure("#").height
  let it-lines-height = it-lines.map(l => (
    l.slines.len() * (char-height + code.line-spacing)
  ))

  // Comments size

  let comments-map = range(nbr-lines + 1).map(_ => ())
  for c in comments {
    c.insert(
      "width",
      code.inset.left
        + code-width
        + code.inset.right
        + if c.spans { numbers-width } else { 0mm },
    )
    let body-height = measure(width: c.width, block(
      inset: c.inset,
      c.body,
    )).height
    c.insert(
      "height",
      if numbering.visible and c.marker != none {
        calc.max(
          body-height,
          measure(width: numbers-width, block(
            inset: numbering.inset,
            c.marker,
          )).height,
        )
      } else { body-height },
    )
    comments-map.at(c.gap).push(c)
  }

  // Highlights blocks touching each other

  highlights = highlights.map(h => (
    h
      + (
        touches: hl.compute-touches(
          h,
          it-lines,
          code-width,
          code.inset,
          char-width,
        ),
      )
  ))

  // Group the highlight by line of application
  let highlights-map = range(nbr-lines).map(_ => ())
  for h in highlights {
    for i in range(h.range.first().first(), h.range.last().first() + 1) {
      highlights-map.at(i).push(h)
    }
  }

  // Rendering

  let frame-content = re.render(
    nbr-lines,
    numbering,
    numbers-width,
    code,
    it-lines,
    code-width,
    it-lines-height,
    frame,
    header,
    footer,
    lang-tag,
    lang-tag-block,
    char-width,
    char-height,
    highlights-map,
    comments-map,
    lines-range: lines-range,
  )

  let frame-block = block(
    width: frame.width,
    height: frame.height,
    breakable: frame.breakable,
    frame-content,
  )

  // Register the code block, to continue its numbering
  blocks-update

  if lang-tag.visible and lang-tag.on-frame {
    if is-left or is-right {
      block({
        lt.place-frame-lang-tag(lang-tag, lang-tag-block)
        frame-block
      })
    } else {
      let alignment = lt.lang-tag-alignment(lang-tag)
      lang-tag-block = block(
        width: frame.width,
        align(alignment, lang-tag-block),
      )
      if is-top {
        stack(dir: ttb, lang-tag-block, frame-block)
      } else {
        stack(dir: ttb, frame-block, lang-tag-block)
      }
    }
  } else {
    frame-block
  }
})

/// Display raw code.
///
/// - args (arguments): The settings (see `uraw-set`), and the content whose raw blocks are displayed.
/// - highlights (array): The highlights of the code.
/// - comments (array): The comments of the code.
/// - jumps (array): The jumps of the numbering.
/// - continues (none, label): The label of a code block (or of a figure containing it) that this code continues: it inherits its settings (its own settings taking precedence), continues its numbering, and the frame between them is open as at a page break (the header is only repeated with `header.repeat`, and the footer of the followed block is only shown with `footer.repeat`).
/// -> content
#let uraw(
  ..args,
  highlights: (),
  comments: (),
  jumps: (),
  continues: none,
  doc,
) = {
  assert(
    continues == none or type(continues) == label,
    message: "A block can only continue a block given by its label.",
  )
  // Settings given by section or flat (e.g. `header-fill`)
  let args = st.normalize-settings(args.named())

  /// The show rules displaying the raw blocks, with the function giving the text style of the headers, footers, and comments.
  let with-rules(base-text) = {
    // Remember the label of the figure containing the code
    show figure: it => if it.has("label") {
      uraw-figure.update(it.label)
      it
      uraw-figure.update(none)
    } else {
      it
    }

    // Figures containing pseudo code are algorithms (with their own numbering),
    // their supplement can be changed by a later show-set rule
    show figure.where(kind: "algorithm"): set figure(supplement: [Algorithm])
    show figure.where(kind: image): it => if is-algorithm-figure(it) {
      let fields = it.fields()
      // The lines are labelled after the replaced figure, which is the one referenced
      if it.has("label") { uraw-figure.update(it.label) }
      figure(
        it.body,
        kind: "algorithm",
        caption: if it.caption != none { it.caption.body },
        ..("placement", "scope", "gap", "numbering", "outlined")
          .filter(key => key in fields)
          .map(key => (key, fields.at(key)))
          .to-dict(),
      )
      // The replaced figure is not an image
      counter(figure.where(kind: image)).update(n => n - 1)
      if it.has("label") { uraw-figure.update(none) }
    } else {
      it
    }
    show outline.entry: it => if is-algorithm-figure(
      it.element,
      at: it.element.location(),
    ) { none } else { it }

    // A reference to a figure containing pseudo code refers to its algorithm
    show ref: it => {
      let el = it.element
      if el == none or not is-algorithm-figure(el, at: el.location()) {
        return it
      }
      let alg = resolve-figure(el)
      let supplement = if it.supplement == auto {
        alg.supplement
      } else if type(it.supplement) == function {
        (it.supplement)(alg)
      } else {
        it.supplement
      }
      link(
        alg.location(),
        if supplement in (none, []) { [] } else { supplement + [~] }
          + numbering(
            alg.numbering,
            ..counter(figure.where(kind: "algorithm")).at(alg.location()),
          ),
      )
    }

    // A reference to a line `@figure-label.n` displays the reference to its figure followed by `.n`,
    // and links to the line number
    show ref: it => {
      let el = it.element
      if (
        el == none
          or el.func() != metadata
          or type(el.value) != dictionary
          or not "uraw-line-ref" in el.value
      ) {
        return it
      }

      let line-ref = el.value.uraw-line-ref
      let (figure-label, n, line-reference) = (
        line-ref.figure,
        line-ref.number,
        line-ref.reference,
      )
      let version = line-ref.at("version", default: none)
      let fig = resolve-figure(query(figure-label).first())
      assert(
        fig.numbering != none,
        message: "Cannot reference a line of a figure without numbering.",
      )

      let fig-number = numbering(
        fig.numbering,
        ..counter(figure.where(kind: fig.kind)).at(fig.location()),
      )
      let supplement = if it.supplement == auto {
        fig.supplement
      } else if type(it.supplement) == function {
        (it.supplement)(fig)
      } else {
        it.supplement
      }

      link(
        el.location(),
        if supplement in (none, []) { [] } else { supplement + [~] }
          + fig-number
          + if line-reference == auto {
            "." + str(n) + if version != none { " (" + version + ")" }
          } else if version != none {
            line-reference(n, version)
          } else {
            line-reference(n)
          },
      )
    }

    /// Display a raw block whose highlights delimiters are removed, with the highlights read from these delimiters.
    let display(it, delimited) = {
      let pre-highlights = st.uraw-uncontext-get-highlights(none)
      let format-manual(hls) = ut
        .single-to-list(hls)
        .map(h => hl.format-highlight-style(h, pre-highlights))
        .map(hl.format-highlight)

      // The chain of continued blocks containing this block
      let index = query(selector(<uraw-block-start>).before(here())).len() - 1
      let chain = cm.block-chain(index)
      let position = chain.position(k => k == index)

      // A block continuing another one inherits its settings, and the numbering of the first block of the chain
      let block-args = if continues != none {
        let inherited = cm.merge-settings(cm.followed-settings(continues), args)
        let starts = query(<uraw-block-start>)
        let first-numbering = if chain.first() < starts.len() {
          cm
            .merge-settings(
              (:),
              starts.at(chain.first()).value.args,
            )
            .at("numbering", default: (:))
        } else { (:) }
        let numbering = inherited.at("numbering", default: (:))
        for key in ("start", "end") {
          let _ = numbering.remove(key, default: none)
          if key in first-numbering {
            numbering.insert(key, first-numbering.at(key))
          }
        }
        inherited.insert("numbering", numbering)
        inherited
      } else { args }

      if chain.len() > 1 and position != none {
        // The blocks of the chain are computed as a single block, of which only the lines of this block are shown
        let members = chain.map(k => query(<uraw-block-start>).at(k).value)
        let sizes = members.map(m => m.text.split("\n").len())
        let start = sizes.slice(0, position).sum(default: 0)
        let range = (start, start + sizes.at(position))

        let phls = pre-highlights.values()
        let (dels, lines) = hl.parse-delimiters(
          members.map(m => m.text).join("\n").split("\n"),
          phls,
        )
        let delimited = dels
          .map(del => hl.make-highlight(phls.at(del.idx), del))
          .map(hl.format-highlight)
        let manual = members.fold((), (acc, m) => (
          acc + format-manual(m.highlights)
        ))
        let all-comments = members.fold((), (acc, m) => (
          acc + ut.single-to-list(m.comments)
        ))
        let all-jumps = members.fold((), (acc, m) => (
          acc + ut.single-to-list(m.jumps)
        ))
        let base-text = base-text

        set text(1.25em)
        show <uraw-chain>: chain-it => raw-to-uraw(
          ..block-args,
          manual,
          delimited,
          all-comments,
          all-jumps,
          continues,
          base-text,
          chain-it,
          lines-range: range,
          chain-id: chain.first(),
          chain-texts: lines,
        )
        // Only the lines of this block are highlighted by Typst
        [#raw(
          lines.slice(..range).join("\n"),
          lang: it.lang,
          block: true,
        )<uraw-chain>]
      } else {
        raw-to-uraw(
          ..block-args,
          format-manual(highlights),
          delimited.map(hl.format-highlight),
          comments,
          jumps,
          continues,
          base-text,
          it,
        )
      }
    }

    show raw.where(block: true): it => context {
      set text(1.25em)

      let pre-highlights = st.uraw-uncontext-get-highlights(none).values()
      cm.block-start(
        args: args,
        continues: continues,
        text: it.text,
        highlights: highlights,
        comments: comments,
        jumps: jumps,
      )

      // The highlights delimiters are removed, and the highlights given directly to the display (without introspection)
      let (dels, lines) = hl.parse-delimiters(
        it.lines.map(l => l.text),
        pre-highlights,
      )
      let delimited = dels.map(del => hl.make-highlight(
        pre-highlights.at(del.idx),
        del,
      ))
      show <uraw-code>: code-it => display(code-it, delimited)
      [#raw(lang: it.lang, lines.join("\n", default: ""))<uraw-code>]
    }

    doc
  }

  // The text style outside of the raw environments, used by the comments:
  // - for a whole document (`#show: uraw`), it is read directly, which costs no layout pass,
  // - for a raw block (which can be the body of a figure, whose kind is detected only if the raw block is not in a context), it is stored in a state
  if type(doc) == content and doc.func() == raw {
    context {
      let style = (font: text.font, size: text.size)
      uraw-text.update(styles => styles + (style,))
    }
    with-rules(cm.base-text)
    uraw-text.update(styles => styles.slice(0, -1))
  } else {
    context {
      let style = (font: text.font, size: text.size)
      with-rules(() => style)
    }
  }
}
