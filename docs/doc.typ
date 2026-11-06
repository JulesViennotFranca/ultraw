#import "@mine/ultraw:0.0.1": *
#import "@preview/pinit:0.2.2": *
#import "utils.typ": *

#show heading: text.with(font: "Geist Mono")
#show heading.where(depth: 1): text.with(30pt)
#show heading.where(depth: 2): text.with(18pt)
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

#highlights.add(
  (ldel: "*$", rdel: "$*", ..highlights.base-style(olive), sticky: true),
  (ldel: "*b", rdel: "b*", code-style: text.with(rgb("#4C69C6"))),
  (ldel: "*k", rdel: "k*", code-style: text.with(black)),
  (
    ldel: "*g|",
    rdel: "|g*",
    code-style: it => box(text(fill: gradient.linear(..color.map.rainbow), it)),
  ),
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
          (line: 15, expand: center, fill: gradient.linear(..color.map.flare)),
        ),
        ````typ
        = Using the *|ultraw|* package

        // It is as simple as that:
        #show: uraw

        You can now write *g|beautiful|g* raw
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

      #v(-4pt)

      #uraw-pseudo(
        width: 100%,
        header: [*Algorithm* Merge Sort],
        no-number[*Procedure* MERGE-SORT($L$)],
        [$n <-$ the length of $L$],
        [*if* $n <= 1$ *then*],
        indent[*return* $L$],
        [*end if*],
        [$h <- n / 2$],
        [$L_1 <- L[{0, 1, ..., h-1}]$],
        [$L_2 <- L[{h, h + 1, ..., n-1}]$ ],
        [$L_1 <-$ MERGE-SORT($L_1$)],
        [$L_2 <-$ MERGE-SORT($L_2$)],
        [*return* MERGE($L_1$, $L_2$)],
      )
    ],

    uraw(
      ..themes.window,
      header: style.window-header[The Merge Sort algorithm in python.],
      line-spacing: 0.8em,
      lang-tag-fill: blue.lighten(75%),
      highlights: (
        (
          line: (7, 10),
          ..highlights.base(color: orange),
          expand: none,
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
    ..themes.dark,
    header: [`merge_sort` correction],
    line-spacing: 0.8em,
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
  raw(if type(body) == content and body.has("text") { body.text } else {
    body
  }),
)
#let urawf = f("uraw")
#let uraw-difff = f("uraw-diff")
#let uraw-pseudof = f("uraw-pseudo")

= Usage <usage>

#ultraw provides a highly customizable formatting of raw text.

#v(10pt)

#let import-str = ("#import \"@preview/ultraw:" + uraw-version + "\": *")

#context grid(
  columns: (1fr, auto),
  column-gutter: 3mm,
  row-gutter: par.spacing,
  align: bottom,

  align(center)[*Source code*], align(center)[*Produced pdf*],

  source(width: 100%, precedes: 18, raw(block: true, lang: "typ", import-str)),
  [],

  grid.cell(colspan: 2)[Change the raw blocks with the #urawf show rule:],

  source(
    width: 100%,
    follows: 1,
    precedes: 37,
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
  ),

  [
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
  ],

  grid.cell(
    colspan: 2,
  )[#urawf can also be called locally for a specific raw block:],

  source(
    width: 100%,
    follows: 18,
    precedes: 59,
    ````typ
    #uraw(
      frame: (stroke: luma(240)),
      code: (
        fill: style.zebra(even: luma(240)),
      ),
      header: (
        content: [Some Rust code],
        fill: auto,
      ),
      lang-tag: (
        placement: "header",
        fill: orange.lighten(75%),
      ),
      ```rs
      fn main() {
          println!("Hello World!");
      }
      ```,
    )
    ````,
  ),

  uraw(
    frame-stroke: luma(240),
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
  ),

  grid.cell(
    colspan: 2,
  )[Global configurations can be set with the function #f("set-uraw"):],

  source(
    width: 100%,
    follows: 37,
    ````typ
    #set-uraw(
      frame: (
        width: 6.5cm,
        stroke: 1pt + purple,
        radius: (right: 2mm),
      ),
      numbers: (
        color: white,
        fill: purple,
      ),
      code: (
        fill:
          n => purple.lighten(80% + n * 5%)
      ),
      lang-tag: (visible: false),
    )

    ```py
    def main():
        print("Hello")
        print("World")
    ```
    ````,
  ),

  uraw(
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
  ),
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
    ```typ
    #let my-box(body) = box(
      stroke: purple,
      body,
    )
    ```,
  ),
  caption: [The differents components of an #urawf block.],
) <uraw-block-components>

A block of raw text formatted by #urawf is made of several components. They are all colored differently in @uraw-block-components and their name will be underlined with the corresponding color. The raw text is shown inside of the #underline-col(code-col)[code] part. The #underline-col(num-col)[numbers] and #underline-col(num-col)[markers] are displayed in a gutter on the left. A #underline-col(hf-col)[header] and a #underline-col(hf-col)[footer] can be defined. The #underline-col(lang-col)[lang tag] indicates which coding language is used. Finally, the #underline-col(frame-col)[frame] is the box containg the whole block.

#alert(icon: "info")[
  The precise arguments of the #urawf function can be inspected #link(<uraw-lib>)[here].
]

#alert[
  For conciseness, arguments names in this section are different than in the above examples. Refer to the #link(<args-forms>)[Arguments forms] section if you want to understand why both namings are supported.
]

