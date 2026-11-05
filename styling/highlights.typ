// -----------------------------------------------------------------------------
// Style
// -----------------------------------------------------------------------------

#let base-style(color) = (
  fill: color.transparentize(70%),
  stroke: color,
)

#let base(color: yellow) = (
  ldel: "*|",
  rdel: "|*",
  ..base-style(color),
)

#let square-style(color) = (
  radius: 0pt,
  fill: color,
  stroke: none,
)

#let alert-style(color) = (
  radius: 0pt,
  fill: color,
  code-style: it => strong(text(fill: white, it)),
)

#let alert(color: red) = (
  ldel: "*!",
  rdel: "!*",
  ..alert-style(color),
)

#let hole(color: black) = (
  ldel: "*?",
  rdel: "?*",
  code-style: std.hide,
  stroke: (paint: color, dash: "dashed"),
  fill: none,
)

#let strike(color: red) = (
  ldel: "*-",
  rdel: "-*",
  code-style: std.strike.with(stroke: 1.5pt + color),
  stroke: none,
  fill: none,
)

#let underline(color: black) = (
  ldel: "*_",
  rdel: "_*",
  code-style: std.underline.with(offset: 1.5pt, stroke: 1pt + color),
  stroke: none,
  fill: none,
)

#let strong = (
  del: "***", // Third * needed for Typst code
  code-style: std.strong,
  stroke: none,
  fill: none,
)

// -----------------------------------------------------------------------------
// Management
// -----------------------------------------------------------------------------

#import "../src/highlight.typ" as hl

/// The highlights defined by delimiters, by name.
#let highlights-state = state("uraw-highlights", (base: base(), alert: alert()))

/// Add highlights by name, a highlight replacing the one with the same name. A highlight has delimiters (`ldel` and `rdel`, or `del` when they are the same) and some `highlight` settings.
///
/// -> content
#let add(..args) = {
  assert(args.pos().len() == 0, message: "The highlights are given by name.")
  let added = args
    .named()
    .pairs()
    .map(((name, h)) => (name, hl.pre-highlight(h)))
    .to-dict()
  highlights-state.update(hls => {
    let hls = hls + added
    let _ = hl.check-pre-highlights(hls)
    hls
  })
}

/// Remove highlights by name.
///
/// -> content
#let remove(..names) = highlights-state.update(hls => {
  for name in names.pos() { let _ = hls.remove(name, default: none) }
  hls
})

/// The settings of a highlight (in a context).
///
/// - name (str):
/// -> dictionary
#let get(name) = {
  let hls = highlights-state.get()
  assert(name in hls, message: "There is no highlight `" + name + "`.")
  hls.at(name)
}

/// The highlights by name (in a context).
///
/// -> dictionary
#let list() = highlights-state.get()
