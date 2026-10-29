#import "@mine/ultraw:0.0.1": *
#import "@preview/octique:0.1.1": *

#show heading: text.with(font: "Geist Mono")
#show heading.where(depth: 1): text.with(30pt)
#show heading.where(depth: 2): text.with(22pt)
#set page(numbering: "1")
#set text(12pt)
#show link: it => underline(stroke: blue, it)
#show ref: it => underline(stroke: blue, it)

#let uraw-version = "0.0.1"

#align(center)[
  #text(font: "Geist Mono", 50pt, weight: "bold")[ultraw] \

  #v(5mm)

  A Typst package for beautiful `raw` text.

  #text(14pt, strong("Version " + uraw-version))
]

#v(2cm)

#grid(
  columns: (1fr, 1fr),
  column-gutter: 1cm,
  outline(
    title: text(22pt)[Guide],
    target: selector(heading).before(<library>, inclusive: false),
    depth: 1,
    indent: 2mm,
  ),
  outline(
    title: text(22pt)[Library],
    target: selector(heading).after(<library>, inclusive: false),
    depth: 1,
    indent: 2mm,
  ),
)

#pagebreak()

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
  let ss(color: black) = stack(
    dir: ttb,
    b(color: color),
    ls(color),
    b(color: color),
  )
  let sl(color: black) = stack(
    dir: ttb,
    b(color: color),
    ll(color),
    b(color: color),
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

#let octique-marker(name, color: black) = move(dy: -.3mm, octique(
  name,
  color: color,
))

