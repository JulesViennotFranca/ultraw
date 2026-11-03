#import "@mine/ultraw:0.0.1": code-themes, get-uraw, style, themes, uraw
#import "@preview/octique:0.1.1": *

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

#let octique-marker = style.octique-marker(octique)

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

#let source(code, ..args) = uraw(
  ..themes.note,
  lang-tag-name: "source",
  ..args,
  code,
)

#let source-output(output-code, source-args: (:), hidden-args: (:), ..args) = {
  let nargs = args.named()
  let source-code = (
    "#uraw(\n"
      + nargs
        .pairs()
        .map(((k, v)) => "  " + k + ": " + v + ",\n")
        .sum(default: "")
      + ")"
  )

  let output-code-line = (
    nargs.values().map(v => 1 + v.matches("\n").len()).sum(default: 0) + 1
  )
  let output-block = uraw(
    width: 100%,
    ..nargs.map(v => if v.trim().starts-with("style.") {
      eval("import \"@mine/ultraw:0.0.1\": style\n" + v)
    } else if v.trim().starts-with("code-themes.") {
      eval("import \"@mine/ultraw:0.0.1\": code-themes\n" + v)
    } else { eval(v) }),
    ..hidden-args,
    output-code,
  )

  source(
    width: 100%,
    ..source-args,
    comments: (
      after: output-code-line,
      content: text(style: "normal", output-block),
      fill: white,
      indent: "frame",
    ),
    raw(block: true, lang: "typ", source-code),
  )
}

#let fade(alpha, body) = box(inset: 0pt, {
  body
  place(top + left, box(
    outset: (bottom: 3pt, rest: 1pt),
    fill: white.transparentize(alpha),
    hide(body),
  ))
})

#let fade-string = "#let fade(alpha, body) = box(inset: 0pt, {\n
  body\n
  place(top + left, box(\n
    outset: (bottom: 3pt, rest: 1pt),\n
    fill: white.transparentize(alpha),\n
    hide(body),\n
  ))\n
})"

/// An example: some code, followed by its output in a comment.
///
/// - code (raw): The code of the example.
/// - output-args (dictionary): Arguments given to `uraw` and `uraw-diff` in the example only, as strings (e.g. `(numbers: "none")`).
/// - hidden-prefix1, hidden-prefix2 (str): Code evaluated before the example, without being shown (before and after the output arguments).
/// - hidden-suffix (str): Code evaluated after the example, without being shown (e.g. `#reset-uraw()` after a `set-uraw`).
/// - hidden-raw (bool): Whether the raw blocks of the code (with their delimiters) are skipped. They must not be on the first or last line.
/// - args (arguments): Arguments of the code block (`source`), with its `comments`.
#let example(
  code,
  output-args: (:),
  hidden-prefix1: "",
  hidden-prefix2: "",
  hidden-suffix: "",
  ..args,
) = {
  let args = args.named()
  let comments = args.remove("comments", default: ())
  if type(comments) == dictionary { comments = (comments,) }
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
    "#import \"@mine/ultraw:0.0.1\": *\n\n"
      + hidden-prefix1
      + "\n\n"
      + output-args
      + "\n\n"
      + hidden-prefix2
      + "\n\n"
      + code.text
      + "\n\n"
      + hidden-suffix,
  )
  let jumps = args.remove("jumps", default: ())
  if (
    type(jumps) == dictionary or jumps.len() > 0 and type(jumps.first()) == int
  ) { jumps = (jumps,) }
  source(
    width: 100%,
    code-inset: (bottom: 0pt, top: 2.5pt, x: 3pt),
    jump-comment-fill: none,
    jump-comment-marker: [],
    jump-comment-indent: "guideline",
    ..args,
    jumps: jumps,
    comments: comments
      + (
        (
          after: code.text.split("\n").len(),
          content: std.text(style: "normal", block(width: 100%, output)),
          fill: white,
        ),
      ),
    raw(block: true, lang: "typ", code.text),
  )
}
