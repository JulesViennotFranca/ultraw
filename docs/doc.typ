#import "@mine/ultraw:0.0.1": *
#import "@preview/pinit:0.2.2": *
#import "utils.typ": *

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
    // depth: 1,
    indent: 2mm,
  ),
  outline(
    title: text(22pt)[Library],
    target: selector(heading).after(<library>, inclusive: false),
    // depth: 1,
    indent: 2mm,
  ),
)

#pagebreak()

#add-highlights(
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
  blue-code: (
    ldel: "*b",
    rdel: "b*",
    code-style: text.with(rgb("#4C69C6")),
  ),
  rainbow-code: (
    ldel: "*g",
    rdel: "g*",
    code-style: it => box(text(
      fill: gradient.linear(..color.map.rainbow),
      it,
    )),
  ),
  pinit: (ldel: "*p", rdel: "p*", code-style: it => pin(it)),
)

#page(margin: 1cm)[
  #set align(horizon)

  #grid(
    columns: (1fr, auto),
    column-gutter: 1cm,

    [
      #set par(spacing: 1cm)

      #uraw(
        ..themes.note,
        width: 100%,
        highlights: (
          (
            line: (9, 13),
            fill: teal.transparentize(70%),
            stroke: teal.darken(30%),
            expand: left,
          ),
          (line: 15, fill: gradient.linear(..color.map.flare)),
        ),
        ````typ
        = Using the *|ultraw|* package

        // It is as simple as that:
        #show: uraw

        You can now write *gbeautifulg* raw
        text by simply typing it:

        ```rs
        fn main() {
            println!("Hello World!");
        }
        ```

        == Styling

        *|Markers, highlights, or comments|*
        are easily defined. You can even
        write *|pseudo code|* and *|diffs|*.
        ````,
      )

      #uraw-pseudo(
        width: 100%,
        header: [*Algorithm* Merge Sort],
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
    ],

    uraw(
      frame-stroke: 1pt + luma(235),
      // numbers-sep: gray,
      header: [The Merge Sort algorithm's implementation in python.],
      header-fill: luma(235),
      comment-fill: luma(245),
      line-spacing: 0.8em,
      lang-tag-size: 1em,
      lang-tag-fill: blue.lighten(80%),
      highlights: (
        (
          line: (7, 10),
          ..highlights.default(color: orange),
          fill: orange.transparentize(80%),
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
#let urawf = f("uraw")

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
    raw(block: true, lang: "typ", import-str),
    width: 100%,
  ),
  [],

  grid.cell(colspan: 2)[Change the raw blocks with the #urawf show rule:],

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
  )[#urawf can also be called locally for a specific raw block:],

  source(
    follows: 18,
    precedes: true,
    ````typ
    #uraw(
      frame-stroke: luma(240),
      frame-radius: 1mm,

      code-fill:
        style.zebra(even: luma(240)),

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
      code-fill: style.zebra(even: luma(240)),
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

    #uraw(
      width: 6.5cm,
      frame-stroke: 1pt + purple,
      frame-radius: (right: 2mm),
      numbers-color: white,
      numbers-fill: purple,
      code-fill: n => purple.lighten(80% + n * 5%),
      lang-tag: false,
      ```py
      def main():
          print("Hello")
          print("World")
      ```,
    )

    #v(1.35em)
  ],
)

= Raw blocks

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
  caption: [The differents components of an #urawf block.],
) <uraw-block-components>

A block of raw text formatted by #urawf is made of several components. They are all colored differently in @uraw-block-components and their name will be underlined with the corresponding color. The raw text is shown inside of the #underline-col(code-col)[code] part. The #underline-col(num-col)[numbers] and #underline-col(num-col)[markers] are displayed in a gutter on the left. Some #underline-col(comment-col)[comments] may be added to the code, a #underline-col(hf-col)[header] and a #underline-col(hf-col)[footer] can be defined. The #underline-col(lang-col)[lang tag] indicates which coding language is used. Finally, the #underline-col(frame-col)[frame] is the box containg the whole block.

#alert(icon: "info")[
  The precise parameters of the #urawf function can be inspected #link(<uraw-lib>)[here].
]

== Code

Quite some parameters of the code can be set with #urawf, such as appearence (e.g., `theme`, `fill`) or the layout (e.g., `line-spacing`, `indent-size`). Here are some examples illustrating the offered possibilities:

#grid(
  columns: (1fr, 1fr),
  column-gutter: 1cm,

  text(0.8em, source-output(
    hidden-args: (lang-tag: false, numbers: none),
    indentation: "purple",
    indent-size: "1",
    indented-line-return: "false",
    code-color: "olive",
    ```typ
    #let ex(body) = stack(dir: ttb,
      spacing: 2mm,
      [Here is an example I really want to show you:],
      body
    )
    ```,
  )),

  text(0.8em, source-output(
    hidden-args: (lang-tag: false, numbers: none),
    line-spacing: ".88em",
    code-fill: "style.zebra(odd: luma(240))",
    theme: "code-themes.github-light",
    ```typ
    #let ex(body) = stack(dir: ttb,
      spacing: 2mm,
      [Here is an example I really want to show you:],
      body
    )
    ```,
  )),
)

== Numbers & Markers

Numbers indicate the code lines numbers and markers can further decorate each line. They both appear in a gutter on the left of the code. The background of this gutter, the color of numbers and markers, or the starting or ending number can be chose as follow:

#grid(
  columns: (1fr, 1fr),
  column-gutter: 1cm,

  text(0.8em, source-output(
    hidden-args: (
      lang-tag: false,
      indentation: silver,
      highlights: (line: (8, 12), code-style: it => fade(20%, it)),
    ),
    start: "8",
    numbers-align: "left",
    numbers-fill: "\n    style.zebra(even: yellow, odd: aqua)",
    markers: "((10, [•]), (11, [•]))",
    ```typ
    #let ex(body) = stack(dir: ttb,
      spacing: 2mm,
      [Here is an example:],
      body
    )
    ```,
  )),

  text(0.8em, source-output(
    hidden-args: (
      lang-tag: false,
      indentation: silver,
      numbers-align: left,
      highlights: (line: (1, 5), code-style: it => fade(20%, it)),
    ),
    numbers: "\"1.\"",
    numbers-color: "maroon",
    numbers-sep: "1pt + teal",
    markers-over-numbers: "true",
    markers: "(4, $->$)",
    ```typ
    #let ex(body) = stack(dir: ttb,
      spacing: 2mm,
      [Here is an example:],
      body
    )
    ```,
  )),
)

== Header & Footer


Each #urawf block can have a header and a footer. Like `grid`s headers and footers, they can be repeated at each page breaks. Their start can also be aligned with the code block. Here are som examples:

#grid(
  columns: (1fr, 1fr),
  column-gutter: 1cm,

  text(0.8em, source(
    width: 100%,
    precedes: true,
    comments: (
      after: 5,
      content: text(style: "normal", uraw(
        width: 100%,
        lang-tag: false,
        indentation: silver,
        numbers-color: silver,
        highlights: (line: (1, 2), code-style: it => fade(20%, it)),
        header: [Some basic header],
        header-color: blue,
        ```typ
        #let my-box(body) = box(stroke: purple,
          body
        ```,
      )),
      fill: white,
    ),
    ```typ
    *b#urawb*(
      header: [Some basic header],
      header-color: blue,
      header-repeat: true,
    ```,
  )),

  text(0.8em, source(
    width: 100%,
    precedes: true,
    comments: (
      after: 5,
      content: text(style: "normal", {
        uraw(
          width: 100%,
          lang-tag: false,
          indentation: silver,
          numbers-color: silver,
          highlights: (line: (1, 2), code-style: it => fade(20%, it)),
          ```typ
          #let my-box(body) = box(stroke: purple,
            body
          ```,
        )
        v(2.1mm)
      }),
      fill: white,
    ),
    ```typ
    *b#urawb*(
      footer: [Some basic footer],
      footer-fill: purple.lighten(80%),
      footer-sep: 1pt + purple,
      footer-code-aligned: true,
    ```,
  )),

  text(0.8em, source(
    width: 100%,
    follows: 4,
    comments: (
      before: 5,
      content: text(style: "normal", uraw(
        width: 100%,
        start: 3,
        lang-tag: false,
        indentation: silver,
        numbers-color: silver,
        highlights: (line: 3, code-style: it => fade(20%, it)),
        header: [Some basic header],
        header-color: blue,
        ```typ
        )
        ```,
      )),
      fill: white,
    ),
    ```typ
    )
    ```,
  )),

  text(0.8em, source(
    width: 100%,
    follows: 5,
    comments: (
      after: 5,
      content: text(style: "normal", uraw(
        width: 100%,
        start: 3,
        lang-tag: false,
        indentation: silver,
        numbers-color: silver,
        highlights: (line: 3, code-style: it => fade(20%, it)),
        footer: [Some basic footer],
        footer-fill: purple.lighten(80%),
        footer-sep: 1pt + purple,
        footer-code-aligned: true,
        ```typ
        )
        ```,
      )),
      fill: white,
    ),
    ```typ
    )
    ```,
  )),
)

== Lang tag & Frame

The lang tag indicates which language is used and can be placed inside of the code, in the header, or on the frame.

= Highlights

The #ultraw package provides a simple and efficient highlighting that enables one to define highlights directly inside the raw text.

= Comments & Jumps

= Referencing

= Pseudo code

= Diffs

= Themes

= Good practices

// --- Library -----------------------------------------------------------------

#pagebreak()

= Library <library>

#alert[
  Before going any further, a note about arguments of functions of this package (#urawf, #f("set-uraw"), etc) must be made. Most arguments are grouped by categories (`frame`, `numbers`, etc) to which they refer to. Such arguments can be given under two form: a *grouped form* or a *direct form*. The grouped form groups arguments of the same category together while the direct form points to the arguments directly as follow:

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

== #urawf <uraw-args-forms-table>

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
    sep..............................................................comment-sep
    style..........................................................comment-style
  )
  jump: (
    comment.........................................................jump-comment
    comment-fill...............................................jump-comment-fill
    comment-indent...........................................jump-comment-indent
    comment-marker...........................................jump-comment-marker
    comment-marker-fill.................................jump-comment-marker-fill
    comment-placement.....................................jump-comment-placement
    comment-sep.................................................jump-comment-sep
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

Arguments from `frame`, `header`, `footer`, `numbers`, `code`, `comment`, `jump`, `highlight`, and `lang-tag` follow the same pattern as the #link(<uraw-args-forms-table>)[#urawf table], the general ones adding the following ones.

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

Arguments from `frame`, `header`, `footer`, `numbers`, and `code` follow the same pattern as the #link(<uraw-args-forms-table>)[#urawf table], except for a specific argument of `code`.

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

