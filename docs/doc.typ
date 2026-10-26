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
    target: selector(heading).before(<library>),
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

#page(margin: 1cm)[

  #uraw-add-highlights(
    safety: (
      ldel: "*$",
      rdel: "$*",
      ..highlights.default-style(olive.lighten(70%)),
      lined: true,
    ),
  )

  #let b(body: none, color: orange) = box(
    width: .7em,
    height: .7em,
    stroke: color,
    body,
  )
  #let ls(color) = align(center, line(
    angle: 90deg,
    length: 2mm,
    stroke: (
      paint: color,
      dash: "dotted",
    ),
  ))
  #let ll(color) = align(center, line(
    angle: 90deg,
    length: .7em + 4mm,
    stroke: (
      paint: color,
      dash: "dotted",
    ),
  ))
  #let ss(color: black) = stack(
    dir: ttb,
    b(color: color),
    ls(color),
    b(color: color),
  )
  #let sl(color: black) = stack(
    dir: ttb,
    b(color: color),
    ll(color),
    b(color: color),
  )
  #let st(color: black) = align(top, stack(
    dir: ttb,
    spacing: 2mm,
    b(color: color),
    b(color: color),
  ))

  #uraw-set(
    "typ",
    frame-stroke: 1pt + luma(230),
    frame-radius: 1mm,
    header-fill: luma(230),
    line-spacing: 0.8em,
    lang-tag-size: 1em,
    lang-tag-fill: teal.lighten(80%),
  )

  #grid(
    columns: (1fr, auto),
    column-gutter: 1cm,

    uraw-pseudo(
      header: [*Algorithm* Merge],
      no-number[*Procedure* MERGE($L_1$, $L_2$)],
      no-number[*Input* $L_1$ and $L_2$ two sorted list to merge into a sorted one],
      [$n <-$ the length of $L_1$ $+$ the length of $L_2$],
      [$L_1 <- L_1 + [$_inf_$]$],
      [$L_2 <- L_2 + [$_inf_$]$],
      [$L <- []$],
      [*for* \_ $= 1$ *to* $n$ *do*],
      indent(
        [*if* $L_1."first"() <= L_2."first"()$ *then*],
        indent[$L <- L + [L_1."pop"(0)]$],
        [*else*],
        indent[$L <- L + [L_2."pop"(0)]$],
        [*end if*],
      ),
      [*end for*],
      [*return* $L$],
    ),

    uraw(
      header: [The Merge Sort algorithm],
      highlights: (
        (
          line: (7, 11),
          ..highlights.default-style(orange.lighten(70%)),
          lined: true,
          expand: left,
          // TODO put back the stroke for highlights ?
          // TODO `highlight` setting for `uraw` that lets the user determine the default settings for a highlight
        ),
      ),
      comments: (
        (
          after: 4,
          content: [Safety condition to avoid out of bounds indices],
          in-code: true,
          indented: true,
          fill: none,
          style: text.with(style: "italic", olive),
        ),
        (
          after: 11,
          content: [
            Construction of $L$:
            #grid(
              columns: 30,
              column-gutter: (2mm, 0mm),
              align: bottom,
              stack(dir: ttb, spacing: 2mm, [$L_1$:], [$L_2$:], [$L$:]),
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
          ],
          in-code: true,
        ),
        (
          after: 14,
          content: [$O($`l1.len()` $+$ `l2.len()`$)$],
          marker: octique-inline("stopwatch"),
        ),
        (
          after: 21,
          content: [$O(h dot log(h))$],
          marker: octique-inline("stopwatch"),
          indented: true,
        ),
        (
          after: 22,
          content: [$O(h dot log(h))$],
          marker: octique-inline("stopwatch"),
          indented: true,
        ),
        (
          after: 24,
          // TODO: the height of the comment block is not right
          content: [$O(2 h dot log(h) + (h + h)) = O(n dot log(n))$ #text(
              olive,
            )[*✓*]],
          marker: octique-inline("stopwatch"),
        ),
      ),
      ```typ
      #let merge(l1, l2) = {
        let n = l1.len() + l2.len()
        *$l1.push(calc.inf)
        l2.push(calc.inf)$*
        let l = ()
        for _ in range(n) {
          if l1.first() <= l2.first() {
            l.push(l1.remove(0))
          } else {
            l.push(l2.remove(0))
          }
        }
        return l
      }

      #let merge-sort(l) = {
        if l.len() <= 1  { return l }
        let h = int(l.len() / 2)
        let l1 = l.slice(0, h)
        let l2 = l.slice(h)
        l1 = merge-sort(l1)
        l2 = merge-sort(l2)
        return merge(l1, l2)
      }
      ```,
    ),
  )

  #uraw-reset-highlights()

  #uraw-diff(
    header: [`merge-sort` correction],
    // columns: auto,
    column-gutter: 1cm,
    sep: 1pt + luma(230),
    comments: (
      (
        after: 1,
        content: [test a1],
        version: "old",
      ),
      (
        after: 1,
        content: [test a2],
        version: "old",
      ),
      (
        before: 2,
        content: [test b1],
        version: "old",
      ),
      (
        before: 2,
        content: [test b1],
        version: "new",
      ),
      (
        before: 2,
        content: [test b2],
        version: "new",
      ),
      (
        after: 1,
        content: [test a1],
        version: "new",
      ),
      // TODO: no frame adaptation for uraw diff page break
      // TODO: check that comment matching is right
    ),
    ```typ
    #let merge-sort(l) = {
      if l.len() <= 1 { return l }
      let h = int(l.len() / 2)
      let l1 = l.slice(0, h)
      let l2 = l.slice(h)
      l1 = merge-sort(l1)
      l2 = merge-sort(l2)
      return merge(l1, l2)
    }
    ```,
    ```typ
    #let merge-sort(l) = {
      if l.len() == 0 { return () }
      if l.len() == 1 { return (l.first()) }
      let h = int(l.len() / 2)
      let l1 = l.slice(0, h)
      let l2 = l.slice(h)
      l1 = merge-sort(l1)
      l2 = merge-sort(l2)
      return merge(l1, l2)
    }
    ```,
  )

  #uraw-reset("typ")
]

