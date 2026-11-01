#import "content.typ" as ct
#import "formatting.typ" as formatting
#import "highlight.typ" as hl
#import "measure.typ" as me
#import "rendering.typ" as re
#import "config.typ" as cf
#import "utils.typ" as ut


#let uraw-figure = cf.uraw-figure

/// Wether a figure is turned into an algorithm: it is a figure of image kind (the kind of figures whose kind cannot be detected) containing pseudo code with the `algorithm-figure` setting.
#let is-algorithm-figure(fig, at: none) = {
  if fig.func() != figure or fig.kind != image { return false }
  let marker = formatting.find-pseudo-marker(fig.body)
  if marker == none { return false }
  if marker.algorithm-figure != auto { return marker.algorithm-figure }
  let conf = if at == none { cf.uraw-pseudo-config-state.get() } else {
    cf.uraw-pseudo-config-state.at(at)
  }
  conf.general.algorithm-figure
}

/// The algorithm figure replacing a figure, or the figure itself.
#let resolve-figure(fig) = if is-algorithm-figure(fig, at: fig.location()) {
  query(figure.where(kind: "algorithm").after(fig.location())).first()
} else {
  fig
}

#let raw-to-uraw(
  args,
  markers,
  manual-highlights,
  highlights,
  comments,
  jumps,
  base-style,
  first-line,
  it,
) = {
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

  // The states (settings, outside style, identifier) are read outside of `layout`, whose content can be laid out without them (as when measuring an auto column of a grid)
  context {
    let id = id-counter.get().first()
    let style = base-style()
    let base-style() = style
    let general = cf.category-parser("general", args, it.lang)
    let with-default-thickness(stroke) = ut.with-default-thickness(
      stroke,
      general.default-stroke-thickness,
    )

    let frame = cf.category-parser("frame", args, it.lang)
    let header = cf.category-parser("header", args, it.lang)
    let footer = cf.category-parser("footer", args, it.lang)
    let number = cf.category-parser("numbers", args, it.lang)
    let code = cf.category-parser("code", args, it.lang)
    let lang-tag = cf.category-parser("lang-tag", args, it.lang)
    let comment = cf.category-parser("comment", args, it.lang)
    let jump = cf.category-parser("jump", args, it.lang)

    set par(leading: code.line-spacing)

    layout(layout-size => {
      let frame = formatting.frame-width(frame, layout-size)

      // The measures (of the comments, headers, ...) only take the settings above into account in a new context
      context {
        // (the settings are modified below)
        let (frame, header, footer, number, code, lang-tag, comment, jump) = (
          frame,
          header,
          footer,
          number,
          code,
          lang-tag,
          comment,
          jump,
        )

        // Continuation: the block follows or precedes another one, as at a page break
        let follows = args.at("follows", default: false)
        let precedes = args.at("precedes", default: false)
        assert(
          type(follows) in (bool, int),
          message: "`follows` must be a boolean, or the number of the last line of the preceding block.",
        )
        assert(
          type(precedes) in (bool, int, str, content),
          message: "`precedes` must be a boolean, the largest line number of the following blocks, or their widest number (as content).",
        )
        // The widest number of the following blocks, the number column being wide enough for it
        let widest-number = if type(precedes) == int {
          formatting.shown-number(number, precedes)
        } else if type(precedes) in (str, content) { precedes }
        let precedes = precedes != false
        // An integer is the last line of the preceding block, the lines are numbered from the next one
        if type(follows) == int { number.start = follows + 1 }
        let follows = follows != false
        // The numbers start by default at the first line of the code (in its file)
        if number.start == auto { number.start = first-line }

        // Basic formatting
        lang-tag.visible = lang-tag.visible and it.lang != none
        // The lang tag is removed from the open sides
        if (
          follows
            and (
              lang-tag.placement in ("code", "inline", "header")
                or lang-tag.placement.starts-with("top")
            )
        ) { lang-tag.visible = false }
        if precedes and lang-tag.placement.starts-with("bottom") {
          lang-tag.visible = false
        }
        frame = formatting.frame(frame, lang-tag, with-default-thickness)
        lang-tag = formatting.lang-tag(
          lang-tag,
          it.lang,
          frame,
          header,
          with-default-thickness,
        )
        let (is-top, is-left, is-right, is-bottom) = {
          if lang-tag.visible and lang-tag.on-frame {
            formatting.lang-tag-position(lang-tag)
          } else {
            (none, none, none, none)
          }
        }
        code = formatting.code(code, with-default-thickness)

        // Numbers and markers (the lines skipped by the jumps are not shown)
        number.visible = number.format != none
        let (jumps, jumps-map) = formatting.jumps(
          jumps,
          number,
          skip-lines: jump.skip-lines,
        )
        let nbr-lines = it.lines.len() - formatting.nbr-skipped(jumps)
        number = formatting.number(
          number,
          nbr-lines,
          jumps,
          code,
          with-default-thickness,
        )
        let (line-numbers, line-index, kept) = formatting.line-numbers(
          number,
          it.lines.len(),
          jumps,
          jumps-map,
        )
        // Coloring
        (number, code) = formatting.coloring(
          number,
          code,
          general,
          frame,
          line-numbers,
          nbr-lines,
        )
        // (the lang tag being in the color of the code of the first line by default)
        if lang-tag.color == auto { lang-tag.color = (code.color)(0) }
        lang-tag.block = formatting.lang-tag-block(it.lang, lang-tag, frame)

        // Comments
        let single-comment(c, g, k) = (
          formatting.single-comment(
            c,
            g,
            k,
            number,
            code,
            base-style,
            with-default-thickness,
          )
        )
        let jump-comments = formatting.jump-comments(
          jumps,
          jump,
          comment,
          line-index,
          single-comment,
        )
        let comments = formatting.comments(
          comments,
          comment,
          line-numbers,
          single-comment,
        )
        comments = jump-comments + comments

        // Markers
        let marker = formatting.marker(general, number, code)
        let (number-markers, markers, marker) = formatting.markers(
          cf.parse-markers(markers, line-index, line-numbers),
          comments,
          marker,
        )
        number = formatting.number-cells(
          number,
          general,
          number-markers,
          line-numbers,
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

        // The open sides have no radius and no stroke, the header and footer are only shown if they repeat
        if follows {
          if not header.repeat { header.content = none }
          header.radius = (:)
          frame.radius.top-left = 0pt
          frame.radius.top-right = 0pt
          frame.stroke.top = none
        }
        if precedes {
          if not footer.repeat { footer.content = none }
          footer.radius = (:)
          frame.radius.bottom-left = 0pt
          frame.radius.bottom-right = 0pt
          frame.stroke.bottom = none
        }
        (frame, header, footer) = formatting.frame-block(frame, header, footer)

        // Lines & highlights (the highlights are on all the lines of the code, the shown ones being kept)
        let code-lines = formatting.lines(it, code)
        let it-lines = kept.map(i => code-lines.at(i))
        let highlights = formatting.highlights(
          manual-highlights,
          highlights,
          code-lines,
          n => kept.at(line-index(n)),
          with-default-thickness,
        )

        // Available width

        let char-width = measure("#").width

        let (numbers-width, markers-width) = me.numbers-markers-width(
          number,
          marker,
          widest: widest-number,
          monotonic: type(number.format) != function,
        )

        // The width of the columns before the code
        let pre-width = numbers-width + markers-width

        lang-tag.insert(
          "width",
          if lang-tag.visible and lang-tag.in-code {
            measure(lang-tag.block).width + lang-tag.code-spacing.to-absolute()
          },
        )

        let code-width = me.available-code-width(
          layout-size,
          frame,
          code,
          pre-width,
        )
        let max-code-width = code-width

        // Comments position
        comments = formatting.comments-position(
          comments,
          it-lines,
          code,
          pre-width,
          marker.inset,
          char-width,
        )

        // Break lines in sub-lines
        code-lines = formatting.break-lines(
          code-lines,
          code-width,
          lang-tag,
          char-width,
          indented: code.indented-line-return,
        )
        it-lines = kept.map(i => code-lines.at(i))

        // Width

        (header, footer) = formatting.align-header-footer(
          header,
          footer,
          pre-width,
        )

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

        code-width = me.tight-code-width(
          frame,
          code-width,
          lang-tag,
          it-lines,
          char-width,
        )
        code-width = me.hf-code-width(
          header-width,
          pre-width,
          code,
          code-width,
          footer-width,
        )
        code-width = me.comments-code-width(
          frame,
          comments,
          code,
          code-width,
          max-code-width,
        )
        if frame.width == auto {
          frame.width = (
            pre-width + code.inset.left + code-width + code.inset.right
          )
        }

        // Height

        let char-height = measure("#").height
        let it-lines-height = it-lines.map(l => (
          l.slines.len() * (char-height + code.line-spacing)
        ))

        // Comments size
        let comments-map = formatting.comments-by-gap(
          comments,
          code,
          code-width,
          number,
          numbers-width,
          marker,
          markers-width,
          nbr-lines,
        )

        // Highlights by line
        let highlights-map = formatting.kept-highlights(
          formatting.highlights-by-line(
            highlights,
            code-lines,
            code-width,
            code,
            char-width,
          ),
          kept,
        )

        // Rendering

        let frame-content = re.render(
          nbr-lines,
          number,
          numbers-width,
          code,
          it-lines,
          code-width,
          it-lines-height,
          frame,
          header,
          footer,
          lang-tag,
          lang-tag.block,
          char-width,
          char-height,
          highlights-map,
          comments-map,
          marker: marker,
          markers-width: markers-width,
          markers: markers,
          id: id,
        )

        let frame-block = block(
          fill: frame.block.fill,
          radius: frame.block.radius,
          stroke: frame.block.stroke,
          clip: not frame.sharp-page-break,
          sticky: lang-tag.visible and lang-tag.on-frame and is-bottom,
          width: frame.width,
          height: frame.height,
          breakable: frame.breakable,
          frame-content,
        )

        if lang-tag.visible and lang-tag.on-frame {
          if is-left or is-right {
            block({
              re.place-frame-lang-tag(lang-tag, lang-tag.block)
              frame-block
            })
          } else {
            let alignment = re.lang-tag-alignment(lang-tag)
            lang-tag.block = block(
              width: frame.width,
              sticky: is-top,
              above: if is-bottom { 0mm } else { auto },
              below: if is-top { 0mm } else { auto },
              align(alignment, lang-tag.block),
            )
            if is-top {
              lang-tag.block
              frame-block
            } else {
              frame-block
              lang-tag.block
            }
          }
        } else {
          frame-block
        }
      }
    })
  }
}

/// Display raw code.
///
/// - args (arguments): The settings (see `uraw-set`), and the content whose raw blocks are displayed, or some code read from a file with `read-code` (or given by its `path`).
/// - markers (array, dictionary): The markers of the lines, shown in the marker column (when it is visible), as `(line, content)` or `(line: line, content: content)` on the displayed line numbers. A single one can be given instead of an array.
/// - highlights (array, dictionary): The highlights of the code, given by `line`, `range`, or `start` and `end`, and some `highlight` settings (a predefined highlight can be spread in it, e.g. `..highlights.alert()`, its delimiters being ignored). A single one can be given instead of an array.
/// - comments (array, dictionary): The comments of the code, as `(line, content)` (after the line) or a dictionary with `after` or `before` (a line), `content`, and any `comment` setting except `style` (the content being styled directly). The comment starts (`indent`) at the left of the frame (`"frame"`), at the start of the code (`"code"`), at the indentation of the commented line (`"line"`), or there with the indentation guides (`"guideline"`). The marker of a comment (`marker`) is shown in the gutter, in the marker column or the number column (`placement`: `"markers"` or `"numbers"`, the marker column when the numbers are hidden). An empty marker (`marker: []`) keeps the gutter beside the comment, so that its separator is not interrupted. The separators of the comment (`sep`: a stroke, `(top: stroke, bottom: stroke)` or `none`) are drawn inside its top and bottom sides, against code lines and comments without separator on this side (not between two comments with separators, nor against the frame, the header or the footer). The fill of the gutter beside the comment (`marker-fill`) is the number fill of the commented line when `none`, and when `auto`, the fill of the comment, or the number fill of the commented line if the comment has no fill. A single one can be given instead of an array.
/// - jumps (array, dictionary): The jumps of the number, as `(from, to)` or a dictionary with `from`, `to`, `skip-lines`, and any `jump` setting except `comment-style`. A jump skipping its lines (`skip-lines: true`) does not show the lines between `from` and `to` (which are in the code), instead of only jumping their numbers. A single one can be given instead of an array.
/// - follows (bool, int): Wether the block continues a previous one, as after a page break: its top has no radius and no stroke, the header is only shown if it repeats, and the lang tag is removed if it is on the top (in the header, in the first line of code, or on the top of the frame). An integer is the number of the last line of the preceding block, the lines of this block being numbered from the next one (overriding `start`).
/// - precedes (bool, int, content): Wether the block is continued by a next one, as before a page break: its bottom has no radius and no stroke, the footer is only shown if it repeats, and the lang tag is removed if it is on the bottom of the frame. An integer is the largest line number of the following blocks (the number format being applied to it) and content is their widest number (or marker): the number column is made wide enough for it, so that it has the same width in the following blocks.
/// -> content
#let uraw(
  ..args,
  markers: (),
  highlights: (),
  comments: (),
  jumps: (),
  doc,
) = {
  let (doc, first-line) = cf.code-input(doc)
  // Settings given by section or flat (e.g. `header-fill`)
  let args = cf.normalize-settings(args.named(), cf.uraw-spec)

  /// The show rules displaying the raw blocks, with the function giving the text style of the headers, footers, and comments.
  let with-base-style(base-style) = {
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

    show raw.where(block: true): it => context {
      set text(1.25em)

      // The default values of the highlights
      let highlight = cf.category-parser("highlight", args, it.lang)

      // Reading highlights from the raw text
      let pre-highlights = cf.uncontext-category-getter("highlights", none)
      let formatted-pre-highlights = pre-highlights
        .values()
        .map(h => hl.format-pre-highlight(h, highlight))
      let (dels, lines) = hl.parse-delimiters(
        it.lines.map(l => l.text),
        formatted-pre-highlights,
      )
      let delimited-highlights = dels.map(del => hl.make-highlight(
        formatted-pre-highlights.at(del.idx),
        del,
      ))
      let manual-highlights = ut
        .single-to-list(highlights)
        .map(h => hl.format-highlight(h, highlight))

      // The raw element without the highlights delimiters is the one displayed
      show <uraw-code>: code-it => raw-to-uraw(
        args,
        markers,
        manual-highlights,
        delimited-highlights.map(h => hl.format-highlight(h, highlight)),
        comments,
        jumps,
        base-style,
        first-line,
        code-it,
      )

      // (`auto` keeps the theme of the original raw element)
      let theme = cf.category-parser("code", args, it.lang).theme
      if theme == auto { theme = it.theme }
      [#raw(
        lang: it.lang,
        theme: theme,
        lines.join("\n", default: ""),
      )<uraw-code>]
    }

    doc
  }

  // The style outside of the raw environments, used by the headers, footers and comments:
  // - for a whole document (`#show: uraw`), it is read directly, which costs no layout pass,
  // - for a raw block (which can be the body of a figure, whose kind is detected only if the raw block is not in a context), it is stored in a state
  if type(doc) == content and doc.func() == raw {
    context {
      let style = cf.outside-style()
      cf.uraw-style.update(styles => styles + (style,))
    }
    with-base-style(cf.base-style)
    cf.uraw-style.update(styles => styles.slice(0, -1))
  } else {
    context {
      let style = cf.outside-style()
      with-base-style(() => style)
    }
  }
}