#page(margin: 1cm)[
  #set align(horizon)

  #uraw-add-highlights(
    safety: (
      ldel: "*$",
      rdel: "$*",
      ..highlights.default-style(olive),
      sticky: true,
    ),
    red-code: (
      ldel: "*r",
      rdel: "r*",
      code-style: text.with(red),
    ),
  )

  #grid(
    columns: (1fr, auto),
    column-gutter: 1cm,

    [
      #uraw-pseudo(
        width: 100%,
        header: [*Algorithm* Merge Sort],
        no-number[*Procedure* MERGE($L_1$, $L_2$)],
        no-number[*Input* $L_1$ and $L_2$ two sorted list],
        [$n <-$ the length of $L_1$ + the length of $L_2$],
        [$L_1 <- L_1 + [$_inf_$]$],
        [$L_2 <- L_2 + [$_inf_$]$],
        [$L <- []$],
        [*for* \_ $= 1$ *to* $n$ *do*],
        indent(
          [*if* $L_1[0] <= L_2[0]$ *then*],
          indent[$L <- L + [L_1."pop"(0)]$],
          [*else*],
          indent[$L <- L + [L_2."pop"(0)]$],
          [*end if*],
        ),
        [*end for*],
        [*return* $L$],
        no-number[],
        no-number[*Procedure* MERGE-SORT($L$)],
        no-number[*Input* $L$ the list to sort],
        [$n <-$ the length of $L$],
        [*if* $n <= 1$ *then*],
        indent[*return* $L$],
        [*end if*],
        [$h <- n / 2$],
        [$L_1 <- L[{0, 1, ..., h-1}]$],
        [$L_2 <- L[{h, h + 1, ..., n-1}]$ ],
        [$L_1 <-$ MERGE-SORT($L_1$)],
        [$L_2 <-$ MERGE-SORT($L_2$)],
      )

      #set par(spacing: 1cm)

      #uraw(
        width: 100%,
        frame-radius: 0mm,
        frame-stroke: black,
        numbers: none,
        header: [#box(height: 1em, icons.py) `Python IDE`],
        header-fill: silver,
        ```
        *r>>>r* merge_sort([3, 4, 1, 6, 0, 2, 5])
        ... [0, 1, 2, 3, 4, 5, 6]
        ```,
      )
    ],

    uraw(
      frame-stroke: black,
      numbers-sep: black,
      header: [The Merge Sort algorithm implementation in python.],
      header-fill: luma(245),
      comment-fill: luma(245),
      line-spacing: 0.8em,
      lang-tag-size: 1em,
      lang-tag-fill: blue.lighten(80%),
      highlights: (
        (
          line: (7, 10),
          ..highlights.default(color: orange),
          fill: orange.transparentize(80%),
          // expand: left,
          // stroke: none,
          // TODO: test how the highlight separation is with stroke on a less perfomant screen + how are strokes not spanning on the whole length created again?
        ),
      ),
      markers: (15, octique-marker("alert", color: red)),
      comments: (
        (
          after: 4,
          content: text(
            style: "italic",
            olive,
          )[Safety condition to avoid out of bounds indices],
          indent: "guideline",
          marker: [],
          fill: none,
        ),
        (
          after: 5,
          content: [Construction of `l`: #merge-diagram],
          indent: "code",
        ),
        (
          after: 11,
          content: [$O($`l1.len()` $+$ `l2.len()`$)$],
          marker: octique-inline("stopwatch"),
        ),
        (
          after: 19,
          content: [$O(h dot log(h))$],
          marker: octique-inline("stopwatch"),
          indent: "guideline",
        ),
        (
          after: 20,
          content: [$O(h dot log(h))$],
          marker: octique-inline("stopwatch"),
          indent: "guideline",
        ),
        (
          after: 21,
          content: [$O(2 h dot log(h) + (h + h)) = O(n dot log(n))$ #text(
              olive,
            )[*✓*]],
          marker: octique-inline("stopwatch"),
        ),
      ),
      ```py
      def merge(l1, l2):
          n = len(l1) + len(l2)
          *$l1.append(float("inf"))
          l2.append(float("inf"))$*
          l = []
          for _ in range(n):
              if l1[0] <= l2[0]:
                  l.append(l1.pop(0))
              else:
                  l.append(l2.pop(0))
          return l

      def merge_sort(l):
          if len(l) <= 1:
              *!return l!*
          h = int(len(l) / 2)
          l1 = l[:h]
          l2 = l[h:]
          l1 = merge_sort(l1)
          l2 = merge_sort(l2)
          return merge(l1, l2)
      ```,
    ),
  )

  #set par(spacing: 1cm)

  #uraw-diff(
    ..themes.diff-dark,
    header: [`merge_sort` correction],
    comment-fill: luma(80),
    code-fill: luma(50),
    numbers-fill: luma(25),
    numbers-sep: none,
    sep: none,
    line-spacing: 0.8em,
    lang-tag-size: 1em,
    lang-tag-fill: blue.darken(30%),
    columns: (1fr, 1fr),
    comments: (
      (
        before: 2,
        content: [`l` is returned directly when `merge` returns a copy:],
        version: "old",
        indent: "line",
      ),
    ),
    ```py
    def merge_sort(l):
        if len(l) <= 1:
            return l
        h = int(len(l) / 2)
        l1 = l[:h]
        l2 = l[h:]
        l1 = merge_sort(l1)
        l2 = merge_sort(l2)
        return merge(l1, l2)
    ```,
    ```py
    def merge_sort(l):
        if len(l) == 0:
            return []
        elif len(l) == 1:
            return [l[0]]
        h = int(len(l) / 2)
        l1 = l[:h]
        l2 = l[h:]
        l1 = merge_sort(l1)
        l2 = merge_sort(l2)
        return merge(l1, l2)
    ```,
  )

]

// --- Guide -------------------------------------------------------------------

#let ultraw = [*`ultraw`*]
#let f(body) = box(
  fill: luma(230),
  outset: (y: 2pt, x: 1pt),
  radius: 2pt,
  raw(body),
)