== Code

Quite some parameters of the code can be set with #urawf, such as appearence (e.g., `theme`, `fill`) or the layout (e.g., `line-spacing`, `indent-size`). Here are some examples illustrating the offered possibilities:

#text(0.8em, grid(
  columns: (1fr, 1fr),
  column-gutter: 5mm,

  example(
    output-args: (lang-tag: "false", numbers: "none"),
    jumps: (from: 5, to: 13, comment: [`...,`], skip-lines: true),
    ````typ
    #uraw(
      indentation: purple,
      indent-size: 1,
      indented-line-return: false,
      code-color: olive,
      ```typ
      #let ex(body) = stack(dir: ttb,
        spacing: 2mm,
        [Here is an example I really want to show you:],
        body
      )
      ```,
    )
    ````,
  ),

  example(
    output-args: (lang-tag: "false", numbers: "none"),
    jumps: (from: 4, to: 12, comment: [`...,`], skip-lines: true),
    ````typ
    #uraw(
      line-spacing: .88em,
      code-fill: style.zebra(odd: luma(240)),
      theme: raw-themes.github-light,
      ```typ
      #let ex(body) = stack(dir: ttb,
        spacing: 2mm,
        [Here is an example I really want to show you:],
        body
      )
      ```,
    )
    ````,
  ),
))

== Numbers & Markers

Numbers indicate the code lines numbers and markers can further decorate each line. They both appear in a gutter on the left of the code. The background of this gutter, the color of numbers and markers, or the starting or ending number can be chose as follow:

#text(0.8em, grid(
  columns: (1fr, 1fr),
  column-gutter: 5mm,

  example(
    output-args: (
      lang-tag: "false",
      indentation: "silver",
      highlights: "(line: (8, 12), code-style: it => fade(20%, it))",
    ),
    hidden-prefix1: fade-string,
    jumps: (from: 6, to: 14, comment: [`...,`], skip-lines: true),
    ````typ
    #uraw(
      start: 8,
      numbers-align: left,
      numbers-fill:
        style.zebra(even: yellow, odd: aqua),
      markers: ((10, [•]), (11, [•])),
      ```typ
      #let ex(body) = stack(dir: ttb,
        spacing: 2mm,
        [Here is an example:],
        body
      )
      ```,
    )
    ````,
  ),

  example(
    output-args: (
      lang-tag: "false",
      indentation: "silver",
      numbers-align: "left",
      highlights: "(line: (1, 5), code-style: it => fade(20%, it))",
    ),
    hidden-prefix1: fade-string,
    jumps: (from: 6, to: 14, comment: [`...,`], skip-lines: true),
    ````typ
    #uraw(
      numbers: "1.",
      numbers-color: maroon,
      numbers-sep: 1pt + teal,
      markers-over-numbers: true,
      markers: (4, $->$),
      ```typ
      #let ex(body) = stack(dir: ttb,
        spacing: 2mm,
        [Here is an example:],
        body
      )
      ```,
    )
    ````,
  ),
))

== Header & Footer

Each #urawf block can have a header and a footer. Like `grid`s headers and footers, they can be repeated at each page breaks. Their start can also be aligned with the code block.

#text(0.8em, grid(
  columns: (1fr, 1fr),
  column-gutter: 5mm,

  source(
    width: 100%,
    frame-inset: (bottom: 0pt, top: 2.5pt, x: 3pt),
    jumps: (
      from: 3,
      to: 9,
      comment: [`...,`],
      marker: [],
      fill: none,
      indent: "guideline",
      skip-lines: true,
    ),
    comments: (
      (
        after: 10,
        content: text(style: "normal", uraw(
          lang-tag: false,
          indentation: silver,
          numbers-color: silver,
          highlights: (line: 1, code-style: it => fade(20%, it)),
          header: [Some basic header],
          header-code-aligned: true,
          ```typ
          #let my-box(body) = box(stroke: purple,
          ```,
        )),
        fill: white,
      ),
      (
        after: 10,
        content: text(style: "normal", uraw(
          width: 100%,
          start: 2,
          lang-tag: false,
          indentation: silver,
          numbers-color: silver,
          highlights: (line: (2, 3), code-style: it => fade(20%, it)),
          header: [Some basic header],
          header-code-aligned: true,
          ```typ
            body,
          )
          ```,
        )),
        fill: white,
      ),
    ),
    ````typ
    #uraw(
      header: [Some basic header],
      header-repeat: true,
      ```typ
      #let my-box(body) = box(stroke: purple,
        body,
      )
      ```,
    )
    ````,
  ),

  example(
    output-args: (
      lang-tag: "false",
      indentation: "silver",
      numbers-color: "silver",
      highlights: "(line: (1, 2), code-style: it => fade(20%, it))",
    ),
    hidden-prefix1: fade-string,
    jumps: (from: 6, to: 11, comment: [`...,`], skip-lines: true),
    ````typ
    #uraw(
      footer: [Some basic footer],
      footer-color: blue,
      footer-fill: purple.lighten(80%),
      footer-sep: 1pt + purple,
      footer-code-aligned: true,
      ```typ
      #let bbox(body) = box(stroke: blue, body)
      #let rbox(body) = box(stroke: red, body)
      ```,
    )
    ````,
  ),
))