#let merge(l1, l2) = {
  let n = l1.len() + l2.len()
  l1.push(calc.inf)
  l2.push(calc.inf)
  let l = ()
  for _ in range(n) {
    if l1.first() <= l2.first() {
      l.push(l1.remove(0))
    } else {
      l.push(l2.remove(0))
    }
  }
  return l
}

#let merge-sort(l) = {
  if l.len() <= 1 { return l }
  let h = int(l.len() / 2)
  let l1 = l.slice(0, h)
  let l2 = l.slice(h)
  l1 = merge-sort(l1)
  l2 = merge-sort(l2)
  return merge(l1, l2)
}

// #let merge-sort(l) = {
//   if l.len() <= 1 {
//     return l
//   }

//   let h = int(l.len() / 2)
//   let l1 = l.slice(0, h)
//   let l1 = merge-sort(l1)
//   let l2 = l.slice(h)
//   let l2 = merge-sort(l2)

//   let new-l = ()
//   for _ in l {
//     let e = if (
//       l2.len() == 0 or (l1.len() > 0 and l1.first() <= l2.first())
//     ) {
//       l1.remove(0)
//     } else {
//       l2.remove(0)
//     }
//     new-l.push(e)
//   }

//   return new-l
// }

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
  numbering-sep: .05em + black,
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

#v(1cm)