#let source(code, ..args) = uraw(
  frame-fill: luma(250),
  frame-stroke: .05em + black,
  code-inset: (x: 1.6mm, y: 0.25em),
  numbers-sep: .05em + black,
  lang-tag-fill: auto,
  lang-tag-stroke: auto,
  lang-tag-placement: "top-right",
  lang-tag-name: "source",
  ..args,
  raw(block: code.block, lang: "typ", code.text),
)

= Usage

#ultraw provides a highly customizable formatting of raw text.

#let import-str = ("#import \"@preview/ultraw:" + uraw-version + "\": *")

#v(5mm)

#context grid(
  columns: (1fr, auto),
  column-gutter: 3mm,
  row-gutter: par.spacing,
  align: (left, bottom),

  align(center)[*Source code*], align(center)[*Produced pdf*],

  source(
    precedes: 18,
    raw(block: true, import-str),
    width: 100%,
  ),
  [],

  grid.cell(colspan: 2)[Change the raw blocks with the #f("uraw") show rule:],

  source(
    follows: 1,
    precedes: true,
    ````typ
    ```typ
    #let my-box(body) = box(
      stroke: purple,
      body,
    )
    ```

    #show: uraw

    `#let my-text = text.with(purple)`

    ```typ
    #let my-box(body) = box(
      stroke: purple,
      body,
    )
    ```
    ````,
    width: 100%,
  ),

  [
    ```typ
    #let my-box(body) = box(
      stroke: purple,
      body,
    )
    ```

    #v(4.15em)

    #show: uraw

    `#let my-text = text.with(purple)`

    #v(1.5em)

    ```typ
    #let my-box(body) = box(
      stroke: purple,
      body,
    )
    ```

    #v(1.35em)
  ],

  grid.cell(
    colspan: 2,
  )[#f("uraw") can also be called locally for a specific raw block:],

  source(
    follows: 18,
    precedes: true,
    ````typ
    #uraw(
      frame-stroke: luma(240),
      frame-radius: 1mm,

      code-fill:
        n => if calc.even(n) { luma(240) },

      header: [Some Rust code],
      header-fill: auto,

      lang-tag-placement: "header",
      lang-tag-fill: orange.lighten(75%),

      ```rs
      fn main() {
          println!("Hello World!");
      }
      ```,
    )
    ````,
    width: 100%,
  ),

  [
    #uraw(
      frame-stroke: luma(240),
      frame-radius: 1mm,
      code-fill: n => if calc.even(n) { luma(240) },
      header: [Some Rust code],
      header-fill: auto,
      lang-tag-placement: "header",
      lang-tag-fill: orange.lighten(75%),
      ```rs
      fn main() {
          println!("Hello World!");
      }
      ```,
    )

    #v(2.5em)
  ],

  grid.cell(
    colspan: 2,
  )[Global configurations can be set with the function #f("set-uraw"):],

  source(
    follows: 38,
    ````typ
    #set-uraw(
      width: 6.5cm,
      frame-stroke: 1pt + purple,
      frame-radius: (right: 2mm),

      numbers-color: white,
      numbers-fill: purple,

      code-fill:
        n => purple.lighten(80% + n * 5%),

      lang-tag: false,
    )

    ```py
    def main():
        print("Hello")
        print("World")
    ```
    ````,
    width: 100%,
  ),

  [
    #show: uraw

    #set-uraw(
      width: 6.5cm,
      frame-stroke: 1pt + purple,
      frame-radius: (right: 2mm),
      numbers-color: white,
      numbers-fill: purple,
      code-fill: n => purple.lighten(80% + n * 5%),
      lang-tag: false,
    )

    ```py
    def main():
        print("Hello")
        print("World")
    ```

    #reset-uraw()

    #v(1.35em)
  ],
)

= Raw blocks

#let frame-col = purple
#let hf-col = rgb("#6877A1")
#let num-col = rgb("#D88C9A")
#let comment-col = rgb("#99C1B9")
#let code-col = rgb("#F2D0A9")
#let lang-col = rgb("#AF92C9")
#let underline-col(col, body) = underline(offset: 2pt, stroke: 2pt + col, body)

