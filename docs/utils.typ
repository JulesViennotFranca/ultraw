#import "@preview/octique:0.1.1": *
#import "../export/main.typ": (
  get-uraw, raw-themes, style, themes, uraw, uraw-inline,
)

// -----------------------------------------------------------------------------
// Cosmetic
// -----------------------------------------------------------------------------

#let merge-diagram = {
  let b(body: none, color: orange) = box(
    width: .7em,
    height: .7em,
    stroke: color,
    body,
  )
  let ls(color) = align(center, line(
    angle: 90deg,
    length: 2mm,
    stroke: (
      paint: color,
      dash: "dotted",
    ),
  ))
  let ll(color) = align(center, line(
    angle: 90deg,
    length: .7em + 4mm,
    stroke: (
      paint: color,
      dash: "dotted",
    ),
  ))
  let ss() = stack(
    dir: ttb,
    b(color: gray),
    ls(gray),
    b(color: black),
  )
  let sl() = stack(
    dir: ttb,
    b(color: gray),
    ll(gray),
    b(color: black),
  )
  let st(color: black) = align(top, stack(
    dir: ttb,
    spacing: 2mm,
    b(color: color),
    b(color: color),
  ))

  grid(
    columns: 30,
    column-gutter: (4mm, 0mm),
    align: bottom,
    stack(dir: ttb, spacing: 2mm, [`l1`], [`l2`], [`l`]),
    ss(),
    ss(),
    sl(),
    ss(),
    sl(),
    sl(),
    sl(),
    ss(),
    h(2mm),
    move(dy: -.35em, line(length: 3.5mm, stroke: (dash: "dotted"))),
    h(2mm),
    sl(),
    ss(),
    h(2mm),
    stack(
      move(dx: .35em, line(length: .35em + 1mm, stroke: (
        paint: orange,
        dash: "dotted",
      ))),
      align(center, line(angle: 90deg, length: .7em + 3mm, stroke: (
        paint: orange,
        dash: "dotted",
      ))),
      b(color: orange),
    ),
    h(.35em),
    stack(
      line(angle: 90deg, length: .7em + 2mm, stroke: .5pt + orange),
      v(1.05em + 2mm),
    ),
    stack(
      line(length: 7mm, stroke: .5pt + orange),
      v(.8mm),
      move(dx: .5mm, text(orange)[$<=$?]),
      v(1.2mm),
      line(length: 7mm, stroke: .5pt + orange),
      v(1.05em + 2mm),
    ),
    st(color: orange),
    h(2mm),
    st(),
    st(),
    h(2mm),
    stack(
      line(length: 3.5mm, stroke: (dash: "dotted")),
      v(.7em + 2mm),
      line(length: 3.5mm, stroke: (dash: "dotted")),
      v(1.05em + 2mm),
    ),
    h(2mm),
    st(),
    st(color: olive),
  )
}

#let alert(icon: "alert", color: black, body) = grid(
  columns: 2,
  column-gutter: 2mm,
  move(dy: -2pt, octique(icon, color: color)), body,
)

#let frame-col = purple
#let hf-col = rgb("#6877A1")
#let num-col = rgb("#D88C9A")
#let comment-col = rgb("#99C1B9")
#let code-col = rgb("#F2D0A9")
#let lang-col = rgb("#AF92C9")
#let underline-col(col, body) = underline(offset: 2pt, stroke: 2pt + col, body)

// -----------------------------------------------------------------------------
// Display code
// -----------------------------------------------------------------------------

#let source(code, ..args) = uraw(
  ..themes.note,
  lang-tag-name: "source",
  ..args,
  code,
)

#let fade(alpha, body) = box(inset: 0pt, {
  body
  place(top + left, box(
    outset: (bottom: 3pt, rest: 1pt),
    fill: white.transparentize(alpha),
    hide(body),
  ))
})

#let fade-highlight(alpha) = (
  fill: none,
  stroke: none,
  code-style: it => fade(alpha, it),
)

#let ex-output(code, output-args: (:), ..args) = {
  let output-args = if output-args.len() > 0 {
    let a = output-args.pairs().map(((k, v)) => k + ": " + v + ",").sum()
    (
      "#let uraw = uraw.with("
        + a
        + ")\n#let uraw-diff = uraw-diff.with("
        + a
        + ")\n"
    )
  } else { "" }
  let output = eval(
    mode: "markup",
    "#import \"@preview/ultraw:0.0.1\": *\n"
      + "#import \"utils.typ\": fade, fade-highlight\n\n"
      + output-args
      + "\n\n"
      + code.text,
  )

  uraw(
    ..themes.note,
    lang-tag-name: "source",
    width: 100%,
    frame-inset: (bottom: 0pt, top: 2.5pt, x: 3pt),
    jump-fill: none,
    jump-marker: [],
    jump-indent: true,
    footer-fill: white,
    footer-inset: (x: 5pt, y: 3pt),
    ..args,
    footer: output,
    code,
  )
}

