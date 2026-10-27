/// The label of the figure being laid out, used to label the lines of the code it contains.
#let uraw-figure = state("uraw-figure", none)

/// The styles outside of the raw environments (one per nested uraw call), used by the headers, footers, and comments.
#let uraw-style = state("uraw-style", ())

/// The current text, paragraph and block settings that the raw blocks and `uraw` change, so that the headers, footers and comments look as they would outside of the raw block.
///
/// -> dictionary
#let outside-style() = (
  text: (
    font: text.font,
    size: text.size,
    hyphenate: text.hyphenate,
    overhang: text.overhang,
  ),
  par: (
    leading: par.leading,
    spacing: par.spacing,
    justify: par.justify,
    first-line-indent: par.first-line-indent,
    hanging-indent: par.hanging-indent,
  ),
  block: (
    above: block.above,
    below: block.below,
    width: block.width,
    height: block.height,
    fill: block.fill,
    stroke: block.stroke,
    inset: block.inset,
    outset: block.outset,
    radius: block.radius,
  ),
)

/// The style of the headers, footers, comments: the one outside of the raw environment (the current one before the state is known).
///
/// -> dictionary
#let base-style() = {
  let styles = uraw-style.get()
  if styles.len() > 0 { styles.last() } else { (text: (:), par: (:), block: (:)) }
}

/// Apply a style saved with `outside-style`.
///
/// - style (dictionary): The text, paragraph and block settings.
/// - body (content):
/// -> content
#let with-style(style, body) = {
  set text(..style.text)
  set par(..style.par)
  set block(..style.block)
  body
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