#figure(
  uraw(
    frame-stroke: 2pt + frame-col,
    header: text(white)[Header],
    header-fill: hf-col,
    header-sep: none,
    footer: text(white)[Footer],
    footer-fill: hf-col,
    footer-sep: none,
    numbers-color: white,
    numbers-fill: num-col,
    code-fill: code-col,
    indentation: code-col.darken(20%),
    lang-tag-color: white,
    lang-tag-fill: lang-col,
    lang-tag-stroke: 2pt + lang-col,
    markers: (2, octique-marker("star-fill", color: white)),
    comments: (
      before: 2,
      content: [Add some color],
      fill: comment-col,
      indent: "line",
    ),
    ```typ
    #let my-box(body) = box(
      stroke: purple,
      body,
    )
    ```,
  ),
  caption: [The differents components of an #f("uraw") block.],
) <uraw-block-components>

A block of raw text formatted by #f("uraw") is made of several components. They are all colored differently in @uraw-block-components and their name will be underlined with the corresponding color. The raw text is shown inside of the #underline-col(code-col)[code] part. The #underline-col(num-col)[numbers] and #underline-col(num-col)[markers] are displayed in a gutter on the left. Some #underline-col(comment-col)[comments] may be added to the code, a #underline-col(hf-col)[header] and a #underline-col(hf-col)[footer] can be defined. The #underline-col(lang-col)[lang tag] indicates which coding language is used. Finally, the #underline-col(frame-col)[frame] is the box containg the whole block.

The different parameters of the #f("uraw") function can be inspected #link(<uraw-lib>)[here].

= Highlights

The #ultraw package provides a simple and efficient highlighting that enables one to define highlights directly inside the raw text.

= Comments and jumps

= Pseudo code

= Diffs

= Themes

= Good practices

// --- Library -----------------------------------------------------------------

#pagebreak()

= Library <library>

#let alert(body) = grid(
  columns: 2,
  column-gutter: 2mm,
  octique("alert"), body,
)

#alert[
  Before going any further, a note about arguments of functions of this package (#f("uraw"), #f("set-uraw"), etc) must be made. Most arguments are grouped by categories (`frame`, `numbers`, etc) to which they refer to. Such arguments can be given under two form: a *grouped form* or a *direct form*. The grouped form groups arguments of the same category together while the direct form points to the arguments directly as follow:

  #align(center, grid(
    columns: 2,
    column-gutter: 1cm,
    row-gutter: 5mm,
    align: center,
    [*Grouped form*], [*Direct form*],
    uraw-inline(`#set-uraw(*|frame|*: (*|fill|*: purple))`),
    uraw-inline(`#set-uraw(*|frame-fill|*: purple)`),
  ))

  Look at the #link(<args-forms-table>)[Arguments forms table] for a precise correspondence between grouped and direct forms of arguments.
]

= `uraw` <uraw-lib>

= Arguments forms table <args-forms-table>

== #f("uraw") <uraw-args-forms-table>

#stack(dir: ltr, spacing: 1fr)[*Grouped form*][*Direct form*]

