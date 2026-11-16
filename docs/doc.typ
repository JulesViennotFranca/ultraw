#import "@preview/ultraw:0.0.1": *
#import "@preview/pinit:0.2.2": *
#import "utils.typ": *

#show heading: it => {
  set text(font: "Geist Mono")
  it
}
#show heading.where(depth: 1): text.with(30pt)
#show heading.where(depth: 2): text.with(18pt)
#set page(numbering: "1")
#set text(12pt)
#show link: it => underline(stroke: blue, it)
#show ref: it => underline(stroke: blue, it)

#let uraw-version = "0.0.1"

#highlights.add(
  (ldel: "*$", rdel: "$*", ..highlights.base-style(olive), sticky: true),
  (ldel: "*b", rdel: "b*", code-style: text.with(rgb("#4C69C6"))),
  (ldel: "*k", rdel: "k*", code-style: text.with(black)),
  (
    ldel: "*g|",
    rdel: "|g*",
    code-style: it => box(text(fill: gradient.linear(..color.map.rainbow), it)),
  ),
  highlights.hole(),
  highlights.strike(),
  highlights.underline(),
  (..highlights.underline(color: red), ldel: "*r_", rdel: "_r*"),
  highlights.strong,
  highlight-types,
)

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
    depth: 1,
    indent: 2mm,
  ),
)

#pagebreak()

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
            line: (8, 12),
            fill: teal.transparentize(70%),
            stroke: teal.darken(30%),
            expand: left,
          ),
          (line: 14, expand: center, fill: gradient.linear(..color.map.flare)),
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

      #uraw-pseudo(width: 100%, header: [*Algorithm* Merge Sort])[
        #pseudo-info[*Procedure* MERGE-SORT($L$)]
        + $n <-$ the length of $L$
        + *if* $n <= 1$ *then*
          + *return* $L$
        + *end if*
        + $h <- n / 2$
        + $L_1 <- L[{0, 1, ..., h-1}]$
        + $L_2 <- L[{h, h + 1, ..., n-1}]$
        + $L_1 <-$ MERGE-SORT($L_1$)
        + $L_2 <-$ MERGE-SORT($L_2$)
        + *return* MERGE($L_1$, $L_2$)
      ]
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
          marker: octique-marker("feed-issue-closed", color: olive),
          marker-placement: "markers",
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
#let f(body) = context {
  assert(body.func() == raw)
  let content = if text.font == "geist mono" { body.text } else { body }
  box(
    fill: luma(230),
    outset: (y: 2pt, x: 1pt),
    radius: 2pt,
    content,
  )
}
#let urawf = f(`uraw`)
#let uraw-difff = f(`uraw-diff`)
#let uraw-pseudof = f(`uraw-pseudo`)

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
  )[Global configurations can be set with the function #f(`set-uraw`):],

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
  caption: [The different components of an #urawf block.],
) <uraw-block-components>

A block of raw text formatted by #urawf is made of several components. They are all colored differently in @uraw-block-components and their names are underlined with the corresponding color. The raw text is shown inside of the #underline-col(code-col)[code] part. The #underline-col(num-col)[numbers] and #underline-col(num-col)[markers] are displayed in a gutter on the left. A #underline-col(hf-col)[header] and a #underline-col(hf-col)[footer] can be defined. The #underline-col(lang-col)[lang tag] indicates which coding language is used. Finally, the #underline-col(frame-col)[frame] is the box containing the whole block.

#alert(icon: "info")[
  The precise arguments of the #urawf function can be inspected #link(<uraw-lib>)[here].
]

#alert[
  For conciseness, argument names in this section are different from those in the above examples. Refer to the #link(<args-forms>)[Arguments forms] section if you want to understand why both namings are supported.
]

== Code

Many parameters of the code can be set with #urawf, such as the appearance (e.g. `theme`, `fill`) or the layout (e.g. `line-spacing`, `indent-size`). Here are some examples illustrating the offered possibilities:

