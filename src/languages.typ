#import "utils.typ" as ut

/// A list of lang tag settings for common languages.
#let pre-lang-tag-config = (
  (("typ", "typst"), (icon: image("../styling/icons/typst.png"))),
  (("typc",), (icon: image("../styling/icons/typst.png"))),
  (("typm",), (icon: image("../styling/icons/typst.png"))),
  (("js", "javascript"), (icon: image("../styling/icons/javascript.png"))),
  (
    ("html", "htm", "shtml", "xhtml"),
    (icon: image("../styling/icons/html.png")),
  ),
  (("css",), (icon: image("../styling/icons/css.png"))),
  (("sql",), (icon: image("../styling/icons/sql.png"))),
  (
    ("py", "py3", "pyw", "pyi", "pyx", "pxd", "pxi", "rpy", "cpy", "python"),
    (icon: image("../styling/icons/python.png")),
  ),
  (("sh", "bash", "zsh", "ash"), (icon: image("../styling/icons/bash.png"))),
  (("typescript", "ts"), (icon: image("../styling/icons/typescript.png"))),
  (("java",), (icon: image("../styling/icons/java.png"))),
  (("cs",), (icon: image("../styling/icons/csharp.png"))),
  (("cpp",), (icon: image("../styling/icons/cpp.png"))),
  (("c",), (icon: image("../styling/icons/c.png"))),
  (("php",), (icon: image("../styling/icons/php.png"))),
  (("go",), (icon: image("../styling/icons/go.png"))),
  (("rs", "rust"), (icon: image("../styling/icons/rust.png"))),
  (("ocaml", "ml"), (icon: image("../styling/icons/ocaml.png"))),
  (("rocq",), (icon: image("../styling/icons/rocq.png"))),
)

#let lang-tag-config = ut.keys-value-to-dict(pre-lang-tag-config)

/// A map from common languages to their icon.
#let icons = lang-tag-config.map(i => i.icon)