#align(center, uraw(
  numbers: none,
  code-inset: 0mm,
  indentation: none,
  ```
  frame: (
    breakable....................................................frame-breakable
    fill..............................................................frame-fill
    height................................................................height
    radius..........................................................frame-radius
    sharp-page-break............................................sharp-page-break
    stroke..........................................................frame-stroke
    width..................................................................width
  )
  header: (
    alignment...................................................header-alignment
    code-aligned.............................................header-code-aligned
    color...........................................................header-color
    fill.............................................................header-fill
    height.........................................................header-height
    inset...........................................................header-inset
    repeat.........................................................header-repeat
    sep...............................................................header-sep
  )
  footer: (
    alignment...................................................footer-alignment
    code-aligned.............................................footer-code-aligned
    color...........................................................footer-color
    fill.............................................................footer-fill
    height.........................................................footer-height
    inset...........................................................footer-inset
    repeat.........................................................footer-repeat
    sep...............................................................footer-sep
  )
  numbers: (
    alignment..................................................numbers-alignment
    color..........................................................numbers-color
    end......................................................................end
    fill............................................................numbers-fill
    format...............................................................numbers
    inset..........................................................numbers-inset
    sep..............................................................numbers-sep
    start..................................................................start
  )
  code: (
    color.............................................................code-color
    fill...............................................................code-fill
    indentation......................................................indentation
    indent-size......................................................indent-size
    indented-line-return....................................indented-line-return
    inset.............................................................code-inset
    line-spacing....................................................line-spacing
    theme..................................................................theme
  )
  comment: (
    fill............................................................comment-fill
    indent........................................................comment-indent
    marker........................................................comment-marker
    marker-fill..............................................comment-marker-fill
    placement..................................................comment-placement
    style..........................................................comment-style
  )
  jump: (
    comment.........................................................jump-comment
    comment-fill...............................................jump-comment-fill
    comment-indent...........................................jump-comment-indent
    comment-marker...........................................jump-comment-marker
    comment-marker-fill.................................jump-comment-marker-fill
    comment-placement.....................................jump-comment-placement
    comment-style.............................................jump-comment-style
    skip-lines...................................................jump-skip-lines
  )
  highlight: (
    code-style..............................................highlight-code-style
    expand......................................................highlight-expand
    fill..........................................................highlight-fill
    radius......................................................highlight-radius
    sticky......................................................highlight-sticky
    stroke......................................................highlight-stroke
  )
  lang-tag: (
    code-spacing...........................................lang-tag-code-spacing
    color.........................................................lang-tag-color
    fill...........................................................lang-tag-fill
    mode...........................................................lang-tag-mode
    name...........................................................lang-tag-name
    placement.................................................lang-tag-placement
    radius.......................................................lang-tag-radius
    size...........................................................lang-tag-size
    stroke.......................................................lang-tag-stroke
    visible.............................................................lang-tag
  )
  ```,
))

== #f("uraw-diff")

Arguments from `frame`, `header`, `footer`, `numbers`, `code`, `comment`, `jump`, `highlight`, and `lang-tag` follow the same pattern as the #link(<uraw-args-forms-table>)[#f("uraw") table], the general ones adding the following ones.

#stack(dir: ltr, spacing: 1fr)[*Grouped form*][*Direct form*]

#align(center, uraw(
  numbers: none,
  code-inset: 0mm,
  indentation: none,
  ```
  general: (
    blank-fill........................................................blank-fill
    column-gutter..................................................column-gutter
    columns..............................................................columns
    line-reference................................................line-reference
    sep......................................................................sep
  )
  diff-marker: (
    inset......................................................diff-marker-inset
    unchanged..............................................diff-marker-unchanged
    visible..........................................................diff-marker
  )
  old: (
    diff-marker..................................................old-diff-marker
    fill................................................................old-fill
    numbers-color..............................................old-numbers-color
    numbers-fill................................................old-numbers-fill
  )
  new: (
    diff-marker..................................................new-diff-marker
    fill................................................................new-fill
    numbers-color..............................................new-numbers-color
    numbers-fill................................................new-numbers-fill
  )
  ```,
))

== #f("uraw-pseudo")

Arguments from `frame`, `header`, `footer`, `numbers`, and `code` follow the same pattern as the #link(<uraw-args-forms-table>)[#f("uraw") table], except for a specific argument of `code`.

#stack(dir: ltr, spacing: 1fr)[*Grouped form*][*Direct form*]

#align(center, uraw(
  numbers: none,
  code-inset: 0mm,
  indentation: none,
  ```
  code: (
    style..................................................................style
  )
  ```,
))