#text(0.8em, grid(
  columns: (1fr, 1fr),
  column-gutter: 5mm,

  ex-output(
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

  ex-output(
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

Numbers indicate the line numbers of the code and markers can further decorate each line. They both appear in a gutter on the left of the code. The background of this gutter, the color of numbers and markers, or the starting or ending number can be chosen as follows:

#text(0.8em, grid(
  columns: (1fr, 1fr),
  column-gutter: 5mm,

  ex-output(
    output-args: (
      lang-tag: "false",
      indentation: "silver",
      highlights: "(line: (8, 12), code-style: it => fade(20%, it))",
    ),
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

  ex-output(
    output-args: (
      lang-tag: "false",
      indentation: "silver",
      numbers-align: "left",
      highlights: "(line: (1, 5), code-style: it => fade(20%, it))",
    ),
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

Each #urawf block can have a header and a footer. Like the headers and footers of `grid`, they can be repeated at each page break. Their start can also be aligned with the code block.

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
        content: box(inset: (x: 2pt, top: 3pt - .325em, bottom: 1pt), text(
          style: "normal",
          uraw(
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
          ),
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

  ex-output(
    output-args: (
      lang-tag: "false",
      indentation: "silver",
      numbers-color: "silver",
      highlights: "(line: (1, 2), code-style: it => fade(20%, it))",
    ),
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

The lang tag indicates which language is used and can be placed inside of the code, in the header, or on the frame. The lang tag may contain a custom icon or name. For most known languages, their icon is already available by default. The frame controls various parameters such as whether the code block can break across pages or whether such a page break is sharp (no radius and stroke around the page break).

#text(0.8em, grid(
  columns: (1fr, 1fr),
  column-gutter: 5mm,

  ex-output(
    output-args: (
      numbers-color: "silver",
      indentation: "silver",
      highlights: "(line: (1, 4), code-style: it => fade(20%, it))",
    ),
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

  ex-output(
    output-args: (
      numbers-color: "silver",
      indentation: "silver",
      highlights: "(line: (1, 4), code-style: it => fade(20%, it))",
    ),
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

The #ultraw package provides simple and efficient highlighting. The main feature is to be able to define highlights directly inside the raw text as follows:

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
  ],
)

As shown above, raw text can be highlighted by framing it between highlight delimiters.

#alert(icon: "info")[
  For the precise list of default highlights, refer to the #link(<highlights-lib>)[`highlights`] module.
]

You can define your own highlights by providing a left and a right delimiter and its style. In addition to basic style parameters (`stroke`, `fill`, `radius`), a highlight can style the code it highlights (`code-style`), expand left or right or both (`expand`), and merge with its other parts across lines (`sticky`). Default values of these parameters are set by the #link(<set-uraw-lib>)[`highlight`] setting of #urawf. Here are some examples illustrating the definition and use of highlights:

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

Highlights can also be defined per block through the `highlights` argument of #urawf, without touching the raw text. A local highlight targets either a range of lines (`line`) or a range of code coordinates (`start` and `end` containing `(line, character)` pairs). The style parameters remain the same as for regular highlights.

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

A simpler version of #urawf for inline raw text exists. It inherits its appearance from #urawf and can contain highlights. Here is an example of such inline formatted raw text:

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

Comments are content blocks inserted between lines of code. They are defined locally either in a short form `(line, content)` or in an elaborate one `(after: line, content: content, ...)` containing more parameters. Such parameters control the style, placement, and markers of comments. By default, they abide by the #link(<set-uraw-lib>)[`comment`] setting of #urawf.

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
          content: [With a marker, no style and no background.],
          marker: style.callout-marker(color: blue, "?"),
          style: none,
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
        content: [With a marker, no style and no background.],
        marker: style.callout-marker(color: blue, "?"),
        style: none,
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

Jumps enable one to skip some line numbers and possibly skip corresponding raw text lines too. Like comments, jumps are defined either by a short form `(from, to)` or with a dictionary (`from: from, to: to, ...`). Defined with the dictionary form, a jump can skip the associated raw text lines (`skip-lines`). Jumps can also be paired with a comment whose content and style can be set. The #link(<set-uraw-lib>)[`jump`] setting of #urawf controls default parameters of jumps.

#text(0.8em, grid(
  columns: (1fr, 1fr),
  column-gutter: 5mm,

  ex-output(
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

  ex-output(
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

To display consecutive raw blocks across your document (e.g. the source code in the #link(<usage>)[Usage] section), you can use `follows` and `precedes` arguments.

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

  Your laptop can't compute this result:

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

    Your laptop can't compute this result:

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
  The precise values taken by `follows` and `precedes` are quite intricate, so read their #link(<uraw-lib>)[documentation] to use them optimally.
]

= Diffs

#uraw-difff automatically compares and displays the difference between an old and a new version of some code. The different colors and markers of removed and added lines are customizable. The codes take all the settings of #urawf, including highlight delimiters.

#text(0.8em, ex-output(
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

The diff is displayed on one or two columns, depending on a `columns` parameter mimicking the one of `grid`. Between the two columns, a `column-gutter` can be set and a separator `sep` can be drawn. Displayed in one column, the two number gutters are side by side. More styling parameters are specific to the function #link(<uraw-diff-lib>, uraw-difff). Here is an example:

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

Markers, highlights, comments, and jumps are defined per version (`(old: ..., new: ...)`) or as an array where each entry is given an additional `version` they refer to (`"new"` or `"old"`). Comments can span both versions.

The settings of all the diffs are set with #f(`set-uraw-diff`), which overrides the ones of #f(`set-uraw`).

= Pseudo code <pseudo-code>

#uraw-pseudof writes pseudo code with the same `code`, `numbers`, `header`, `footer`, `frame` and `comment` settings as #urawf. The lines of the pseudo code are the items of a numbered list, nested items being indented:

#text(0.8em, grid(
  columns: (1fr, auto),
  column-gutter: 5mm,
  source(width: 100%, ```typ
  #uraw-pseudo(header: [*Algorithm* Binary search])[
    #pseudo-info[*Input* a sorted list $L$, a value $x$]
    + $a <- 0$, $b <- |L|$
    + *while* $a < b$ *do*
      #pseudo-comment[$L[a - 1] < x <= L[b]$]
      + $c <- floor((a + b) / 2)$
      + *if* $L[c] < x$ *then* $a <- c + 1$ *else* $b <- c$
    + *return* $a$
  ]
  ```),

  align(horizon, uraw-pseudo(header: [*Algorithm* Binary search])[
    #pseudo-info[*Input* a sorted list $L$, a value $x$]
    + $a <- 0$, $b <- |L|$
    + *while* $a < b$ *do*
      #pseudo-comment[$L[a - 1] < x <= L[b]$]
      + $c <- floor((a + b) / 2)$
      + *if* $L[c] < x$ *then* $a <- c + 1$ *else* $b <- c$
    + *return* $a$
  ]),
))

Comments are written between the lines with `pseudo-comment`, with the same settings as the comments of #urawf except `marker-placement` (their markers are over the numbers). An additional `pseudo-info` function is provided to display information about the pseudo code.

The settings of all pseudo codes are set with #f(`set-uraw-pseudo`).

= Figure & Referencing

A #urawf block and a #uraw-difff in figures are listings. A #uraw-pseudof code is referred to as an Algorithm by default. If the show rule is used (`#show: uraw`), the lines of a labeled figure can be referenced by `@label.n` (or `@label.version.n` for diffs).

#show: uraw

#grid(
  columns: (1fr, 1fr),
  align: bottom,
  [
    #figure(
      uraw-pseudo[
        + *if* $n = 0$ *then*
          + *return* $1$
        + *else*
          + *return* $n *$ FACT($n - 1$)
        + *end if*
      ],
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

#urawf and #uraw-difff both can take files as input. Files should be given as a `path` or using the finer #link(<read-code-lib>, f(`read-code`)) function. Using this, you can for example make a raw block display itself (useless but really cool):

#uraw(
  ..themes.note,
  width: 100%,
  lang-tag-name: "source",
  read-code(path("doc.typ"), lang: "typ", from: 1245, to: 1250),
)
// TODO make sure this is right at the end

= Themes <themes>

By default, #ultraw keeps a very simple look so that it fits any document and can easily be built upon. But more elaborate themes are available in the #link(<themes-lib>, `themes`) module:

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

A theme is a collection of settings that is spread into functions to change their output appearance (e.g. `uraw(..themes.note, ...)`). Diffs can be styled with the same themes. Pseudo codes have only one default theme (the one shown in #link(<fact-algo>)[examples]).

A theme can be applied globally with `#set-uraw(..themes.dark)`.

== Creation

First create a `pre-theme` holding your settings as you would write them inside of #urawf. Then, format it to a proper theme with #link(<themes-make-lib>, f(`themes.make`)). The formatted theme can apply both to `uraw` and `uraw-diff`. Pseudo code themes are formatted with #link(<themes-make-pseudo-lib>, f(`themes.make-pseudo`)).

#text(0.8em, source(width: 100%, ```typ
#let pre-theme = (frame: (stroke: purple, radius: 0pt), code: (fill: red, color: green), *k...k*)
#let theme = themes.make(pre-theme)
```))

== Raw themes

Several themes for raw text are available in the #link(<raw-themes-lib>, `raw-themes`) module:

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

Additionally, helper styling functions are provided through the #link(<style-lib>, `style`) module. These functions range over coloring (e.g. `style.zebra`), numbers styling (e.g. `style.padded`), providing styled elements (e.g. `style.callout-marker`, `style.vdots-jump`) and more (e.g. `style.window-header` or `style.icons`).

// --- Library -----------------------------------------------------------------

#pagebreak()

#text(40pt, font: "Geist Mono", weight: "bold")[Library] <library>

= Arguments forms <args-forms>

Functions of this package can receive arguments under two forms: a *grouped form* and a *direct form*. The grouped form groups arguments of the same category together while the direct form points to the arguments directly as follows:

#align(center, grid(
  columns: 2,
  column-gutter: 1cm,
  row-gutter: 5mm,
  align: center,
  [*Grouped form*], [*Direct form*],
  uraw-inline(`#uraw(*|frame|*: (*|fill|*: purple))`),
  uraw-inline(`#uraw(*|frame-fill|*: purple)`),
))

For all arguments, the grouped form is #uraw-inline(`*r_category_r*: (..., *r_parameter_r*: value, ...)`) and the direct form is #uraw-inline(`*r_category_r*-*r_parameter_r*: value`). For organization purposes, throughout the rest of the documentation arguments will be given under their grouped form.

To enable fast access to common and unambiguous parameters, some arguments can be given under a *short form*. The short form is straightforward: it is #uraw-inline(`*r_parameter_r*: value`) in most cases. Here is the list of eligible arguments along with their short form:

#align(center, uraw(
  numbers: none,
  comment-fill: none,
  comment-style: text.with(style: "normal"),
  comments: (
    (before: 1, content: strong(urawf)),
    (before: 27, content: strong(uraw-difff)),
    (before: 38, content: strong(uraw-pseudof)),
  ),
  line-spacing: 7pt,
  ```
  code
    line-spacing...................................................line-spacing
    theme.................................................................theme
    indentation.....................................................indentation
    indented-line-return...................................indented-line-return
    indent-size.....................................................indent-size
  numbers
    start.................................................................start
    end.....................................................................end
    format..............................................................numbers
  general
    coloring-follow-numbers.............................coloring-follow-numbers
    markers-over-numbers...................................markers-over-numbers
    line-reference...............................................line-reference
    default-stroke-thickness...........................default-stroke-thickness
  header
    content..............................................................header
  footer
    content..............................................................footer
  frame
    breakable.........................................................breakable
    sharp-page-break...........................................sharp-page-break
    width.................................................................width
  lang-tag
    visible............................................................lang-tag

  general
    columns.............................................................columns
    column-gutter.................................................column-gutter
    sep.....................................................................sep
    blank-fill.......................................................blank-fill
    markers-over-numbers...................................markers-over-numbers
    line-reference...............................................line-reference
    default-stroke-thickness...........................default-stroke-thickness
  diff-marker
    visible.........................................................diff-marker

  code
    style.................................................................style
    indent-size.....................................................indent-size
  general
    algorithm-figure...........................................algorithm-figure
  ```,
))

= #urawf <uraw-lib>

#documentation(
  ```typ
  #uraw(
    ..args *htargumentsht*,
    markers *htarray dictionaryht*: (),
    highlights *htarray dictionaryht*: (),
    comments *htarray dictionaryht*: (),
    jumps *htarray dictionaryht*: (),
    follows *htbool int content arrayht*: false,
    precedes *htbool int content arrayht*: false,
    body *htcontent path dictionaryht*,
  )
  ```,

  description: [
    Display raw text.

    For `markers`, `highlights`, `comments` and `jumps`, a single entry or an array of entries are both valid.
  ],

  (
    2,
    [
      The settings (see #link(<set-uraw-lib>)[`set-uraw`] for their description).
    ],
  ),

  (
    3,
    [
      Each marker is given as `(line, content)` or `(line: ..., content: ...)`. `line` takes a single line or a range `(from, to)`.
    ],
  ),

  (
    4,
    [
      For each highlight, the range it covers is given either by `line` or `start` and `end`. `line` can take a single line number or a pair `(from, to)`. `start` and `end` both can take a single line number (meaning the start and end of that line) or a pair `(line, character)` to point at an exact code location. Each highlight can have specific styling parameters (`fill`, `stroke`, `radius`, `code-style`, `sticky`, `expand`, see #link(<set-uraw-lib>)[`set-uraw`] for more details).
    ],
  ),

  (
    5,
    [
      Each comment is given as `(line, content)` (the comment is displayed after the line) or a dictionary with `after` / `before` indicating the targeted line, `content`, and styling parameters (`style`, `indent`, `fill`, `sep`, `marker`, `marker-fill`, `marker-placement`, see #link(<set-uraw-lib>)[`set-uraw`] for more details).
    ],
  ),

  (
    6,
    [
      Each jump is given as `(from, to)` or a dictionary with `from`, `to`, whether to `skip-lines (bool)` of the raw text, and the associated comment parameters (`comment`, `indent`, `fill`, `sep`, `marker`, `marker-fill`, `marker-placement`, see #link(<set-uraw-lib>)[`set-uraw`] for more details). `from` and `to` take integer values or `start` and `end`.
    ],
  ),

  (
    7,
    [
      Whether the block continues a previous one; it then renders as after a page break (no top radius, no top stroke, etc.). For a correct numbering and to display the accurate width of the numbers column, an integer value represents the last line of the preceding block, content is the widest marker of the preceding blocks (the marker column being shown and made wide enough for it), and a pair `(number, marker)` gives both.
    ],
  ),

  (
    8,
    [
      Whether the block is continued by a next one; it then renders as before a page break (no bottom radius, no bottom stroke, etc.). To display the accurate width of the numbers column, an integer value is the largest line number of the following blocks, content is their widest marker, and a pair `(number, marker)` gives both.
    ],
  ),

  (
    9,
    [
      Either the whole document to apply the show rule (`#show: uraw`), some raw text block to format, a path indicating the file to read the code from, or the dictionary output of #link(<read-code-lib>)[`read-code`].
    ],
  ),
)

= #f(`set-uraw`) <set-uraw-lib>

#documentation(
  ```typ
  #set-uraw(..args *htargumentsht*)
  ```,

  description: [Set the `uraw` configuration, specific to a language if one is mentioned.],

  (
    1,
    [
      The optional language and the configuration settings. The language is given as a positional argument; the settings are given as named arguments. Here is the complete list of settings by category with their type and default value (set by `themes.pre-themes.pre-default`) (you can click on #octique-inline("search", color: blue) to jump to the documentation of a parameter):

      #documentation(
        label: "set-uraw-args-doc",
        ```typ
        ***code***: (
          line-spacing *htlength autoht*: auto,
          theme *htbytes str auto noneht*: auto,
          color *htfunction color gradient tiling auto noneht*: auto,
          fill *htfunction color gradient tiling noneht*: none,
          indentation *htlength color gradient stroke tiling noneht*: gray,
          indented-line-return *htboolht*: true,
          indent-size *htint autoht*: auto,
        ),
        ***numbers***: (
          start *htint autoht*: auto,
          end *htint noneht*: none,
          format *htfunction str auto noneht*: auto,
          color *htfunction color gradient tiling auto noneht*: auto,
          fill *htfunction color gradient tiling auto noneht*: auto,
          gutter *htlength array autoht*: auto,
          sep *htlength color gradient stroke tiling noneht*: none,
          align *htalignmentht*: top + right,
        ),
        ***general***: (
          coloring-follow-numbers *htboolht*: true,
          markers-over-numbers *htboolht*: false,
          line-reference *htfunctionht*: n => ", line " + str(n) + ",",
          default-stroke-thickness *htlengthht*: .5pt,
        ),
        ***header***: (
          content *htcontent noneht*: none,
          color *htcolor gradient tiling auto noneht*: auto,
          fill *htcolor gradient tiling auto noneht*: none,
          repeat *htboolht*: false,
          sep *htlength color gradient stroke tiling auto noneht*: auto,
          inset *htrelative dictionaryht*: 5pt,
          align *htalignmentht*: left + horizon,
          code-aligned *htboolht*: false,
        ),
        ***footer***: (
          content *htcontent noneht*: none,
          color *htcolor gradient tiling auto noneht*: auto,
          fill *htcolor gradient tiling auto noneht*: none,
          repeat *htboolht*: false,
          sep *htlength color gradient stroke tiling auto noneht*: auto,
          inset *htrelative dictionaryht*: 5pt,
          align *htalignmentht*: left + horizon,
          code-aligned *htboolht*: false,
        ),
        ***frame***: (
          breakable *htboolht*: true,
          sharp-page-break *htboolht*: true,
          width *htrelative autoht*: auto,
          fill *htcolor gradient tiling noneht*: none,
          stroke *htlength color gradient stroke tiling dictionary noneht*: none,
          radius *htrelative dictionaryht*: 1mm,
          inset *htlength dictionaryht*: (x: 3pt),
        ),
        ***lang-tag***: (
          visible *htboolht*: true,
          name *htcontent auto noneht*: auto,
          icon *htcontent noneht*: none,
          placement *htstrht*: "code",
          spacing *htlengthht*: 5pt,
          color *htcolor gradient tiling auto noneht*: auto,
          fill *htcolor gradient tiling auto noneht*: luma(230),
          radius *htrelative dictionaryht*: 2pt,
          stroke *htlength color gradient stroke tiling dictionary auto noneht*: auto,
        ),
        ***highlight***: (
          fill *htcolor gradient tiling noneht*: none,
          stroke *htlength color gradient stroke tiling noneht*: none,
          radius *htrelative dictionaryht*: 3pt,
          code-style *htfunctionht*: it => it,
          sticky *htbool autoht*: auto,
          expand *htalignment auto noneht*: auto,
        ),
        ***comment***: (
          style *htfunctionht*: text.with(style: "italic"),
          indent *htstrht*: "frame",
          fill *htcolor gradient tiling noneht*: luma(245),
          sep *htlength color gradient stroke tiling dictionary noneht*: none,
          marker *htcontent noneht*: none,
          marker-fill *htcolor gradient tiling auto noneht*: auto,
          marker-placement *htstrht*: "numbers",
        ),
        ***jump***: (
          comment *htcontent function noneht*: none,
          style *htfunction autoht*: auto,
          indent *htstr autoht*: auto,
          fill *htcolor gradient tiling auto noneht*: auto,
          sep *htlength color gradient stroke tiling dictionary auto noneht*: auto,
          marker *htcontent auto noneht*: auto,
          marker-fill *htcolor gradient tiling auto noneht*: auto,
          marker-placement *htstr autoht*: auto,
        ),
        ***diff*** *htdictionaryht*: (..),
        ```,

        description: alert[In the following, the arguments are given in order and their name is shown in the most compact form.],

        (
          2,
          [The space between the lines, `auto` being the leading of the paragraphs (`par.leading`).],
        ),

        (
          3,
          [The syntax highlighting theme, as the `theme` of `raw`.],
        ),

        (
          4,
          "code-color",
          [The color of the code, `auto` and `none` being the color of the text of the document, a function gives the color from the line number (e.g. `n => if calc.even(n) { blue } else { red }`).],
        ),

        (
          5,
          "code-fill",
          [The background of the code, `none` being the one of the frame, a function gives the background from the line number.],
        ),

        (
          6,
          [The stroke of the indentation guidelines, `none` for no guidelines.],
        ),

        (
          7,
          [Whether the code after a line return starts at the indentation of its line, or at the left.],
        ),

        (
          8,
          [The number of spaces of an indent, `auto` detecting it from the most common indent increase.],
        ),

        (
          11,
          [The number of the first line, `auto` being 1 or the first line read with #link(<read-code-lib>)[`read-code`].],
        ),

        (
          12,
          [The number of the last line, which overrides `start` when it is not `none`.],
        ),

        (
          13,
          "numbers",
          [How the numbers are displayed: a function gives some content from the number (e.g. `n => strong(str(n))`), a string must contain a `1` replaced by the number (e.g. `"1:"`), `auto` displays the number and `none` hides the numbers.],
        ),

        (
          14,
          "numbers-color",
          [The color of the numbers, `auto` being the one of the code, `none` the color of the text of the document, a function gives it from the line number.],
        ),

        (
          15,
          "numbers-fill",
          [The background of the numbers, `auto` being the one of the code, `none` the one of the frame, a function gives it from the line number.],
        ),

        (
          16,
          "numbers-gutter",
          [The space between the numbers and the code: a pair `(before, after)` gives the spaces before and after the separator, a relative length `l` is `(l / 2, l / 2)`, `auto` is `(frame.inset.left, frame.inset.right)`.],
        ),

        (
          17,
          "numbers-sep",
          [The separator line between the numbers (and markers) and the code.],
        ),

        (
          18,
          "numbers-align",
          [The alignment of the numbers in their cells (markers share the same vertical alignment but are centered horizontally).],
        ),

        (
          21,
          [Whether the coloring functions (`fill`, `color`) take the line numbers, or the absolute positions of the lines in the block.],
        ),

        (
          22,
          [Whether the markers are displayed over the numbers (rather than in their own column), a line whose number is hidden by a marker can still be referenced with `@label.n`.],
        ),

        (
          23,
          [The text written after "Listing ..." when referencing a line.],
        ),

        (
          24,
          [The thickness of the strokes given without one.],
        ),

        (
          27,
          "header",
          [The content of the header or footer, `none` for no header or footer.],
        ),

        (
          28,
          "header-color",
          [The color of the text of the header or footer, `auto` being the one of the code, `none` being the color of the text of the document.],
        ),

        (
          29,
          "header-fill",
          [The background color, with `auto` it is the code background color at line `numbers.start - 1` (useful for striped code styles), with `none` it is the background color of the frame.],
        ),

        (
          30,
          "header-repeat",
          [Whether the header or footer of a raw block should be repeated at page breaks or when chaining blocks with `follows` and `precedes`.],
        ),

        (
          31,
          "header-sep",
          [The separator line between the header or footer and the code, `auto` is the same as the frame's stroke.],
        ),

        (
          32,
          "header-inset",
          [The inset of the header or footer block.],
        ),

        (
          33,
          "header-align",
          [The alignment of the content of the header or footer.],
        ),

        (
          34,
          "header-code-aligned",
          [Whether to align the header or footer content with the code (when numbers or markers are visible).],
        ),

        (
          37,
          "footer",
          [The content of the header or footer, `none` for no header or footer.],
        ),

        (
          38,
          "footer-color",
          [The color of the text of the header or footer, `auto` being the one of the code, `none` being the color of the text of the document.],
        ),

        (
          39,
          "footer-fill",
          [The background color, with `auto` it is the code background color at line `numbers.start - 1` (useful for striped code styles), with `none` it is the background color of the frame.],
        ),

        (
          40,
          "footer-repeat",
          [Whether the header or footer of a raw block should be repeated at page breaks or when chaining blocks with `follows` and `precedes`.],
        ),

        (
          41,
          "footer-sep",
          [The separator line between the header or footer and the code, `auto` is the same as the frame's stroke.],
        ),

        (
          42,
          "footer-inset",
          [The inset of the header or footer block.],
        ),

        (
          43,
          "footer-align",
          [The alignment of the content of the header or footer.],
        ),

        (
          44,
          "footer-code-aligned",
          [Whether to align the header or footer content with the code (when numbers or markers are visible).],
        ),

        (
          47,
          [Whether the raw block is breakable.],
        ),

        (
          48,
          [At page breaks, when `false` the raw block is displayed within two frame blocks (normal Typst processing), when `true` the frame block appears cut in half (no border, no radius, no inset along the page break).],
        ),

        (
          49,
          [The total width of the raw block.],
        ),

        (
          50,
          "frame-fill",
          [The background color of the whole raw block.],
        ),

        (
          51,
          "frame-stroke",
          [The border of the raw block.],
        ),

        (
          52,
          "frame-radius",
          [The radius of the raw block.],
        ),

        (
          53,
          "frame-inset",
          [The inset of the raw block.],
        ),

        (
          56,
          "lang-tag",
          [Whether to show the lang tag or not.],
        ),

        (
          57,
          "lang-tag-name",
          [The language name displayed in the lang tag, `auto` defaults to the raw block `lang`.],
        ),

        (
          58,
          "lang-tag-icon",
          [The icon displayed in the lang tag.],
        ),

        (
          59,
          "lang-tag-placement",
          [Where the lang tag is displayed: `"inline"` places it on the first line of code; `"code"` is like `"inline"` but the vertical space for the lang tag is reserved on all the lines of the code; `"header"` places it in the header and defaults to `"code"` when there is no header; the rest (`"top-left"`, `"top"`, `"top-right"`, `"left-top"`, `"left"`, `"left-bottom"`, `"right-top"`, `"right"`, `"right-bottom"`, `"bottom-left"`, `"bottom"`, `"bottom-right"`) place it on the border of the frame, the first location indicates the frame side while the second indicates the placement on that side (no second location is like `center` or `horizon`).],
        ),

        (
          60,
          "lang-tag-spacing",
          [The spacing between the lang tag and the content when the placement is `"inline"`, `"code"` or `"header"`.],
        ),

        (
          61,
          "lang-tag-color",
          [The color of the language name in the lang tag, `auto` is the same as the code's color, `none` is the same as the document's text color.],
        ),

        (
          62,
          "lang-tag-fill",
          [The background color of the lang tag, `auto` defaults to the frame's background color.],
        ),

        (
          63,
          "lang-tag-radius",
          [The radius of the lang tag.],
        ),

        (
          64,
          "lang-tag-stroke",
          [The border of the lang tag, `auto` defaults to the frame's border.],
        ),

        (
          67,
          "highlight-fill",
          [The background color of the highlight block.],
        ),

        (
          68,
          "highlight-stroke",
          [The border of the highlight block.],
        ),

        (
          69,
          "highlight-radius",
          [The radius of the highlight block.],
        ),

        (
          70,
          "highlight-code-style",
          [A styling function to apply to the highlighted content.],
        ),

        (
          71,
          "highlight-sticky",
          [Whether the parts of the highlight merge from one line to the next (the stroke and radius are changed accordingly), `auto` sets this parameter automatically: a highlight defined with `line` is sticky while others are not.],
        ),

        (
          72,
          "highlight-expand",
          [The side on which the highlight expands when going from one line to the next (`none` = no expansion, `left` = left side, `right` = right side, `center` = both sides), `auto` sets this parameter automatically: a highlight defined with `line` expands on both sides while others don't expand.],
        ),

        (
          75,
          "comment-style",
          [A basic style to apply to the content of all comments.],
        ),

        (
          76,
          "comment-indent",
          [`"frame"` to align with the left of the frame; `"code"` to start at the same left inset as the code; `"line"` to have the same indentation as the targeted line; `"guideline"` to further draw indentation lines in the comment.],
        ),

        (
          77,
          "comment-fill",
          [The background color of the comment, `none` is the same as the frame's background color.],
        ),

        (
          78,
          "comment-sep",
          [The separators at the `top` or `bottom` between the code and other comments that don't have a separator on the shared side; if it is not a dictionary, the style applies to both separators.],
        ),

        (
          79,
          "comment-marker",
          [The marker of the comment.],
        ),

        (
          80,
          "comment-marker-fill",
          [The background color of the comment's marker, `auto` is the comment's background color, `none` is the numbers column background color.],
        ),

        (
          81,
          "comment-marker-placement",
          [The placement of the marker inside the numbers column: in the space reserved for `"numbers"` or for `"markers"`.],
        ),

        (
          84,
          "jump-comment",
          [The default comment content associated with jumps, a function taking the bounds of the jump `from` and `to` as arguments.],
        ),

        (
          85,
          "jump-style",
          [As for `comment-style`, `auto` being the same as `comment-style`.],
        ),

        (
          86,
          "jump-indent",
          [As for `comment-indent`, `auto` being the same as `comment-indent`.],
        ),

        (
          87,
          "jump-fill",
          [As for `comment-fill`, `auto` being the same as `comment-fill`.],
        ),

        (
          88,
          "jump-sep",
          [As for `comment-sep`, `auto` being the same as `comment-sep`.],
        ),

        (
          89,
          "jump-marker",
          [As for `comment-marker`, `auto` being the same as `comment-marker`.],
        ),

        (
          90,
          "jump-marker-fill",
          [As for `comment-marker-fill`, `auto` being the same as `comment-marker-fill`.],
        ),

        (
          91,
          "jump-marker-placement",
          [As for `comment-marker-placement`, `auto` being the same as `comment-marker-placement`.],
        ),

        (
          93,
          "diff",
          [The settings of diffs, as for #link(<set-uraw-diff-lib>)[`set-uraw-diff`].],
        ),
      )
    ],
  ),
)

= #f(`get-uraw`) <get-uraw-lib>

#documentation(
  ```typ
  #get-uraw(..lang *htargumentsht*)
  ```,

  description: [Get the current `uraw` configuration, specific to a language if one is mentioned. The context must be known to call this function.],

  (
    1,
    [The optional language name as a positional argument.],
  ),
)

= #f(`uraw-inline`) <uraw-inline-lib>

#documentation(
  ```typ
  #uraw-inline(
    lang *htnone strht*: none,
    highlights *htarray dictionaryht*: (),
    body *htstr contentht*,
  )
  ```,

  description: [Display inline code with the same settings as `uraw`.],

  (
    2,
    [The language of the code.],
  ),

  (
    3,
    [For each highlight, the range it covers is given either by `start (int)` and `end (int)` or `range ((int, int))`. Default values of `start` and `end` are the first and the last characters. Each highlight can have specific styling parameters (`fill`, `stroke`, `radius`, `code-style`, see #link(<set-uraw-lib>)[`set-uraw`] for more details).],
  ),

  (
    4,
    [The code to be displayed.],
  ),
)

= #f(`uraw-diff`) <uraw-diff-lib>

#documentation(
  ```typ
  #uraw-diff(
    ..args *htargumentsht*,
    markers *htarray dictionaryht*: (),
    highlights *htarray dictionaryht*: (),
    comments *htarray dictionaryht*: (),
    jumps *htarray dictionaryht*: (),
    follows *htbool int content array dictionaryht*: false,
    precedes *htbool int content array dictionaryht*: false,
    old *htcontent path dictionaryht*,
    new *htcontent path dictionaryht*,
  )
  ```,

  description: [Display a diff between an old and a new version of some code.

    For `markers`, `highlights`, `comments` and `jumps`, a single entry, an array of entries or a dictionary grouping entries by version (`(old: ..., new: ...)`) are all valid. Under the dictionary form, entries are given without their `version`.
  ],

  (
    2,
    [The settings (see #link(<set-uraw-lib>)[`set-uraw`] and #link(<set-uraw-diff-lib>)[`set-uraw-diff`] for their description). The numbers `start` and `end` can be given by version, as `(old: ..., new: ...)` dictionaries.],
  ),

  (
    3,
    [Same as #link(<uraw-lib>, `uraw`) markers with a `version` field (first element when giving a marker as an array).],
  ),

  (
    4,
    [Same as #link(<uraw-lib>, `uraw`) highlights with a `version` field.],
  ),

  (
    5,
    [Same as #link(<uraw-lib>, `uraw`) comments with a `version` field (first element when giving a comment as an array). Additionally, comments can `span` over both code versions (see #link(<set-uraw-diff-lib>)[`set-uraw-diff`] for more details).],
  ),

  (
    6,
    [Same as #link(<uraw-lib>, `uraw`) jumps with a `version` field (first element when giving a jump as an array) and a possible `span` field for the comment (see #link(<set-uraw-diff-lib>)[`set-uraw-diff`] for more details).],
  ),

  (
    7,
    [Same as #link(<uraw-lib>, `uraw`), and it can be given by version as an `(old: ..., new: ...)` dictionary.],
  ),

  (
    8,
    [Same as #link(<uraw-lib>, `uraw`), and it can be given by version as an `(old: ..., new: ...)` dictionary.],
  ),

  (
    9,
    [The old code, given as a raw text block, a path indicating the file to read the code from, or the dictionary output of #link(<read-code-lib>)[`read-code`].],
  ),

  (
    10,
    [The new code, given as a raw text block, a path indicating the file to read the code from, or the dictionary output of #link(<read-code-lib>)[`read-code`].],
  ),
)

= #f(`set-uraw-diff`) <set-uraw-diff-lib>

#documentation(
  ```typ
  #set-uraw-diff(..args *htargumentsht*)
  ```,

  description: [Set the `uraw-diff` configuration, specific to a language if one is mentioned.],

  (
    1,
    [
      The optional language and the configuration settings. The language is given as a positional argument; the settings are given as named arguments. By default, diffs inherit the same settings as `uraw` (set by #link(<set-uraw-lib>)[`set-uraw`]) but `set-uraw-diff` updates the configuration for diffs only. In addition to the settings of `uraw` (see #link(<set-uraw-lib>)[`set-uraw`] for their description), here is the complete list of diff-only settings with their type and default value (set by `themes.pre-themes.pre-default`) (you can click on #octique-inline("search", color: blue) to jump to the documentation of a parameter):

      #documentation(
        label: "set-uraw-diff-args-doc",
        ```typ
        ***general***: (
          columns *htrelative ratio array autoht*: (auto, auto),
          column-gutter *htrelativeht*: 0pt,
          sep *htlength color gradient stroke tiling noneht*: gray,
          blank-fill *htcolor gradient tiling noneht*: style.hatch(luma(200)),
          line-reference *htfunctionht*: (n, version) => ", " + version + " line " + str(n) + ",",
        ),
        ***old***: (
          diff-marker *htcontentht*: text(red.darken(20%))[-],
          fill *htcolor gradient tiling noneht*: red.lighten(75%),
          numbers-color *htcolor gradient tiling auto noneht*: auto,
          numbers-fill *htcolor gradient tiling auto noneht*: rgb("#FF8B85"),
        ),
        ***new***: (
          diff-marker *htcontentht*: text(olive)[+],
          fill *htcolor gradient tiling noneht*: rgb("#32C04C").lighten(75%),
          numbers-color *htcolor gradient tiling auto noneht*: auto,
          numbers-fill *htcolor gradient tiling auto noneht*: rgb("#7CCBA7"),
        ),
        ***diff-marker***: (
          visible *htboolht*: true,
          gutter *htlengthht*: 3pt,
          unchanged *htcontentht*: [],
        ),
        ***comment***: (
          span *htboolht*: false,
        ),
        ***jump***: (
          span *htbool autoht*: auto,
        )
        ```,

        (
          2,
          [The columns of the diff, one column meaning that both versions are displayed in the same code part, working as the `columns` parameter of `grid`.],
        ),

        (
          3,
          [A separator space when there are two columns.],
        ),

        (
          4,
          [A separator line when there are two columns.],
        ),

        (
          5,
          [The background color of spaces that don't contain anything.],
        ),

        (
          6,
          [The text written after "Listing ..." when referencing a precise line.],
        ),

        (
          9,
          "old-diff-marker",
          [The marker associated with changes on old / new lines.],
        ),

        (
          10,
          "old-fill",
          [The background color of old / new lines of code where changes happened, `none` doesn't change the background.],
        ),

        (
          11,
          "old-numbers-color",
          [The color of the numbers on old / new lines that change, `auto` is the same color as the other numbers, `none` is the same as the document's text color.],
        ),

        (
          12,
          "old-numbers-fill",
          [The background color of numbers on old / new lines that change, `auto` is the same as `fill`, `none` is the background color of numbers.],
        ),

        (
          15,
          "new-diff-marker",
          [The marker associated with changes on old / new lines.],
        ),

        (
          16,
          "new-fill",
          [The background color of old / new lines of code where changes happened, `none` doesn't change the background.],
        ),

        (
          17,
          "new-numbers-color",
          [The color of the numbers on old / new lines that change, `auto` is the same color as the other numbers, `none` is the same as the document's text color.],
        ),

        (
          18,
          "new-numbers-fill",
          [The background color of numbers on old / new lines that change, `auto` is the same as `fill`, `none` is the background color of numbers.],
        ),

        (
          21,
          "diff-marker",
          [Whether the markers specific to diffs (lying in the code part) are shown.],
        ),

        (
          22,
          "diff-marker-gutter",
          [The space between the diff markers and the code.],
        ),

        (
          23,
          "diff-marker-unchanged",
          [The markers to use for lines with no changes.],
        ),

        (
          26,
          "comment-span",
          [Whether the comments span over both code versions, their marker being in the numbers column of the old code.],
        ),

        (
          29,
          "jump-span",
          [As for `comment-span`, `auto` being the same as `comment-span`.],
        ),
      )
    ],
  ),
)

= #f(`get-uraw-diff`) <get-uraw-diff-lib>

#documentation(
  ```typ
  #get-uraw-diff(..lang *htargumentsht*)
  ```,

  description: [Get the current `uraw-diff` configuration, specific to a language if one is mentioned. The context must be known to call this function.],

  (
    1,
    [The optional language name as a positional argument.],
  ),
)

= #f(`read-code`) <read-code-lib>

#documentation(
  ```typ
  #read-code(
    file *htpathht*,
    from *htintht*: 1,
    to *htint noneht*: none,
    lang *htstr auto noneht*: auto,
  )
  ```,

  description: [Read some code from a file, to display it with `uraw` or `uraw-diff`.],

  (
    2,
    [The file, given with `path` (a simple string is refused as it would be read relative to the package).],
  ),

  (
    3,
    [The first line read.],
  ),

  (
    4,
    [The last line read, `none` for the end of the file.],
  ),

  (
    5,
    [The language of the code, `auto` for the extension of the file.],
  ),
)

= #f(`uraw-pseudo`) <uraw-pseudo-lib>

#documentation(
  ```typ
  #uraw-pseudo(
    ..args *htargumentsht*,
    body *htcontentht*,
  )
  ```,

  description: [Display pseudo code.],

  (
    2,
    [The settings (see #link(<set-uraw-pseudo-lib>)[`set-uraw-pseudo`] for their description).],
  ),

  (
    3,
    [The lines of pseudo code as a numbered list. Comments are written with #link(<pseudo-comment-lib>)[`pseudo-comment`].],
  ),
)

= #f(`set-uraw-pseudo`) <set-uraw-pseudo-lib>

#documentation(
  ```typ
  #set-uraw-pseudo(..args *htargumentsht*)
  ```,

  description: [Set the `uraw-pseudo` configuration.],

  (
    1,
    [Pseudo codes have the same `code`, `numbers`, `general`, `header`, `footer`, `frame` and `comment` settings as `uraw` (see #link(<set-uraw-lib>)[`set-uraw`] for their description, see `themes.pre-themes.pseudo-pre-default` for the default values). The only exceptions are:
      - `indent-size` is now a length;
      - `code` has an additional `style` parameter that applies a styling function to pseudo code lines;
      - `general` has an additional `algorithm-figure` parameter that controls whether pseudo codes inside figures are counted as Algorithms or Figures (`#show: uraw` is required for the counting of Algorithms to work);
      - `theme`, `indented-line-return`, `lang-tag`, `markers-over-numbers`, `comment-marker-placement` are removed.
    ],
  ),
)

= #f(`get-uraw-pseudo`) <get-uraw-pseudo-lib>

#documentation(
  ```typ
  #get-uraw-pseudo()
  ```,

  description: [Get the current `uraw-pseudo` configuration. The context must be known to call this function.],
)

= #f(`pseudo-comment`) <pseudo-comment-lib>

#documentation(
  ```typ
  #pseudo-comment(
    ..args *htargumentsht*,
    body *htcontentht*,
  )
  ```,

  description: [Write a comment in pseudo code, between the lines where it is written.],

  (
    2,
    [The settings of the comment (`style`, `indent`, `fill`, `sep`, `marker`, `marker-fill`, see #link(<set-uraw-pseudo-lib>)[`set-uraw-pseudo`]).],
  ),

  (
    3,
    [The content of the comment.],
  ),
)

= #f(`pseudo-info`) <pseudo-info-lib>

#documentation(
  ```typ
  #pseudo-info(body *htcontentht*)
  ```,

  description: [Write a special information comment in pseudo code.],

  (
    1,
    [The information.],
  ),
)

= #f(`highlights`) <highlights-lib>

Sample highlights and functions to manage them. There are two highlights by default: `base` (`*|` and `|*`) and `alert` (`*!` and `!*`).

== #f(`add`)

#documentation(
  ```typ
  #highlights.add(..highlights *htargumentsht*)
  ```,

  description: [Add highlights to use them in raw text.],

  (
    1,
    [
      Each highlight to register is given as a dictionary. If some keys are omitted, their default values are given by the `highlight` setting of `uraw` or `uraw-diff`. The keys of the dictionary are:

      #documentation(
        ```typ
        (
          ldel *htstrht*,
          rdel *htstrht*,
          del *htstrht*,
          fill *htcolor gradient tiling noneht*,
          stroke *htlength color gradient stroke tiling noneht*,
          radius *htrelative dictionaryht*,
          code-style *htfunctionht*,
          sticky *htboolht*,
          expand *htalignment noneht*,
        )
        ```,

        (
          2,
          [The left delimiter of the highlight inside the raw text.],
        ),

        (
          3,
          [The right delimiter of the highlight inside the raw text.],
        ),

        (
          4,
          [Given instead of `ldel` and `rdel` to set both delimiters to the same value.],
        ),

        (
          5,
          [The background color of the highlight block.],
        ),

        (
          6,
          [The border of the highlight block.],
        ),

        (
          7,
          [The radius of the highlight block.],
        ),

        (
          8,
          [A styling function to apply to the highlighted content.],
        ),

        (
          9,
          [Whether the parts of the highlight merge from one line to the next (the stroke and radius are changed accordingly).],
        ),

        (
          10,
          [The side on which the highlight expands when going from one line to the next (`none` = no expansion, `left` = left side, `right` = right side, `center` = both sides).],
        ),
      )
    ],
  ),
)

== #f(`remove`)

#documentation(
  ```typ
  #highlights.remove(..delimiters *htargumentsht*)
  ```,

  description: [Remove highlights.],

  (
    1,
    [The delimiters of each highlight are a dictionary with either two keys `ldel` and `rdel` representing the left and right delimiters or a single key `del` representing both delimiters.],
  ),
)

== #f(`get`)

#documentation(
  ```typ
  #highlights.get(
    del *htstr noneht*: none,
    ldel *htstr noneht*: none,
    rdel *htstr noneht*: none,
  )
  ```,

  description: [Return the parameters of a highlight. The context must be known to call this function.],

  (
    2,
    [`del` represents both delimiters of the highlight. It overrides `ldel` and `rdel` if given.],
  ),

  (
    3,
    [The left delimiter of the highlight.],
  ),

  (
    4,
    [The right delimiter of the highlight.],
  ),
)

== #f(`list`)

#documentation(
  ```typ
  #highlights.list()
  ```,

  description: [List highlights. The context must be known to call this function.],
)

== #f(`base-style`)

#documentation(
  ```typ
  #highlights.base-style(color *htcolor gradient tilinght*)
  ```,

  description: [Return the styling parameters of the base highlight: a dimmed background with a plain border.],

  (
    1,
    [The color of the highlight.],
  ),
)

== #f(`base`)

#documentation(
  ```typ
  #highlights.base(color *htcolor gradient tilinght*: yellow)
  ```,

  description: [
    The base highlight: a dimmed background and a plain border. \
    #show-highlight(`#let *|rec|*(n) = rec(n + 1) + 1`)
  ],

  (
    1,
    [The color of the highlight.],
  ),
)

== #f(`square-style`)

#documentation(
  ```typ
  #highlights.square-style(color *htcolor gradient tilinght*)
  ```,

  description: [Return the styling parameters of a square highlight: no border and a plain background.],

  (
    1,
    [The color of the highlight.],
  ),
)

== #f(`alert-style`)

#documentation(
  ```typ
  #highlights.alert-style(color *htcolor gradient tilinght*)
  ```,

  description: [Return the styling parameters of an alert highlight: no border, a plain background and strong white highlighted code.],

  (
    1,
    [The color of the highlight.],
  ),
)

== #f(`alert`)

#documentation(
  ```typ
  #highlights.alert(color *htcolor gradient tilinght*: red)
  ```,

  description: [
    The alert highlight: no border, a plain background and strong white highlighted code. \
    #show-highlight(`#let rec(n) = *!rec!*(n + 1) + 1`)
  ],

  (
    1,
    [The color of the highlight.],
  ),
)

== #f(`hole`)

#documentation(
  ```typ
  #highlights.hole(color *htcolor gradient tilinght*: black)
  ```,

  description: [
    The hole highlight: no background, hidden code and a dashed border. \
    #show-highlight(`#let rec(n) = *?rec(n + 1) +?* 1`)
  ],

  (
    1,
    [The color of the dashed border.],
  ),
)

== #f(`strike`)

#documentation(
  ```typ
  #highlights.strike(color *htcolor gradient tilinght*: red)
  ```,

  description: [
    A highlight that strikes through the code. \
    #show-highlight(`#let rec(n) = *-rec(n + 1) +-* 1`)
  ],

  (
    1,
    [The color of the strike line.],
  ),
)

== #f(`underline`)

#documentation(
  ```typ
  #highlights.underline(color *htcolor gradient tilinght*: black)
  ```,

  description: [
    A highlight that underlines the code. \
    #show-highlight(`#let rec(n) = rec(*_n + 1_*) + 1`)
  ],

  (
    1,
    [The color of the underlining line.],
  ),
)

== #f(`strong`)

#documentation(
  ```typ
  #highlights.strong
  ```,

  description: [
    A highlight that renders the code bold. \
    #show-highlight(`#let ***rec***(n) = ***rec***(n + 1) + 1`)
  ],
)

= #f(`themes`) <themes-lib>

The themes of the `ultraw` package and support functions for making new themes.

Available themes are #raw(lang: "typ", "#themes.default"), #raw(lang: "typ", "#themes.dark"), #raw(lang: "typ", "#themes.note"), #raw(lang: "typ", "#themes.window") and #raw(lang: "typ", "#themes.pseudo-default") for pseudo code.

The #raw(lang: "typ", "#themes.pre-themes") module gives access to the pre-themes.

== #f(`make`) <themes-make-lib>

#documentation(
  ```typ
  #themes.make(pre-theme *htdictionaryht*)
  ```,

  description: [Make a theme of `uraw` and `uraw-diff` from a pre-theme.],

  (
    1,
    [The pre-theme to format, look at `themes.pre-themes.pre-default` for an example.],
  ),
)

== #f(`make-pseudo`) <themes-make-pseudo-lib>

#documentation(
  ```typ
  #themes.make-pseudo(pre-theme *htdictionaryht*)
  ```,

  description: [Make a theme of `uraw-pseudo` from a pre-theme.],

  (
    1,
    [The pre-theme to format, look at `themes.pre-themes.pseudo-pre-default` for an example.],
  ),
)

= #f(`raw-themes`) <raw-themes-lib>

The themes for raw text. Available themes are #raw(lang: "typ", "#raw-themes.typst-dark"), #raw(lang: "typ", "#raw-themes.github-light") and #raw(lang: "typ", "#raw-themes.github-dark").

= #f(`style`) <style-lib>

A collection of styling functions.


== #f(`zebra`)

#documentation(
  ```typ
  #style.zebra(
    odd *htcolor gradient tiling noneht*: none,
    even *htcolor gradient tiling noneht*: none,
  )
  ```,

  description: [Return a coloring function alternating between two colors.],

  (
    2,
    [The color of odd lines.],
  ),

  (
    3,
    [The color of even lines.],
  ),
)

== #f(`exact`)

#documentation(
  ```typ
  #style.exact(
    ..lines *htargumentsht*,
    rest *htcolor gradient tiling noneht*: none,
  )
  ```,

  description: [Return a coloring function that assigns precise colors to ranges of lines.],

  (
    2,
    [Each positional argument must be a pair `(line, color)` where `line` is either an integer or a pair of integers `(from, to)` representing a range of lines and where `color` is the color used for the associated lines.],
  ),

  (
    3,
    [The color for the rest of the lines.],
  ),
)

== #f(`focus`)

#documentation(
  ```typ
  #style.focus(
    ..lines *htargumentsht*,
    color *htcolorht*: black,
    rest *htratio color gradient tilinght*: 60%,
  )
  ```,

  description: [Return a coloring function that applies focus to the given lines with some color.],

  (
    2,
    [Each positional argument is either an integer or a pair of integers `(from, to)` representing a range of lines.],
  ),

  (
    3,
    [The color used for the specified lines.],
  ),

  (
    4,
    [Either a transparency ratio mitigating `color` or a color for the unfocused lines.],
  ),
)

== #f(`hatch`)

#documentation(
  ```typ
  #style.hatch(color *htcolor gradient tilinght*)
  ```,

  description: [A hatching tiling.],

  (
    1,
    [The color of the hatching.],
  ),
)

== #f(`padded`)

#documentation(
  ```typ
  #style.padded(n-digits *htintht*)
  ```,

  description: [Return a function padding numbers with 0s.],

  (
    1,
    [The number of digits to pad to.],
  ),
)

== #f(`callout-marker`)

#documentation(
  ```typ
  #style.callout-marker(
    body *htint contentht*,
    color *htcolor gradient tilinght*: black,
  )
  ```,

  description: [Create a marker made of encircled content.],

  (
    2,
    [The encircled integer or content.],
  ),

  (
    3,
    [The color of the marker.],
  ),
)

== #f(`badge-marker`)

#documentation(
  ```typ
  #style.badge-marker(color *htcolor gradient tilinght*: black)
  ```,

  description: [Create a dot marker.],

  (
    1,
    [The color of the badge marker.],
  ),
)

== #f(`vdots-jump`)

#documentation(
  ```typ
  #style.vdots-jump(
    from *htintht*,
    to *htintht*,
    numbers *htboolht*: true,
    code *htboolht*: false,
    ..comment *htargumentsht*,
  )
  ```,

  description: [Create a jump that displays a comment containing vertical dots.],

  (
    2,
    [The starting line of the jump.],
  ),

  (
    3,
    [The ending line of the jump.],
  ),

  (
    4,
    [Whether to show vertical dots in the numbers column.],
  ),

  (
    5,
    [Whether to show vertical dots in the code.],
  ),

  (
    6,
    [The styling parameters of the comment.],
  ),
)

== #f(`window-header`)

#documentation(
  ```typ
  #style.window-header(body *htcontentht*)
  ```,

  description: [Create a header styled like a macOS window.],

  (
    1,
    [The content of the header.],
  ),
)

== #f(`icons`) <icons-lib>

#documentation(
  ```typ
  #style.icons *htdictionaryht*
  ```,

  description: [A map from common languages to their icon.],
)
