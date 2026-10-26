#import "content.typ" as ct
#import "highlight.typ" as hl
#import "state.typ" as st
#import "utils.typ" as ut

/// The position of a manual highlight of inline code: a character position, `(line, character)` being also accepted.
#let inline-position(pos, default) = if pos == auto or pos == none {
  default
} else if type(pos) == int {
  pos
} else if type(pos) == array and pos.len() == 2 and type(pos.last()) == int {
  pos.last()
} else {
  panic(
    "The start and the end of a highlight of inline code must be character positions.",
  )
}

/// The highlights of some inline code, as dictionaries with a `start`, an `end` (character positions, the end being excluded), a `fill`, a `radius` and a `code-style`.
///
/// - manual (array): The manual highlights.
/// - delimited (array): The highlights read from delimiters.
/// - pre-highlights (dictionary): The highlights defined in the settings.
/// - length (int): The length of the code.
/// -> array
#let inline-highlights(manual, delimited, pre-highlights, length) = {
  let simplify(h, start, end) = (
    start: calc.max(0, start),
    end: calc.min(length, end),
    fill: h.at("fill", default: none),
    radius: h.at("radius", default: 0pt),
    code-style: h.at("code-style", default: it => it),
  )

  let delimited = delimited.map(h => simplify(
    h,
    h.range.first().last(),
    h.range.last().last(),
  ))
  let manual = ut
    .single-to-list(manual)
    .map(h => {
      let h = hl.format-highlight-style(h, pre-highlights)
      simplify(
        h,
        inline-position(h.at("start", default: auto), 0),
        inline-position(h.at("end", default: auto), length),
      )
    })

  (delimited + manual).filter(h => h.start < h.end)
}

/// Highlight a line of inline code: it is split at the bounds of the highlights, each part being styled and put in the boxes of the highlights covering it (the later highlights being on top).
///
/// - body (content): The content of the line.
/// - length (int): The length of the line.
/// - highlights (array): The simplified highlights.
/// -> content
#let highlight-inline(body, length, highlights) = {
  if highlights.len() == 0 { return body }

  let bounds = (0, length)
  for h in highlights { bounds += (h.start, h.end) }
  bounds = bounds.dedup().sorted()

  let rest = body
  let result = []
  for k in range(bounds.len() - 1) {
    let (a, b) = (bounds.at(k), bounds.at(k + 1))
    let (part, after) = ct.content-split-pos(rest, b - a)
    rest = after

    let covering = highlights.filter(h => h.start <= a and b <= h.end)
    // (the style functions can return strings, which are converted to content)
    for h in covering { part = [#ct.content-map-text(part, h.code-style)] }
    for h in covering.rev() {
      // The corners are only rounded at the ends of the highlight
      let radius = ut.full-radius(h.radius)
      if a != h.start {
        radius.top-left = 0pt
        radius.bottom-left = 0pt
      }
      if b != h.end {
        radius.top-right = 0pt
        radius.bottom-right = 0pt
      }
      part = box(fill: h.fill, radius: radius, outset: (y: .25em), part)
    }
    result += part
  }
  result
}

/// Display inline code with highlights: the highlights delimiters of `uraw` (`*|...|*`, ...) and manual highlights.
///
/// - body (str, content): The code, as a string or an inline raw element (it can be used in a show rule on inline raw elements).
/// - lang (none, str): The language of the code given as a string.
/// - highlights (array): The manual highlights, with a `start` and an `end` (character positions of the code without delimiters, the end being excluded, the default ones being the start and the end of the code), and a `fill`, a `radius`, a `code-style`, or the `style` of a highlight defined in the settings.
/// -> content
#let uraw-inline(body, lang: none, highlights: ()) = {
  // The code displayed by this function is not displayed again (when it is used in a show rule)
  if (
    type(body) == content and body.at("label", default: none) == <uraw-inline-code>
  ) {
    return body
  }
  assert(
    type(body) == str or (type(body) == content and body.func() == raw),
    message: "`uraw-inline` takes a string or an inline raw element.",
  )
  let (text, lang) = if type(body) == str { (body, lang) } else {
    (body.text, body.at("lang", default: lang))
  }
  // In a show rule, the raw element is already displayed (so its size is applied twice)
  let shown = type(body) == content and body.location() != none

  context {
    let pre-highlights = st.uraw-uncontext-get-highlights(none)
    let phls = pre-highlights.values()
    let (dels, lines) = hl.parse-delimiters(text.split("\n"), phls)
    let delimited = dels.map(del => hl.make-highlight(phls.at(del.idx), del))
    let code = lines.join("\n", default: "")

    // The code is shown as a raw element, to get its highlighted lines
    show <uraw-inline-code>: it => {
      let hls = inline-highlights(
        highlights,
        delimited,
        pre-highlights,
        code.len(),
      )
      // The lines of the code (with their position in the code)
      let start = 0
      let parts = ()
      for l in it.lines {
        let line-hls = hls
          .filter(h => h.start < start + l.text.len() and h.end > start)
          .map(h => h + (
            start: calc.max(0, h.start - start),
            end: calc.min(l.text.len(), h.end - start),
          ))
        parts.push(highlight-inline(l.body, l.text.len(), line-hls))
        start += l.text.len() + 1
      }
      parts.join(linebreak())
    }
    set std.text(if shown { 1.25em } else { 1em })
    [#raw(code, lang: lang, block: false)<uraw-inline-code>]
  }
}
