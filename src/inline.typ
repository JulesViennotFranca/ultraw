#import "content.typ" as ct
#import "highlight.typ" as hl
#import "config.typ" as cf
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
/// - defaults (dictionary): The `highlight` settings, giving the missing style fields of the manual highlights.
/// - length (int): The length of the code.
/// -> array
#let inline-highlights(manual, delimited, defaults, length) = {
  let simplify(h, start, end) = (
    start: calc.max(0, start),
    end: calc.min(length, end),
    fill: h.at("fill", default: none),
    radius: h.at("radius", default: 0pt),
    stroke: h.at("stroke", default: none),
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
      let h = defaults + h
      simplify(
        h,
        inline-position(h.at("start", default: auto), 0),
        inline-position(h.at("end", default: auto), length),
      )
    })

  (delimited + manual).filter(h => h.start < h.end)
}

/// Highlight a line of inline code: it is split at the bounds of the highlights, each part being styled and highlighted by the highlights covering it (the later highlights being on top).
///
/// - body (content): The content of the line.
/// - length (int): The length of the line.
/// - highlights (array): The simplified highlights.
/// - cap-height (length): The height of the capital letters of the code, the highlights going from `.24em` above it to `.25em` below the baseline (as the highlights of raw blocks).
/// - with-dst (function): Give a thickness to the strokes given without one.
/// -> content
#let highlight-inline(body, length, highlights, cap-height, with-dst) = {
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
    // The later highlights wrap the earlier ones, so that they are drawn on top of them
    for h in covering.filter(h => h.fill != none or h.stroke != none) {
      // The corners are only rounded and the sides only stroked at the ends of the highlight
      let radius = ut.full-radius(h.radius)
      let s = with-dst(h.stroke)
      let stroke = if s == none { none } else {
        (top: s, bottom: s, left: s, right: s)
      }
      if a != h.start {
        radius.top-left = 0pt
        radius.bottom-left = 0pt
        if stroke != none { stroke.left = none }
      }
      if b != h.end {
        radius.top-right = 0pt
        radius.bottom-right = 0pt
        if stroke != none { stroke.right = none }
      }
      // (unlike a box, a highlight can be broken across lines)
      part = std.highlight(
        fill: h.fill,
        radius: radius,
        stroke: stroke,
        top-edge: cap-height + .24em,
        bottom-edge: -.25em,
        part,
      )
    }
    result += part
  }
  result
}

/// Display inline code with highlights: the highlights delimiters of `uraw` (`*|...|*`, ...) and manual highlights.
///
/// - body (str, content): The code, as a string or an inline raw element (it can be used in a show rule on inline raw elements).
/// - lang (none, str): The language of the code given as a string.
/// - highlights (array, dictionary): The manual highlights, with a `start` and an `end` (character positions of the code without delimiters, the end being excluded, the default ones being the start and the end of the code), and a `fill`, a `radius`, a `stroke`, a `code-style` (a predefined highlight can be spread in it, e.g. `..highlights.alert()`, its delimiters being ignored). A single one can be given instead of an array.
/// -> content
#let uraw-inline(body, lang: none, highlights: ()) = {
  // The code displayed by this function is not displayed again (when it is used in a show rule)
  if (
    type(body) == content
      and body.at("label", default: none) == <uraw-inline-code>
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
    let highlight = cf.uncontext-category-getter("highlight", lang)
    let pre-highlights = cf.uncontext-category-getter("highlights", none)
    let phls = pre-highlights
      .values()
      .map(h => hl.format-pre-highlight(h, highlight))
    let (dels, lines) = hl.parse-delimiters(text.split("\n"), phls)
    let delimited = dels.map(del => hl.make-highlight(phls.at(del.idx), del))
    let code = lines.join("\n", default: "")

    // The code is shown as a raw element, to get its highlighted lines
    show <uraw-inline-code>: it => context {
      // (the height of a text is the one of its capital letters, measured in the font of the code)
      let cap-height = measure(it.lines.first(default: [])).height
      let thickness = cf
        .uncontext-category-getter("general", lang)
        .default-stroke-thickness
      let with-dst(s) = ut.with-default-thickness(s, thickness)
      let hls = inline-highlights(
        highlights,
        delimited,
        highlight,
        ct.text-len(code),
      )
      // The lines of the code (with their position in the code)
      let start = 0
      let parts = ()
      for l in it.lines {
        let n = ct.text-len(l.text)
        let line-hls = hls
          .filter(h => h.start < start + n and h.end > start)
          .map(h => (
            h
              + (
                start: calc.max(0, h.start - start),
                end: calc.min(n, h.end - start),
              )
          ))
        parts.push(highlight-inline(l.body, n, line-hls, cap-height, with-dst))
        start += n + 1
      }
      parts.join(linebreak())
    }
    set std.text(if shown { 1.25em } else { 1em })
    [#raw(code, lang: lang, block: false)<uraw-inline-code>]
  }
}
