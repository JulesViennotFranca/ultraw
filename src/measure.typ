#import "content.typ" as ct

/// Return the maximum width of numbers.
///
/// - line-numbers (array): The displayed line numbers.
/// - format (function): Format a number.
/// -> length
/// - monotonic (bool): Wether the widest numbers are the first and the last ones (as for the numbers themselves), so that only them are measured.
#let numbers-width(line-numbers, format: str, monotonic: false) = calc.max(
  0pt,
  ..if monotonic and line-numbers.len() > 2 {
    (line-numbers.first(), line-numbers.last())
  } else { line-numbers }.map(n => measure(format(n)).width),
)

/// Return the maximum width of the code.
///
/// - layout-size (dictionary): The layout dimensions.
/// - frame (dictionary): The frame parameters.
/// - code (dictionary): The code parameters.
/// - numbers-width (length):
/// -> length
#let available-code-width(layout-size, frame, code, numbers-width) = {
  let frame-width = if frame.width == auto {
    layout-size.width
  } else if type(frame.width) == ratio {
    layout-size.width * frame.width
  } else {
    frame.width
  }

  return (
    frame-width - numbers-width - (code.inset.left + code.inset.right)
  ).to-absolute()
}

/// Return the actual width filled by the code.
///
/// - frame (dictionary): The frame parameters.
/// - code-width (length):
/// - lang-tag (dictionary): The parameters of the lang tag.
/// - it-lines (array): The formatted lines of the document.
/// -> length
#let tight-code-width(frame, code-width, lang-tag, it-lines) = {
  if frame.width == auto {
    let lines-width = it-lines.map(l => l.slines.map(sl => {
      if "estimated-width" in sl { sl.estimated-width } else {
        measure(sl.body).width
      }
    }))

    if lang-tag.placement == "inline" and lines-width.len() > 0 {
      lines-width.at(0).at(0) += lang-tag.width
    } else if lang-tag.placement == "code" {
      lines-width = lines-width.map(sl => sl.map(w => w + lang-tag.width))
    }

    lines-width = lines-width.map(lens => calc.max(..lens))

    return calc.min(code-width, calc.max(..lines-width))
  } else {
    return code-width
  }
}

/// The code width when the header and footer are taken into account.
///
/// - header-width (length):
/// - numbers-width (length):
/// - code (dictionary): The code parameters.
/// - code-width (length):
/// - footer-width (length):
/// -> length
#let hf-code-width(
  header-width,
  numbers-width,
  code,
  code-width,
  footer-width,
) = {
  calc.max(
    code-width,
    (
      header-width - numbers-width - code.inset.left - code.inset.right
    ).to-absolute(),
    (
      footer-width - numbers-width - code.inset.left - code.inset.right
    ).to-absolute(),
  )
}

/// The code width when the comments are taken into account.
///
/// - frame (dictionary): The frame parameters.
/// - comments (array): The formatted comments.
/// - numbers-width (length):
/// - code (dictionary): The code parameters.
/// - code-width (length):
/// - max-code-width (length): The maximum width available for the code.
/// -> length
#let comments-code-width(
  frame,
  comments,
  numbers-width,
  code,
  code-width,
  max-code-width,
) = if frame.width == auto {
  calc.max(
    code-width,
    ..comments.map(c => calc.min(
      max-code-width,
      (
        c.inset.left
          + measure(c.body).width
          + c.inset.right
          - if c.spans { numbers-width } else { 0mm }
          - code.inset.left
          - code.inset.right
      ).to-absolute(),
    )),
  )
} else {
  code-width
}