== Lang tag & Frame

The lang tag indicates which language is used and can be placed inside of the code, in the header, or on the frame. The lang tag may contain a custom icon or name. For most know languages, their icon is already available by default. The frame controls various parameters such as wether the code block can break across pages or if such page break is sharp (no radius and stroke around the page break).

#text(0.8em, grid(
  columns: (1fr, 1fr),
  column-gutter: 5mm,

  example(
    output-args: (
      numbers-color: "silver",
      indentation: "silver",
      highlights: "(line: (1, 4), code-style: it => fade(20%, it))",
    ),
    hidden-prefix1: fade-string,
    jumps: (from: 6, to: 13, comment: [`...,`], skip-lines: true),
    ````typ
    #uraw(
      lang-tag-stroke: teal,
      lang-tag-fill: teal.lighten(80%),
      lang-tag-radius: (right: 5pt),
      lang-tag-name: "Typst",
      lang-tag-color: teal.darken(30%),
      ```typ
      #let my-box(body) = box(
        stroke: purple,
        body,
      )
      ```,
    )
    ````,
  ),

  example(
    output-args: (
      numbers-color: "silver",
      indentation: "silver",
      highlights: "(line: (1, 4), code-style: it => fade(20%, it))",
    ),
    hidden-prefix1: fade-string,
    jumps: (from: 6, to: 13, comment: [`...,`], skip-lines: true),
    ````typ
    #uraw(
      width: 80%,
      frame-stroke: 1pt + red,
      frame-radius: 2mm,
      lang-tag-placement: "right-top",
      lang-tag-icon: none,
      ```typ
      #let my-box(body) = box(
        stroke: purple,
        body,
      )
      ```,
    )
    ````,
  ),
))

= Highlights

The #ultraw package provides a simple and efficient highlighting. The main feature is to be able to define highlights directly inside the raw text as follow:

#grid(
  columns: (1fr, auto),
  align: bottom,
  column-gutter: 3mm,

  [
    #highlights.remove((ldel: "*|", rdel: "|*"), (ldel: "*!", rdel: "!*"))
    #highlights.add(
      (ldel: "*||", rdel: "||*", ..highlights.base-style(yellow), sticky: true),
      (ldel: "*!!", rdel: "!!*", ..highlights.alert-style(red), sticky: true),
    )

    #source(
      width: 100%,
      ````typ
      #show: uraw

      ```typ
      = One example of *||*|||*highlight*|||*||*

      Highlight as you *!!*!!!*want*!!!*!!*.
      ```
      ````,
    )

    #highlights.add(highlights.base(), highlights.alert())
    #highlights.remove((ldel: "*||", rdel: "||*"), (ldel: "*!!", rdel: "!!*"))
  ],

  [
    #show: uraw

    ```typ
    = One example of *|highlight|*

    Highlight as you *!want!*.
    ```

    #v(16pt)
  ],
)

As shown above, raw text can be highlighted by framing it between highlights delimiters.

#alert(icon: "info")[
  For the precise list of default highlights, refer to the #link(<highlights-lib>)[`highlights`] module.
]

You can define your own highlights by providing a left and a right delimiters and its style. In addition to basic style parameters (`stroke`, `fill`, `radius`), a highlight can style the code it highlights (`code-style`), expand left or right or both (`expand`), and merge with its other parts across lines (`sticky`). Default values of these parameters are set by the #link(<uraw-lib>)[`highlight`] setting of #urawf. Here are some examples illustrating highlights definition and use:

#text(0.8em, block({
  source(
    width: 100%,
    comments: (
      before: 7,
      content: [Set both `ldel` and `rdel` with `del`.],
      sep: none,
      fill: white,
      marker: octique("info"),
      indent: "guideline",
    ),
    ````typ
    #highlights.add(
      (
        ldel: "*r",
        rdel: "r*",
        code-style: it => box(text(fill: gradient.linear(..color.map.rainbow), it)),
      ),
      (del: "*p*", sticky: true, ..highlights.base-style(purple)),
      (ldel: "*#", rdel: "#*", expand: right, fill: gradient.linear(..color.map.flare)),
    )

    ```rs
    fn *rmainr*() {
      let n_even = 0;
      *p*for x in 1..=5 {
        if x % 2 == 1 {
          *rprintlnr*!("odd:", x);
          n_even += 1;
        }
      }*p*
      *#return n_even
    }#*
    ```
    ````,
  )

  highlights.add(
    (
      ldel: "*r",
      rdel: "r*",
      code-style: it => box(text(
        fill: gradient.linear(..color.map.rainbow),
        it,
      )),
    ),
    (del: "*p*", sticky: true, ..highlights.base-style(purple)),
    (
      ldel: "*#",
      rdel: "#*",
      expand: right,
      fill: gradient.linear(..color.map.flare),
    ),
  )

  place(center + bottom, dx: 1cm, dy: -1.2em - 2pt, uraw(
    frame-stroke: black,
    frame-fill: white,
    ```rs
    fn *rmainr*() {
      let n_even = 0;
      *p*for x in 1..=5 {
        if x % 2 == 1 {
          *rprintlnr*!("odd:", x);
          n_even += 1;
        }
      }*p*
      *#return n_even
    }#*
    ```,
  ))
}))

