/// This module contains the different pre-themes.

#import "raw.typ": *
#import "style.typ": hatch

// -----------------------------------------------------------------------------
// Default
// -----------------------------------------------------------------------------

/// The default pre-theme.
#let pre-default = (
  code: (
    line-spacing: .65em,
    indentation: gray,
    indent-size: auto,
    indented-line-return: true,
    theme: auto,
    color: auto,
    fill: none,
  ),
  numbers: (
    format: auto,
    start: auto,
    end: none,
    color: auto,
    fill: auto,
    gutter: auto,
    align: top + right,
    sep: none,
  ),
  general: (
    coloring-follow-numbers: true,
    default-stroke-thickness: .5pt,
    line-reference: n => ", line " + str(n) + ",",
    markers-over-numbers: false,
  ),
  header: (
    align: left + horizon,
    code-aligned: false,
    color: auto,
    fill: none,
    height: auto,
    inset: 5pt,
    repeat: false,
    sep: auto,
  ),
  footer: (
    align: left + horizon,
    code-aligned: false,
    color: auto,
    fill: none,
    height: auto,
    inset: 5pt,
    repeat: false,
    sep: auto,
  ),
  frame: (
    breakable: true,
    sharp-page-break: true,
    fill: none,
    radius: 1mm,
    stroke: none,
    width: auto,
    inset: (x: 3pt),
  ),
  lang-tag: (
    visible: true,
    color: auto,
    name: auto,
    icon: none,
    fill: luma(230),
    radius: 2pt,
    stroke: auto,
    spacing: 5pt,
    placement: "code",
  ),
  comment: (
    indent: "frame",
    marker: none,
    marker-fill: auto,
    marker-placement: "numbers",
    fill: luma(245),
    style: text.with(style: "italic"),
    sep: none,
  ),
  highlight: (
    expand: auto,
    sticky: auto,
    radius: 3pt,
    fill: none,
    stroke: none,
    code-style: it => it,
  ),
  jump: (
    comment: none,
    indent: auto,
    marker: auto,
    marker-fill: auto,
    marker-placement: auto,
    fill: auto,
    style: auto,
    sep: auto,
  ),
  diff: (
    general: (
      line-reference: (n, version) => ", " + version + " line " + str(n) + ",",
      columns: (auto, auto),
      column-gutter: 0pt,
      blank-fill: hatch(luma(200)),
      sep: gray,
    ),
    diff-marker: (
      visible: true,
      unchanged: [],
    ),
    old: (
      diff-marker: text(red.darken(20%))[-],
      numbers-color: auto,
      numbers-fill: rgb("#FF8B85"),
      fill: red.lighten(75%),
    ),
    new: (
      diff-marker: text(olive)[+],
      numbers-color: auto,
      numbers-fill: rgb("#7CCBA7"),
      fill: rgb("#32C04C").lighten(75%),
    ),
  ),
)

// -----------------------------------------------------------------------------
// Dark
// -----------------------------------------------------------------------------

/// The pre-theme for the dark theme.
#let pre-dark = (
  frame: (fill: luma(25)),
  code: (
    indentation: luma(100),
    theme: typst-dark,
    color: luma(230),
    fill: luma(50),
  ),
  numbers: (fill: none, sep: none),
  comment: (fill: luma(80)),
  lang-tag: (fill: luma(100), stroke: none),
  diff: (
    general: (sep: none),
    old: (
      diff-marker: text(red)[-],
      numbers-fill: rgb("#B80900"),
      fill: red.darken(60%),
    ),
    new: (
      diff-marker: text(olive.lighten(30%))[+],
      numbers-fill: rgb("#348360"),
      fill: olive.darken(45%),
    ),
  ),
)

// -----------------------------------------------------------------------------
// Note
// -----------------------------------------------------------------------------

/// The pre-theme for the note theme.
#let pre-note = (
  frame: (fill: luma(250), stroke: black, inset: (x: 3pt, y: 2.5pt)),
  numbers: (align: top + left, sep: black),
  comment: (style: it => it, sep: auto),
  jump: (sep: none),
  lang-tag: (fill: auto, placement: "top-right"),
  diff: (general: (blank-fill: hatch(black), sep: black)),
)

// -----------------------------------------------------------------------------
// Window
// -----------------------------------------------------------------------------

/// The pre-theme for the window theme.
#let pre-window = (
  frame: (stroke: 1pt + luma(240), radius: 5pt),
  header: (fill: luma(240), sep: none),
  footer: (fill: luma(240), sep: none),
  code: (indentation: silver),
  comment: (fill: luma(245)),
  lang-tag: (placement: "header", fill: luma(240)),
  diff: (general: (sep: 1pt + luma(240))),
)

// -----------------------------------------------------------------------------
// Pseudo
// -----------------------------------------------------------------------------

/// The default pre-theme for `uraw-pseudo`.
#let pseudo-pre-default = (
  general: (
    coloring-follow-numbers: true,
    default-stroke-thickness: .5pt,
    line-reference: n => ", line " + str(n) + ",",
    algorithm-figure: true,
  ),
  frame: (
    breakable: true,
    sharp-page-break: true,
    fill: none,
    radius: (:),
    stroke: (top: 1pt + black, bottom: 1pt + black),
    width: auto,
    inset: (x: .25em),
  ),
  header: (
    align: left + horizon,
    code-aligned: false,
    color: auto,
    fill: none,
    height: auto,
    inset: (y: .4em),
    repeat: false,
    sep: auto,
  ),
  footer: (
    align: left + horizon,
    code-aligned: false,
    color: auto,
    fill: none,
    height: auto,
    inset: (y: .4em),
    repeat: false,
    sep: auto,
  ),
  numbers: (
    format: "1:",
    start: 1,
    end: none,
    color: auto,
    fill: auto,
    gutter: auto,
    align: right,
    sep: none,
  ),
  code: (
    line-spacing: .65em,
    indentation: none,
    indent-size: 15pt,
    style: none,
    color: auto,
    fill: none,
  ),
)
