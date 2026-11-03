#import "code.typ": *
#import "style.typ": hatch

// -----------------------------------------------------------------------------
// Default
// -----------------------------------------------------------------------------

#let pre-default = (
  general: (
    coloring-follow-numbers: true,
    default-stroke-thickness: .5pt,
    line-reference: it => ", line " + str(it),
    markers-over-numbers: false,
  ),
  frame: (
    breakable: true,
    sharp-page-break: true,
    fill: none,
    radius: 1mm,
    stroke: none,
    width: auto,
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
  numbers: (
    format: auto,
    start: auto,
    end: none,
    color: auto,
    fill: auto,
    inset: auto,
    align: top + right,
    sep: none,
  ),
  code: (
    inset: (x: 3pt),
    line-spacing: .65em,
    indentation: gray,
    indent-size: auto,
    indented-line-return: true,
    theme: auto,
    color: auto,
    fill: none,
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
  jump: (
    skip-lines: false,
    comment: none,
    comment-indent: auto,
    comment-marker: auto,
    comment-marker-fill: auto,
    comment-marker-placement: auto,
    comment-fill: auto,
    comment-style: auto,
    comment-sep: auto,
  ),
  highlight: (
    expand: auto,
    sticky: auto,
    radius: 3pt,
    fill: none,
    stroke: none,
    code-style: it => it,
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
  diff: (
    general: (
      line-reference: (k, version) => ", " + version + " line " + str(k),
      columns: (auto, auto),
      column-gutter: 0pt,
      blank-fill: hatch(luma(200)),
      sep: gray,
    ),
    diff-marker: (
      visible: true,
      inset: auto,
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

#let pre-note = (
  frame: (fill: luma(250), stroke: black),
  numbers: (align: top + left, sep: black),
  code: (inset: (x: 3pt, y: 2.5pt)),
  comment: (style: it => it, sep: auto),
  jump: (comment-sep: none),
  lang-tag: (fill: auto, placement: "top-right"),
  diff: (general: (blank-fill: hatch(black), sep: black)),
)

// -----------------------------------------------------------------------------
// Window
// -----------------------------------------------------------------------------


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

#let pseudo-pre-default = (
  general: (
    coloring-follow-numbers: true,
    default-stroke-thickness: .5pt,
    line-reference: it => ", line " + str(it),
    algorithm-figure: true,
  ),
  frame: (
    breakable: true,
    sharp-page-break: true,
    fill: none,
    radius: (:),
    stroke: (top: 1pt + black, bottom: 1pt + black),
    width: auto,
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
    inset: .25em,
    align: right,
    sep: none,
  ),
  code: (
    inset: (x: .25em),
    line-spacing: .65em,
    indentation: none,
    indent-size: 15pt,
    style: none,
    color: auto,
    fill: none,
  ),
)