#context grid(
  columns: (1fr, auto),
  column-gutter: 3mm,
  row-gutter: par.spacing,
  align: (left, bottom),

  align(center)[*Source code*], align(center)[*Produced pdf*],

  [#source(raw(block: true, import-str), width: 100%) <import-code>], [],

  grid.cell(colspan: 2)[Change the raw blocks with the #f("uraw") show rule:],

  [
    #source(
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
      continues: <import-code>,
      width: 100%,
    ) <show-rule-code>
  ],

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

  [
    #source(
      ````typ
      #uraw(
        frame-stroke: luma(240),
        frame-radius: 1mm,

        indent-size: 4,
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
      continues: <show-rule-code>,
      width: 100%,
    ) <local-use-code>
  ],

  [
    #uraw(
      indent-size: 4,
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

    #v(.5em)
  ],

  grid.cell(
    colspan: 2,
  )[Global configurations can be set with the function #f("uraw-set"):],

  [
    #source(
      ````typ
      #uraw-set(
        width: 6.5cm,
        frame-stroke: 1pt + purple,
        frame-radius: (right: 2mm),

        numbering-color: white,
        numbering-fill: purple,

        indent-size: 4,
        code-fill:
          n => purple.lighten(80% + n * 5%),

        lang-tag: none,
      )

      ```py
      def main():
          print("Hello")
          print("World")
      ```
      ````,
      continues: <local-use-code>,
      width: 100%,
    ) <uraw-set-code>
  ],

  [
    #show: uraw

    #uraw-set(
      width: 6.5cm,
      indent-size: 4,
      frame-stroke: 1pt + purple,
      frame-radius: (right: 2mm),
      numbering-color: white,
      numbering-fill: purple,
      code-fill: n => purple.lighten(80% + n * 5%),
      lang-tag: none,
    )

    ```py
    def main():
        print("Hello")
        print("World")
    ```

    #uraw-reset()

    #v(1.35em)
  ],
)

= Raw blocks

#let frame-col = rgb("#1B6393")
#let hf-col = rgb("#AC397E")
#let num-col = rgb("#C5283D")
#let code-col = rgb("#FFC857")
#let lang-col = rgb("#E9724C")

#figure(
  uraw(
    frame-stroke: 2pt + frame-col,
    header: text(white)[Header],
    header-fill: hf-col,
    header-sep: none,
    footer: text(white)[Footer],
    footer-fill: hf-col,
    footer-sep: none,
    numbering-color: white,
    numbering-fill: num-col,
    code-fill: code-col,
    indentation: code-col.darken(20%),
    lang-tag: text.with(white),
    lang-tag-fill: lang-col,
    lang-tag-stroke: 2pt + lang-col,
    ```typ
    #let my-box(body) = box(
      stroke: purple,
      body,
    )
    ```,
  ),
  caption: [The differents components of an #f("uraw") block.],
) <uraw-block-components>

A block of raw text formatted by #f("uraw") is made of several components. They are all colored differently in @uraw-block-components and their name will be underlined with the corresponding color. The #underline(offset: 2pt, stroke: 2pt + frame-col)[frame] is the box containg the whole block. It controls for example the dimension of the block or wether it can break from one page to another. The #underline(offset: 2pt, stroke: 2pt + code-col)[code] part contains the raw text and controls parameters such as the indentation lines or the line spacing. Numbers and their style are controled via the #underline(offset: 2pt, stroke: 2pt + num-col)[numbering] setting. A #underline(offset: 2pt, stroke: 2pt + hf-col)[header] and a #underline(offset: 2pt, stroke: 2pt + hf-col)[footer] for the block can be added. The #underline(offset: 2pt, stroke: 2pt + lang-col)[lang tag] indicates which coding language is used.

The different parameters of the #f("uraw") function can be inspected #link(<uraw-lib>)[here].

// TODO: do we discard `color` and `format` to only keep `style`

= Highlighting

The #ultraw package provides a simple and efficient highlighting that enables one to define highlights directly inside the raw text.



= Labels and reference

= Pseudo code

= Diffs

// --- Library -----------------------------------------------------------------

#pagebreak()

= Library <library>

#let alert(body) = grid(
  columns: 2,
  column-gutter: 2mm,
  octique("alert"), body,
)

#alert[
  Before going any further, a note about arguments of functions of this package (#f("uraw"), #f("uraw-set"), etc) must be made. Most arguments are grouped by categories (`frame`, `numbering`, etc) to which they refer to. Such arguments can be given under two form: a *grouped form* or a *direct form*. The grouped form groups arguments of the same category together while the direct form points to the arguments directly as follow:

  #align(center, grid(
    columns: 2,
    column-gutter: 1cm,
    row-gutter: 5mm,
    align: center,
    [*Grouped form*], [*Direct form*],
    uraw-inline(`#uraw-set(*|frame|*: (*|fill|*: purple))`),
    uraw-inline(`#uraw-set(*|frame-fill|*: purple)`),
  ))

  Look at the #link(<args-forms-table>)[Arguments forms table] for a precise correspondence between grouped and direct forms of arguments.
]

