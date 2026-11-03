// (imports inside blocks, so that the module only gives the themes and the functions making them)
#let (make, make-diff, make-pseudo) = {
  import "../src/config.typ": make-diff-theme, make-pseudo-theme, make-theme
  (make-theme, make-diff-theme, make-pseudo-theme)
}

#let (default, diff-default, pseudo-default) = {
  import "pre-themes.typ": pre-default, pseudo-pre-default
  (make(pre-default), make-diff(pre-default), make-pseudo(pseudo-pre-default))
}

#let (dark, diff-dark) = {
  import "pre-themes.typ": pre-dark
  (make(pre-dark), make-diff(pre-dark))
}

#let (note, diff-note) = {
  import "pre-themes.typ": pre-note
  (make(pre-note), make-diff(pre-note))
}

#let (window, diff-window) = {
  import "pre-themes.typ": pre-window
  (make(pre-window), make-diff(pre-window))
}