#alert(icon: "info")[
  The available highlights are managed by functions of the #link(<highlights-lib>)[`highlights`] module.
]

== Local highlights <local-highlights>

Highlights can also be defined per block through the `highlights` argument of #urawf, without touching the raw text. A local highlight targets either a range of lines (`line`) or a range of code coordinates (`start` and `end` containing `(line, character)` pairs). The style parameters remains the same as for regular highlights.

#text(0.8em, block(width: 100%, {
  source(
    width: 100%,
    ````typ
    #uraw(
      highlights: (
        (line: (1, 2), fill: aqua.lighten(60%)),
        (start: (3, 11), end: (3, 17), ..highlights.alert()),
        (start: 4, end: 4, stroke: purple),
      ),
      ```py
      def area(r):
          pi = 3.14
          return pi * r * r
      print(area(2))
      ```,
    )
    ````,
  )

  place(center + bottom, dy: -2.4em - 1pt, uraw(
    frame-stroke: black,
    frame-fill: white,
    highlights: (
      (line: (1, 2), fill: aqua.lighten(60%)),
      (start: (3, 11), end: (3, 17), ..highlights.alert()),
      (start: 4, end: 4, stroke: purple),
    ),
    ```py
    def area(r):
        pi = 3.14
        return pi * r * r
    print(area(2))
    ```,
  ))
}))

= Inline

A simpler version of #urawf for inline raw text exists. It inherits its appearence from #urawf and can contain highlights. Here is an example of such inline formatted raw text:

#highlights.remove((ldel: "*!", rdel: "!*"))
#highlights.add(
  (ldel: "*!!", rdel: "!!*", ..highlights.alert-style(red), sticky: true),
)

#grid(
  columns: (auto, 1fr),
  column-gutter: 1cm,
  align: horizon,
  text(0.8em, source(numbers: none, lang-tag: false, ```typ
  uraw-inline(highlights: (end: 5, ..highlights.base()), `ult*!!*!!!*raw*!!!*!!*`)
  ```)),
  uraw-inline(highlights: (end: 5, ..highlights.base()), `ult*!!raw!!*`),
)

#highlights.add(highlights.alert())
#highlights.remove((ldel: "*!!", rdel: "!!*"))

= Comments <comments>

Comments are content blocks inserted between lines of code. They are defined locally either in a short form `(line, content)` or in an elaborate one `(after: line, content: content, ...)` containing more parameters. Such parameters controls the style, placement, and markers of comments. By default, they abide by the #link(<uraw-lib>)[`comment`] setting of #urawf.

#text(0.8em, block({
  source(
    width: 100%,
    ````typ
    #uraw(
      numbers-sep: black,
      comments: (
        (1, [After line 1, from the frame.]),
        (before: 3, content: [Before line 3, at indentation.], indent: "guideline", sep: olive),
        (
          after: 4,
          content: [With a marker and separators.],
          marker: style.callout-marker(color: blue, "?"),
          marker-placement: "markers",
          fill: none,
        ),
      ),
      ```py
      def area(r):
          if r < 0:
              return None
          return 3.14 * r * r
      ```,
    )
    ````,
  )

  place(center + bottom, dx: 1cm, dy: -7pt, uraw(
    frame-stroke: black,
    frame-fill: white,
    numbers-sep: black,
    comments: (
      (1, [After line 1, from the frame.]),
      (
        before: 3,
        content: [Before line 3, at indentation.],
        indent: "guideline",
        sep: olive,
      ),
      (
        after: 4,
        content: [With a marker and no background.],
        marker: style.callout-marker(color: blue, "?"),
        marker-placement: "markers",
        fill: none,
      ),
    ),
    ```py
    def area(r):
        if r < 0:
            return None
        return 3.14 * r * r
    ```,
  ))
}))

#alert(icon: "info")[
  The numbers column's separator is automatically drawn in the comment when a `marker` is given. So if you want this behavior without a marker, simply set `marker: []`.
]

= Jumps <jumps>

Jumps enables one to skip some line numbers and possibly skip corresponding raw text lines too. As comments, jumps are defined either by a short form `(from, to)` or with a dictionary (`from: from, to: to, ...`). Defined with the dictionary form, a jump can skip the associated raw text lines (`skip-lines`). Jumps can also be paired with a comment whose content and style can be set. The #link(<uraw-lib>)[`jump`] setting of #urawf controls default parameters of jumps.