= `uraw` <uraw-lib>

= Arguments forms table <args-forms-table>

== #f("uraw") <uraw-args-forms-table>

#stack(dir: ltr, spacing: 1fr)[*Grouped form*][*Direct form*]

#align(center, uraw(
  numbering: none,
  code-inset: 0mm,
  indentation: none,
  ```
  frame: (
    breakable....................................................frame-breakable
    fill..............................................................frame-fill
    height................................................................height
    radius..........................................................frame-radius
    stroke..........................................................frame-stroke
    width..................................................................width
  )
  header: (
    alignment...................................................header-alignment
    code-aligned.............................................header-code-aligned
    fill.............................................................header-fill
    height.........................................................header-height
    inset...........................................................header-inset
    repeat.........................................................header-repeat
    sep...............................................................header-sep
  )
  footer: (
    alignment...................................................footer-alignment
    code-aligned.............................................footer-code-aligned
    fill.............................................................footer-fill
    height.........................................................footer-height
    inset...........................................................footer-inset
    repeat.........................................................footer-repeat
    sep...............................................................footer-sep
  )
  numbering: (
    alignment................................................numbering-alignment
    color........................................................numbering-color
    end......................................................................end
    fill..........................................................numbering-fill
    format.............................................................numbering
    inset........................................................numbering-inset
    sep............................................................numbering-sep
    start..................................................................start
  )
  code: (
    fill...............................................................code-fill
    indent-size......................................................indent-size
    indentation......................................................indentation
    inset.............................................................code-inset
    line-spacing....................................................line-spacing
  )
  comment: (
    fill............................................................comment-fill
    in-code......................................................comment-in-code
    indented....................................................comment-indented
    marker........................................................comment-marker
    style..........................................................comment-style
  )
  jump: (
    comment.........................................................jump-comment
    comment-fill...............................................jump-comment-fill
    comment-in-code.........................................jump-comment-in-code
    comment-indented.......................................jump-comment-indented
    comment-marker...........................................jump-comment-marker
    comment-style.............................................jump-comment-style
  )
  lang-tag: (
    code-spacing...........................................lang-tag-code-spacing
    fill...........................................................lang-tag-fill
    format..............................................................lang-tag
    icon...........................................................lang-tag-icon
    mode...........................................................lang-tag-mode
    name...........................................................lang-tag-name
    placement.................................................lang-tag-placement
    radius.......................................................lang-tag-radius
    size...........................................................lang-tag-size
    stroke.......................................................lang-tag-stroke
  )
  ```,
))

== #f("uraw-diff")

Arguments from `frame`, `header`, `footer`, `numbering`, `code`, `comment`, `jump`, and `lang-tag` follow the same pattern as the #link(<uraw-args-forms-table>)[#f("uraw") table].

#stack(dir: ltr, spacing: 1fr)[*Grouped form*][*Direct form*]

#align(center, uraw(
  numbering: none,
  code-inset: 0mm,
  indentation: none,
  ```
  markers: (
    inset..........................................................markers-inset
    sep..............................................................markers-sep
    visible..............................................................markers
  )
  old: (
    fill................................................................old-fill
    marker............................................................old-marker
    number-color................................................old-number-color
    number-fill..................................................old-number-fill
  )
  new: (
    fill....................................................................fill
    marker................................................................marker
    number-color....................................................number-color
    number-fill......................................................number-fill
  )
  ```,
))

== #f("uraw-pseudo")

Arguments from `frame`, `header`, `footer`, `numbering`, and `code` follow the same pattern as the #link(<uraw-args-forms-table>)[#f("uraw") table], except for a specific argument of `code`.

#stack(dir: ltr, spacing: 1fr)[*Grouped form*][*Direct form*]

#align(center, uraw(
  numbering: none,
  code-inset: 0mm,
  indentation: none,
  ```
  code: (
    style..................................................................style
  )
  ```,
))

