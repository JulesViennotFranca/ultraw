# ultraw

**`ultraw`** is a Typst package that let's you customize raw text. It provides many features like highlighting some code, adding markers and comments, jumping over lines, a dark and other themes, presenting diffs and writing pseudo code.

## Overview

![overview](assets/overview.png)

## Starting

The main function of the **`ultraw`** package is `uraw`. It can be used as a show rule for the whole document to format all raw blocks or per raw block to have precise settings, markers, comments, highlights, etc. The two following examples produce the same results:

![basic](assets/basic.png)

The `set-uraw` function enables changing the settings of `uraw` globally, for example to change the theme:

![set-uraw-theme](assets/set-uraw-theme.png)

## Highlights

**`ultraw`** provides a lightweight, quick and robust way to highlight raw text by typing highlights delimiters right inside the raw block:

![highlights1](assets/highlights1.png)

By default only the base (`*:...:*`) and alert (`*!...!*`) highlights are available. Other highlights are provided and can be added using the `highlights` module. Highlights can also be defined locally when using the `uraw` function:

![highlights2](assets/highlights2.png)

## Markers, comments, jumps

Markers (lying in the numbers column), comments (between lines of code) and jumps (skiping numbers and possibly raw text lines) are available. Here are some examples:

## More styling

Code, numbers, header & footer, frame, lang-tag

## Diffs

## Pseudo code

## Themes

## TODO

- show diff, pseudo code
- show markers, highlights, comments, etc