#text(0.8em, grid(
  columns: (1fr, 1fr),
  column-gutter: 5mm,

  example(
    jumps: (from: 5, to: 12, comment: [`...,`], skip-lines: true),
    ````typ
    #uraw(
      jumps: (
        (1, 6),
        (from: 7, to: 11, comment: $dots.v$, indent: "line"),
      ),
      ```py
      def main():
          setup()
          run()
          stop()
      ```,
    )
    ````,
  ),

  example(
    jumps: (from: 8, to: 14, comment: [`...,`], skip-lines: true),
    ````typ
    #uraw(
      jumps: (
        from: 1,
        to: 3,
        skip-lines: true,
        comment:
          (f, t) => [#(t - f - 1) line jump],
      ),
      ```py
      a = 1
      b = 2
      c = 3
      ```,
    )
    ````,
  ),
))

= Chaining raw blocks

To display consecutive raw blocks across your document (e.g., the source code in the #link(<usage>)[Usage] section), you can use `follows` and `precedes` arguments.

#text(0.8em, grid(
  columns: (1fr, 1fr),
  column-gutter: 5mm,
  align: bottom,

  source(width: 100%, ````typ
  #uraw(
    frame: (width: 100%, stroke: black),
    lang-tag-placement: "top-right",
    precedes: true,
    ```rs
    fn a(m: i32, n: i32) -> i32 {
      match (m, n) {
        (0, n) => n + 1,
        (m, 0) => a(m - 1, 1),
        (m, n) => a(m - 1, a(m, n - 1)),
      }
    }
    ```
  )

  Your labtop can't compute this line:

  #uraw(
    frame: (width: 100%, stroke: black),
    lang-tag-placement: "top-right",
    follows: 7,
    ```rs
    let gigantic = a(4, 3)
    ```
  )
  ````),

  [
    #uraw(
      frame: (width: 100%, stroke: black),
      lang-tag-placement: "top-right",
      precedes: true,
      ```rs
      fn a(m: i32, n: i32) -> i32 {
        match (m, n) {
          (0, n) => n + 1,
          (m, 0) => a(m - 1, 1),
          (m, n) => a(m - 1, a(m, n - 1)),
        }
      }
      ```,
    )

    Your labtop can't compute this result:

    #uraw(
      width: 100%,
      frame-stroke: black,
      lang-tag-placement: "top-right",
      follows: 7,
      ```rs
      let gigantic = a(4, 3)
      ```,
    )
  ],
))

#alert(icon: "info")[
  The precise values taken by `follows` and `precedes` are quite intricate so read their #link(<uraw-lib>)[documentation] to use them optimally.
]

= Diffs

#uraw-difff automatically compares and displays the difference between an old and a new version of some code. The different colors and markers of removed and added lines is customizable. The codes take all the settings of #urawf, including highlight delimiters.

#text(0.8em, example(
  indent-size: 2,
  ````typ
  #uraw-diff(
    ```py
    def greet(name):
        print("Hello " + name)
    ```,
    ```py
    def greet(name, polite=False):
        word = "Hello" if polite else "Hi"
        print(word + " " + name)
    ```,
  )
  ````,
))

The diff is displayed on one or two columns, depending on a `columns` parameter mimicking the one of `grid`. Between the two columns, a `column-gutter` can be set and a separator `sep` can be drawn. Displayed in one column, the two numbers gutters are side by side. More styling parameters are specific to the function #link(<uraw-diff-lib>, uraw-difff), here is an example:

#text(0.8em, block({
  source(width: 100%, ````typ
  #uraw-diff(
    columns: 1,
    old-fill: orange.lighten(80%),
    new-fill: blue.lighten(85%),
    old-numbers-fill: orange.lighten(40%),
    new-numbers-fill: blue.lighten(50%),
    blank-fill: style.hatch(purple),
    comments: (version: "new", before: 1, content: [A more precise value:]),
    ```py
    pi = 3.14
    r = 2
    ```,
    ```py
    pi = 3.14159
    r = 2
    ```,
  )
  ````)

  place(center + bottom, dy: -3.6em, uraw-diff(
    frame-stroke: black,
    frame-fill: white,
    columns: 1,
    old-fill: orange.lighten(80%),
    new-fill: blue.lighten(85%),
    old-numbers-fill: orange.lighten(40%),
    new-numbers-fill: blue.lighten(50%),
    blank-fill: style.hatch(purple),
    comments: (version: "new", before: 1, content: [A more precise value:]),
    ```py
    pi = 3.14
    r = 2
    ```,
    ```py
    pi = 3.14159
    r = 2
    ```,
  ))
}))

Markers, highlights, comments, and jumps are given an additional `version` they refer to (`"new"` by default or `"old"`). When given as array short forms, the version must be the first element (e.g., comments given with `(version, line, content)`). Comments can span on both versions (`span: true`) and jumps can apply to both versions (`version: both`, lines numbers of the new version are used).

The settings of all the diffs are set with #f("set-uraw-diff"), which overrides the ones of #f("set-uraw").

= Pseudo code <pseudo-code>

