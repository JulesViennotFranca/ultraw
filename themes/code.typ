/// Code themes (syntax highlighting), to give to the `theme` of the code (as bytes, so that they do not depend on the file using them).

/// The default theme of Typst, made lighter for a dark background.
#let typst-dark = read("typst-dark.tmTheme", encoding: none)
