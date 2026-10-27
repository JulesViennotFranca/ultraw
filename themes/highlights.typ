#let default-style(color) = (
  expand: none,
  radius: .3em,
  fill: color.lighten(70%),
  stroke: color,
  code-style: it => it,
)

#let default(color: yellow) = (
  ldel: "*|",
  rdel: "|*",
  ..default-style(color),
)

#let alert-style(color) = (
  expand: center,
  radius: 0mm,
  fill: color,
  code-style: it => strong(text(fill: white, it)),
)

#let alert(color: red) = (
  ldel: "*!",
  rdel: "!*",
  ..alert-style(color),
)

#let hide-style() = (
  expand: none,
  sticky: true,
  code-style: it => hide(it),
)

#let hide() = (
  ldel: "*~",
  rdel: "~*",
  ..hide-style(),
)

#let strike-style(color) = (
  expand: none,
  sticky: true,
  code-style: it => strike(stroke: .1em + color, it),
)

#let strike(color: red) = (
  ldel: "*-",
  rdel: "-*",
  ..strike-style(color),
)

#let underline-style(color) = (
  expand: none,
  sticky: true,
  code-style: it => underline(offset: .2em, stroke: .1em + color, it),
)

#let underline(color: black) = (
  ldel: "*_",
  rdel: "_*",
  ..underline-style(color),
)