#uraw-pseudof writes pseudo code with the same frame, header, footer and numbers settings as #urawf. The pseudo code is given line by line as follow:

#text(0.8em, grid(
  columns: (1fr, auto),
  column-gutter: 5mm,
  source(```typ
  #uraw-pseudo(
    header: [*Algorithm* Binary search],
    no-number[*Input* a sorted list $L$, a value $x$],
    [$a <- 0$, $b <- |L|$],
    [*while* $a < b$ *do*],
    indent(
      [$m <- floor((a + b) / 2)$],
      [*if* $L[m] < x$ *then* $a <- m + 1$ *else* $b <- m$],
    ),
    [*return* $a$],
  )
  ```),

  align(horizon, uraw-pseudo(
    header: [*Algorithm* Binary search],
    no-number[*Input* a sorted list $L$, a value $x$],
    [$a <- 0$, $b <- |L|$],
    [*while* $a < b$ *do*],
    indent(
      [$m <- floor((a + b) / 2)$],
      [*if* $L[m] < x$ *then* $a <- m + 1$ *else* $b <- m$],
    ),
    [*return* $a$],
  )),
))

As shown, numbering and indentation are managed by the `no-number` and `indent` functions. Jumps can also be added to pseudo code (without comments). The settings of all pseudo codes are set with #f("set-uraw-pseudo").

= Figure & Referencing

A #urawf block and a #uraw-difff in figures are listings. A #uraw-pseudof code is refered to as an Algorithm by default. The lines of a labelled figure can be referenced by `@label.n` (or `@label.version.n` for diffs).

#show: uraw

#grid(
  columns: (1fr, 1fr),
  align: bottom,
  [
    #figure(
      uraw-pseudo(
        [*if* $n = 0$ *then*],
        indent[*return* $1$],
        [*else*],
        indent[*return* $n *$ FACT($n - 1$)],
        [*end if*],
      ),
      caption: [The factorial algorithm.],
    ) <fact-algo>
  ],
  [
    #figure(
      ```py
      def fact(n):
          if n == 0:
              return 1
          return n * fact(n - 1)
      ```,
      caption: [The factorial function.],
    ) <fact>
  ],
)

The factorial algorithm is defined in @fact-algo. Its implementation is shown in @fact. In these, @fact-algo.4 and @fact.4 match. The precise text printed to reference lines can be changed with `line-reference`.

= Code from files

#urawf and #uraw-difff both can take files as input raw texts. Files should be given as a `path` or using the finer #f[read-code] provided function.
// TODO reference `read-code
Using this, you can for example make a raw block display itself (useless but really cool):

#uraw(
  ..themes.note,
  width: 100%,
  lang-tag-name: "source",
  read-code(path("doc.typ"), lang: "typ", from: 1208, to: 1213),
)
// TODO make sure this is right at the end

= Themes <themes>

// TODO reference module raw-themes
By default, #ultraw keeps a very simple look so that it fits any document and can easily be built upon. But more elaborate themes are available in the `themes` module:

#let themes-dict = (
  Default: themes.default,
  Note: themes.note,
  Window: themes.window,
  Dark: themes.dark,
)

#grid(
  columns: (1fr, 1fr),
  column-gutter: 5mm,
  row-gutter: 5mm,
  align: bottom,
  ..themes-dict
    .pairs()
    .map(((name, theme)) => [
      #uraw(
        ..theme,
        width: 100%,
        header: name + " theme",
        comments: (2, [A comment]),
        ```py
        def area(r):
            a = 3.14 * r * r
            return a
        ```,
      )
    ]),
)

A theme is a collection of settings that is spread into functions to change their output appearence (e.g., `uraw(..themes.note, ...)`). Diffs can be styled with the same themes. Pseudo codes have only one default theme (the one shown in #link(<fact-algo>)[examples]).

== Creation

First create a `pre-theme` holding your settings as you would write them inside of #urawf. Then, format it to a proper theme with #f[themes.make]. The formatted theme can apply both to `uraw` and `uraw-diff`. Pseudo code themes are formatted with #f[themes.make-pseudo].
// TODO add the reference to make theme functions

#text(0.8em, source(```typ
#let pre-theme = (frame: (stroke: purple, radius: 0pt), code-fill: style.zebra(odd: red), *k...k*)
#let theme = themes.make(pre-theme)
```))

== Raw themes

// TODO reference module raw-themes
Several themes for raw text are available in the `raw-themes` module:

#let raw-themes-dict = (
  "Typst dark": raw-themes.typst-dark,
  "GitHub light": raw-themes.github-light,
  "GitHub dark": raw-themes.github-dark,
)

#grid(
  columns: (1fr, 1fr),
  column-gutter: 5mm,
  row-gutter: 5mm,
  align: bottom,
  ..raw-themes-dict
    .pairs()
    .map(((name, theme)) => [
      #uraw(
        ..(if "dark" in name { themes.dark } else { (:) }),
        theme: theme,
        breakable: false,
        lang-tag-placement: "inline",
        width: 100%,
        header: name + " raw theme",
        ```py
        def area(r):
            return 3.14 * r * r
        ```,
      )
    ]),
)

== More styling

// TODO add ref pointing to style module
Additionally, helper styling functions are provided through the `style` module. These functions range over coloring (e.g., `style.zebra`), numbers styling (e.g., `style.padded`), providing styled elements (e.g., `style.callout-marker`, `style.vdots-jump`) and more (e.g., `style.window`).

// --- Library -----------------------------------------------------------------

#pagebreak()

#text(40pt, font: "Geist Mono", weight: "bold")[Library] <library>

#highlights.add(
  highlights.hole(color: none),
  highlights.strike(),
  highlights.underline(),
  (..highlights.underline(color: red), ldel: "*r_", rdel: "_r*"),
)

= Arguments forms <args-forms>

Functions of this package can receive arguments under two forms: a *grouped form* and a *direct form*. The grouped form groups arguments of the same category together while the direct form points to the arguments directly as follow:

#align(center, grid(
  columns: 2,
  column-gutter: 1cm,
  row-gutter: 5mm,
  align: center,
  [*Grouped form*], [*Direct form*],
  uraw-inline(`#uraw(*|frame|*: (*|fill|*: purple))`),
  uraw-inline(`#uraw(*|frame-fill|*: purple)`),
))

