#import "../src/config.typ": make-diff-theme, make-pseudo-theme, make-theme
#import "pre-themes.typ": *

#let default = make-theme(pre-default)
#let diff-default = make-diff-theme(pre-default)
#let pseudo-default = make-pseudo-theme(pseudo-pre-default)

#let note = make-theme(pre-note)
#let diff-note = make-diff-theme(pre-note)

#let dark = make-theme(pre-dark)
#let diff-dark = make-diff-theme(pre-dark)
