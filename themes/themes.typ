#import "../src/config.typ": make-diff-theme, make-pseudo-theme, make-theme
#import "pre-themes.typ": pre-dark, pre-default, pseudo-pre-default

#let default = make-theme(pre-default)
#let diff-default = make-diff-theme(pre-default)
#let pseudo-default = make-pseudo-theme(pseudo-pre-default)

#let dark = make-theme(pre-dark)
#let diff-dark = make-diff-theme(pre-dark)