For all arguments, the grouped form is #uraw-inline(`*r_category_r*: (..., *r_parameter_r*: value, ...)`) and the direct form is #uraw-inline(`*r_category_r*-*r_parameter_r*: value`). For organization purpose, throughout the rest of the documentation arguments will be given under their grouped form.

To enable a fast access to common and unambiguous parameters, some arguments can be given under a *short form*. The short form is straightforward, it is #uraw-inline(`*r_parameter_r*: value`) in most cases. Here is the list of eligible arguments along with their short form:

#align(center, uraw(
  numbers: none,
  comment-fill: none,
  comment-style: text.with(style: "normal"),
  comments: (
    (before: 1, content: strong(urawf)),
    (before: 27, content: strong(uraw-difff)),
    (before: 39, content: strong(uraw-pseudof)),
  ),
  line-spacing: 7pt,
  ```
  general
    coloring-follow-numbers.............................coloring-follow-numbers
    default-stroke-thickness...........................default-stroke-thickness
    line-reference...............................................line-reference
    markers-over-numbers...................................markers-over-numbers
  frame
    breakable.........................................................breakable
    sharp-page-break...........................................sharp-page-break
    width.................................................................width
  header
    content..............................................................header
  footer
    content..............................................................footer
  numbers
    end.....................................................................end
    format..............................................................numbers
    start.................................................................start
  code
    indent-size.....................................................indent-size
    indentation.....................................................indentation
    indented-line-return...................................indented-line-return
    line-spacing...................................................line-spacing
    theme.................................................................theme
  lang-tag
    visible............................................................lang-tag

  general
    blank-fill.......................................................blank-fill
    coloring-follow-numbers.............................coloring-follow-numbers
    column-gutter.................................................column-gutter
    columns.............................................................columns
    default-stroke-thickness...........................default-stroke-thickness
    line-reference...............................................line-reference
    markers-over-numbers...................................markers-over-numbers
    sep.....................................................................sep
  diff-marker
    visible.........................................................diff-marker

  general
    algorithm-figure...........................................algorithm-figure
  code
    indent-size.....................................................indent-size
    style.................................................................style
  ```,
))

= #urawf <uraw-lib>

#let arg(name, types, body) = block(breakable: false, below: 1.2em)[
  #raw(name) #h(1fr) #text(0.85em, fill: gray.darken(30%), types) \
  #pad(left: 5mm, body)
]

