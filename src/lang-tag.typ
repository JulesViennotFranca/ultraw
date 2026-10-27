#import "utils.typ" as ut

/// Check that the mode of the lang tag is correct.
///
/// - mode (str):
/// -> none
#let check-lang-tag-mode(mode) = assert(
  mode == "icon" or mode == "name" or mode == "full",
  message: "Wrong mode for the language tag.",
)

/// Check that the placement of the lang tag is correct.
///
/// - plcmt (str):
/// -> none
#let check-lang-tag-placement(plcmt) = assert(
  plcmt == "code"
    or plcmt == "header"
    or plcmt == "inline"
    or plcmt == "top-left"
    or plcmt == "top"
    or plcmt == "top-right"
    or plcmt == "left-top"
    or plcmt == "left"
    or plcmt == "left-bottom"
    or plcmt == "right-top"
    or plcmt == "right"
    or plcmt == "right-bottom"
    or plcmt == "bottom-left"
    or plcmt == "bottom"
    or plcmt == "bottom-right",
  message: "Wrong placement for the language tag.",
)

/// Return for every position wether the lang tag occupies it.
///
/// - lt (dictionary):
/// -> array
#let lang-tag-position(lt) = {
  let is-top = (
    lt.placement == "top-left"
      or lt.placement == "top"
      or lt.placement == "top-right"
  )
  let is-left = (
    lt.placement == "left-top"
      or lt.placement == "left"
      or lt.placement == "left-bottom"
  )
  let is-right = (
    lt.placement == "right-top"
      or lt.placement == "right"
      or lt.placement == "right-bottom"
  )
  let is-bottom = (
    lt.placement == "bottom-left"
      or lt.placement == "bottom"
      or lt.placement == "bottom-right"
  )

  assert(
    is-top or is-left or is-right or is-bottom,
    message: "The placement of the language tag should be a string among the following: 'top-left', 'top', 'top-right', 'left-top', 'left', 'left-bottom', 'right-top', 'right', 'right-bottom', 'bottom-left', 'bottom' or 'bottom-right'.",
  )

  return (is-top, is-left, is-right, is-bottom)
}

/// Return a dictionary containing no or one field. If applied to a dictionary, it keeps the field of the dictionary if it was present, otherwise create a dictionary with that field and value the input.
///
/// - d ():
/// - k (str): The name of the field.
/// -> dictionary
#let df(d, k) = if type(d) == dictionary {
  if k in d { ((k): d.at(k)) } else { (:) }
} else {
  let nd = (:)
  nd.insert(k, d)
  nd
}

/// Create the content present inside of the lang tag.
///
/// - lang (str): The language of the raw code.
/// - lt (dictionary): The lang tag parameters.
/// -> box
#let lang-tag-content(lang, lt) = box(
  height: .8 * lt.size,
  (lt.format)(text(lt.size, if lt.mode == "icon" and lt.icon != none {
    lt.icon
  } else if lt.mode == "icon" or lt.mode == "name" {
    if lt.name != none { lt.name } else { lang }
  } else {
    (
      if lt.icon != none { box(lt.icon) + h(.2em) }
        + {
          let name = if lt.name != none { lt.name } else { lang }
          if (
            (type(name) == str and not name.contains(regex("[A-Z0-9]")))
              or (
                type(name) == content
                  and "text" in name.fields()
                  and not name.text.contains(regex("[A-Z0-9]"))
              )
          ) { box(move(dy: -0.1 * lt.size, name)) } else { name }
        }
    )
  })),
)

/// Create the lang tag.
///
/// - lang (str): The language of the raw code.
/// - lt (dictionary): The lang tag parameters.
/// - frame (dictionary): The frame parameters.
/// -> block
#let lang-tag-block(lang, lt, frame) = {
  let ltc = lang-tag-content(lang, lt)

  /// The stroke of the tag: `auto` for the stroke of the frame (on the given side), `none` for no stroke, a color for a thin stroke of this color.
  let tag-stroke(frame-stroke) = if lt.stroke == auto {
    frame-stroke
  } else if type(lt.stroke) in (color, gradient, tiling) {
    lt.at("stroke-thickness", default: .05em) + lt.stroke
  } else {
    lt.stroke
  }

  if lt.visible and lt.placement not in ("code", "inline", "header") {
    let (is-top, is-left, is-right, is-bottom) = lang-tag-position(lt)

    let r = lt.radius
    let radius = (
      if is-top { df(r, "top-left") + df(r, "top-right") } else if is-left {
        df(r, "top-left") + df(r, "bottom-left")
      } else if is-right {
        df(r, "top-right") + df(r, "bottom-right")
      } else if is-bottom { df(r, "bottom-left") + df(r, "bottom-right") }
    )

    let frame-stroke = (
      if is-top { frame.stroke.top } else if is-left {
        frame.stroke.left
      } else if is-right { frame.stroke.right } else if is-bottom {
        frame.stroke.bottom
      }
    )

    let fill = if lt.fill == auto { frame.fill } else { lt.fill }

    block(
      stroke: tag-stroke(frame-stroke),
      fill: fill,
      radius: radius,
      inset: .25em,
      if is-left { rotate(-90deg, reflow: true, ltc) } else if is-right {
        rotate(90deg, reflow: true, ltc)
      } else { ltc },
    )
  } else if lt.visible {
    block(
      // The height of the tag for a text of size `.8em` is `1.1em`
      height: 1.2 * lt.size,
      // The first stroked side of the frame
      stroke: tag-stroke(
        ("top", "right", "bottom", "left")
          .map(side => frame.stroke.at(side))
          .find(s => s != none),
      ),
      // An automatic fill shows the fill of the code or of the header behind it
      fill: if lt.fill == auto { none } else { lt.fill },
      radius: lt.radius,
      inset: 0.2 * lt.size,
      ltc,
    )
  }
}

/// Return the vertical alignment of the lang tag.
///
/// - lt (dictionary):
/// -> alignment
#let lang-tag-alignment(lt) = {
  if lt.placement == "top-left" or lt.placement == "bottom-left" {
    left
  } else if lt.placement == "top" or lt.placement == "bottom" {
    center
  } else if lt.placement == "top-right" or lt.placement == "bottom-right" {
    right
  }
}

/// Return a placed object containing the lang tag.
///
/// - lt (dictionary):
/// - lt-block (block):
/// -> place
#let place-frame-lang-tag(lt, lt-block) = {
  place(
    if lt.placement == "left-top" { left + top } else if lt.placement
      == "left" { left + horizon } else if lt.placement == "left-bottom" {
      left + bottom
    } else if lt.placement == "right-top" { right + top } else if lt.placement
      == "right" { right + horizon } else if lt.placement == "right-bottom" {
      right + bottom
    },

    dx: if (
      lt.placement == "left-top"
        or lt.placement == "left"
        or lt.placement == "left-bottom"
    ) { -1.1em } else { 1.1em },

    lt-block,
  )
}
