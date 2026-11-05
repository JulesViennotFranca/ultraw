// -----------------------------------------------------------------------------
// Coloring
// -----------------------------------------------------------------------------

#let zebra(odd: none, even: none) = n => if calc.odd(n) { odd } else { even }

#let read-lines(l) = if type(l) == int { (l, l) } else { l }

#let bin-find(l, n) = if l.len() == 0 { false } else if l.len() == 1 {
  if n == l.first() { 0 } else { none }
} else {
  let h = int(l.len() / 2)
  let median = l.at(h)
  if n == median { h } else if n < median {
    bin-find(l.slice(0, h), n)
  } else {
    let r = bin-find(l.slice(h), n)
    if r != none { r + h }
  }
}

#let read-lines-col((l, c)) = (read-lines(l), c)

#let exact(..lines, rest: none) = {
  let lines = lines
    .pos()
    .map(read-lines-col)
    .map((((s, e), c)) => range(s, e + 1).map(i => (line: i, color: c)))
    .flatten()
    .sorted(key: lc => lc.line)
  let (lines, colors) = (lines.map(lc => lc.line), lines.map(lc => lc.color))
  return n => {
    let i = bin-find(lines, n)
    if i != none { colors.at(i) } else { rest }
  }
}

#let focus(..lines, color: black, dim: 60%) = {
  return exact(
    ..lines.pos().map(l => (l, color)),
    rest: color.transparentize(dim),
  )
}

#let hatch(color) = tiling(size: (4pt, 4pt), line(
  start: (0pt, 4pt),
  end: (4pt, 0pt),
  stroke: .3pt + color,
))

// -----------------------------------------------------------------------------
// Numbers
// -----------------------------------------------------------------------------

#let padded(n-bits, n) = {
  let s = str(n)
  if s.len() < n-bits { "0" * (n-bits - s.len()) + s } else { s }
}

#let relative(to, n) = n - to

// -----------------------------------------------------------------------------
// Markers
// -----------------------------------------------------------------------------

#let octique-marker(octique) = (name, color: black) => move(dy: -.07em, octique(
  name,
  color: color,
))

#let callout-marker(body, color: black) = circle(
  radius: .6em,
  stroke: .5pt + color,
  place(center + horizon, text(color, .9em, if type(body) == int {
    str(body)
  } else { body })),
)

#let badge-marker(color: black) = box(height: .8em, align(horizon, circle(
  radius: .3em,
  fill: color,
  stroke: none,
)))

// -----------------------------------------------------------------------------
// Jumps
// -----------------------------------------------------------------------------

#let vdots-jump(from, to, numbers: true, code: false, ..comment) = {
  let jump = comment.named() + (from: from, to: to)
  if numbers {
    jump += (
      marker: $dots.v$,
      marker-placement: "numbers",
      comment: jump.at("comment", default: []),
    )
  }
  if code {
    jump += (comment: $dots.v$, indent: jump.at("indent", default: "line"))
  }
  return jump
}

// -----------------------------------------------------------------------------
// Other
// -----------------------------------------------------------------------------

#let window(body) = stack(
  dir: ltr,
  spacing: 0pt,
  circle(radius: 4pt, fill: rgb("#FF5C5F")),
  h(3pt),
  circle(radius: 4pt, fill: rgb("#FAC800")),
  h(3pt),
  circle(radius: 4pt, fill: rgb("#34C759")),
  h(9pt),
  body,
)