#source(width: 100%, ```typ
#uraw(..args, markers: (), highlights: (), comments: (), jumps: (), doc)
```)

#arg(
  "doc",
  "content, path, dictionary",
)[The content whose raw blocks are displayed (a whole document with `#show: uraw`, or a raw block), some code read from a file with #f("read-code"), or the path of a file.]
#arg(
  "..args",
  "arguments",
)[The settings, by category or directly (see the #link(<args-forms>)[arguments forms table]), and `follows` and `precedes` to continue a block on another one (as at a page break): the side of the block which continues has no radius, stroke or vertical code inset, and its header or footer is only shown if it repeats. An integer `follows` is the number of the last line of the preceding block, an integer `precedes` the largest number of the following blocks (so that the number columns have the same width).]
#arg(
  "markers",
  "array, dictionary",
)[The markers of the lines, as `(line, content)` or `(line: line, content: content)`.]
#arg(
  "highlights",
  "array, dictionary",
)[The manual highlights, given by `line`, or `start` and `end`, and some `highlight` settings (see #link(<local-highlights>)[Manual highlights]).]
#arg(
  "comments",
  "array, dictionary",
)[The comments, as `(line, content)` or dictionaries with `after` or `before`, `content`, and `comment` settings (see #link(<comments>)[Comments]).]
#arg(
  "jumps",
  "array, dictionary",
)[The jumps of the numbers, as `(from, to)` or dictionaries with `from`, `to`, `skip-lines`, `comment` and `jump` settings (see #link(<jumps>)[Jumps]).]

The settings of the following blocks are set with `set-uraw(..args)`, or `set-uraw(lang, ..args)` for the blocks of a language. They are read with `get-uraw(lang)` (in a context) and reset with `reset-uraw(lang)` (the language being optional). The function `read-code(file, from: 1, to: none, lang: auto)` reads the lines `from`-`to` of a file, the language being given by its extension by default. Inline code with highlights is displayed with `uraw-inline(body, lang: none, highlights: ())`, its manual highlights being given by `start` and `end` character positions.

= #uraw-difff <uraw-diff-lib>

#source(width: 100%, ```typ
#uraw-diff(..args, markers: (), highlights: (), comments: (), jumps: ())
```)

#arg(
  "..args",
  "arguments",
)[The old and the new code (raw blocks, paths, or code read with #f("read-code")), the settings of #urawf, the ones specific to diffs (see the #link(<args-forms>)[arguments forms table]), and `follows` and `precedes` as for #urawf.]
#arg(
  "markers, highlights, comments, jumps",
  "array, dictionary",
)[As for #urawf, on the lines of a `version` (`"old"` or `"new"`, `"new"` by default): `(version, line, content)` or dictionaries with a `version`. A comment can `span` over both separated codes, and a jump can be on `"both"` versions.]

The settings of the following diffs are set with `set-uraw-diff(..args)`, read with `get-uraw-diff()` and reset with `reset-uraw-diff()`.

= #uraw-pseudof <uraw-pseudo-lib>

#source(width: 100%, ```typ
#uraw-pseudo(..args, jumps: ())
#indent(..contents)
#no-number(..contents, indent: true)
```)

#arg(
  "..args",
  "arguments",
)[The lines (each content is a line), and the settings (see the #link(<args-forms>)[arguments forms table]).]
#arg(
  "jumps",
  "array, dictionary",
)[The jumps of the numbers, as `(from, to)` or dictionaries with `from` and `to`.]
#arg("indent", "function")[Indents its contents by one level.]
#arg(
  "no-number",
  "function",
)[Writes lines without number, indented as the code when `indent` is `true`, from the left of the frame otherwise.]

The settings of the following pseudo codes are set with `set-uraw-pseudo(..args)`, read with `get-uraw-pseudo()` and reset with `reset-uraw-pseudo()`.

= Highlights <highlights-lib>

The `highlights` module manages the highlights defined by delimiters, which are used by all the blocks. There are two of them by default: `base` (`*|` and `|*`) and `alert` (`*!` and `!*`).

#arg(
  "add(..highlights)",
  "content",
)[Adds highlights by name, a highlight replacing the one with the same name. A highlight has a left and a right delimiter (`ldel` and `rdel`, or `del` when they are the same) and some `highlight` settings. Two highlights cannot have the same delimiters.]
#arg("remove(..names)", "content")[Removes highlights by name.]
#arg("get(name)", "dictionary")[The settings of a highlight (in a context).]
#arg("list()", "dictionary")[The highlights by name (in a context).]

It also provides predefined highlights with their delimiters, and the styles of `base` and `alert` alone (`-style`), to define new highlights or to spread in manual ones:


#text(0.8em, grid(
  columns: (1fr, 1fr),
  column-gutter: 5mm,
  row-gutter: 3mm,
  align: horizon,
  ..(
    ("base(color: yellow)", "base-style(color)", "*|", "|*"),
    ("alert(color: red)", "alert-style(color)", "*!", "!*"),
    ("hide()", none, "*~", "~*"),
    ("strike(color: red)", none, "*-", "-*"),
    ("underline(color: black)", none, "*_", "_*"),
  )
    .map(((f, fs, l, r)) => (
      [#raw(f) \ #if fs != none [#raw(fs) \ ] #text(
          gray.darken(30%),
        )[delimiters #raw(l) and #raw(r)]],
      uraw(
        lang-tag: false,
        numbers: none,
        raw(block: true, lang: "py", "x = " + l + "some code" + r + " + 1"),
      ),
    ))
    .flatten(),
))

= Themes & Style

#arg(
  "themes",
  "module",
)[The themes of #urawf and #uraw-difff (`default`, `note`, `dark`, `window`) and of #uraw-pseudof (`pseudo-default`), to spread in the functions (see #link(<themes>)[Themes]).]
#arg(
  "themes.make(pre-theme)",
  "dictionary",
)[A theme of #urawf and #uraw-difff from its settings by category (and the settings of diffs in `diff`). `themes.make-pseudo` makes the themes of pseudo code.]
#arg(
  "raw-themes",
  "module",
)[Syntax highlighting themes for the `theme` setting: `typst-dark`, `github-light` and `github-dark`.]
#arg(
  "style",
  "module",
)[Helpers for the settings: `zebra(odd: none, even: none)` gives a fill alternating on the line numbers (for `code-fill` or `numbers-fill`), and `octique-marker(octique)` makes a function giving markers from the icons of the `octique` package.]
#arg("lang-icons", "dictionary")[The icons of the lang tag, by language.]
