#import "../src/utils.typ" as ut

/// A list of icons for common languages.
#let pre-icons = (
  (("typ", "typst"), (icon: image("icons/typst.png"))),
  (("typc",), (icon: image("icons/typst.png"))),
  (("typm",), (icon: image("icons/typst.png"))),
  (("js", "javascript"), (icon: image("icons/javascript.png"))),
  (("html", "htm", "shtml", "xhtml"), (icon: image("icons/html.png"))),
  (("css",), (icon: image("icons/css.png"))),
  (("sql",), (icon: image("icons/sql.png"))),
  (
    ("py", "py3", "pyw", "pyi", "pyx", "pxd", "pxi", "rpy", "cpy", "python"),
    (icon: image("icons/python.png")),
  ),
  (("sh", "bash", "zsh", "ash"), (icon: image("icons/bash.png"))),
  (("typescript", "ts"), (icon: image("icons/typescript.png"))),
  (("java",), (icon: image("icons/java.png"))),
  (("cs",), (icon: image("icons/csharp.png"))),
  (("cpp",), (icon: image("icons/cpp.png"))),
  (("c",), (icon: image("icons/c.png"))),
  (("php",), (icon: image("icons/php.png"))),
  (("go",), (icon: image("icons/go.png"))),
  (("rs", "rust"), (icon: image("icons/rust.png"))),
  (("ocaml", "ml"), (icon: image("icons/ocaml.png"))),
  (("rocq",), (icon: image("icons/rocq.png"))),
)

#let pre-icons = ut.keys-value-to-dict(pre-icons)

/// A list of icons for common languages.
#let icons = pre-icons.map(i => i.icon)