// -----------------------------------------------------------------------------
// Documentation
// -----------------------------------------------------------------------------

#let color-type(type) = if type in ("alignment",) {
  rgb("#A7EAFF")
} else if type in ("arguments", "function", "module") {
  rgb("#D2D4FD")
} else if type in ("array", "dictionary", "bytes") {
  rgb("#FCDFFF")
} else if type in ("auto", "none") {
  rgb("#FFD2CA")
} else if type in ("bool", "int", "length", "relative", "fraction", "ratio") {
  rgb("#FFECBF")
} else if type in ("str", "path") {
  rgb("#D1FFE2")
} else if type in ("content",) {
  rgb("#A6EBE5")
} else if type in ("color", "gradient", "stroke") {
  gradient.linear(
    rgb("#7FD7FB"),
    rgb("#A2F7CF"),
    rgb("#D3F6A2"),
    rgb("#FFED7D"),
    rgb("#FFD489"),
    rgb("#FEAA9A"),
    space: oklch,
  )
} else if type == "tiling" {
  tiling(size: (10pt, 10pt), rect(
    width: 100%,
    height: 100%,
    inset: 0pt,
    fill: rgb("#C5FFFF"),
    {
      place(line(
        start: (0pt, -2.5pt),
        end: (12.5pt, 10pt),
        stroke: calc.sqrt(25 / 2) * 1pt + rgb("#FFD2EC"),
      ))
      line(
        start: (-2.5pt, 5pt),
        end: (5pt, 12.5pt),
        stroke: calc.sqrt(25 / 2) * 1pt + rgb("#FFD2EC"),
      )
    },
  ))
} else {
  panic("Unsupported type.")
}

#let highlight-type(type, to-raw: false) = highlight(
  fill: color-type(type),
  radius: 2pt,
  top-edge: 8.5pt,
  extent: 1pt,
  bottom-edge: -2.5pt,
  text(black, if to-raw { raw(type) } else { type }),
)

#let highlight-types = (
  ldel: "*ht",
  rdel: "ht*",
  fill: none,
  stroke: none,
  code-style: it => if it.trim() != "" {
    it.split().map(highlight-type).join(" ")
  } else { it },
)

#let format-types(types) = (
  types
    .split()
    .map(it => highlight-type(it, to-raw: true))
    .join(text(.8em, luma(150), weight: "bold", ` or `))
)

#let arg(name, types, default: none, body) = block(
  breakable: true,
  below: 1.2em,
)[
  #strong(raw(name))
  #h(5mm)
  #format-types(types)
  #if default != none [
    #h(1fr)
    #text(.9em)[
      #text(luma(100), raw("Default:"))
      #raw(lang: "typc", default)
    ]
  ] \
  #body
]

#let documentation(
  code,
  label: none,
  description: none,
  ..args,
) = {
  let lines = code.text.split("\n")
  let arg-lines = args.pos()
  let args-descr = ()
  let markers = ()

  for ag in arg-lines {
    let (i, name, d) = if type(ag) == array {
      if ag.len() == 2 { (ag.at(0), none, ag.at(-1)) } else { ag }
    } else {
      (ag.line, ag.name, ag.description)
    }

    let line = lines.at(i - 1).trim()

    let arg = if name == none {
      let arg = line.split().first()
      if arg.starts-with("#") { arg = arg.slice(arg.position("(") + 1) }
      if arg.starts-with("..") { arg = arg.slice(2) }
      if arg.ends-with(":") { arg = arg.slice(0, -1) }
      arg
    } else { name }

    let types = line.find(regex("\*ht[\s\S]*ht\*"))
    if types != none { types = types.slice(3, -3) }

    let default = line.find(regex(": [\s\S]*,$"))
    if default != none { default = default.slice(2, -1) }

    if label != none {
      markers.push((
        i,
        link(std.label(label + "-" + arg), octique(
          "search",
          color: blue,
        )),
      ))
    }

    args-descr.push(block(below: 1.2em)[
      #strong(raw(arg)) #(if label != none { std.label(label + "-" + arg) })
      #if types != none [
        #h(2mm)
        #text(.8em, format-types(types))
      ]
      #if default != none [
        #h(1fr)
        #text(.9em)[
          #text(luma(100), raw("Default:"))
          #raw(lang: "typc", default)
        ]
      ] \
      #d
    ])
  }

  source(width: 100%, markers: markers, ..args.named(), code)
  if description != none { description }
  args-descr.join()
}

#let show-highlight(code) = [#code #h(1fr) #uraw-inline(lang: "typ", code)]
#let show-highlight-plus(code, ..args) = box(grid(
  columns: 2,
  column-gutter: 1fr,
  align: horizon,
  code, uraw(..args, raw(code.text, lang: "typ", block: true)),
))
