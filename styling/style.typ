#let zebra(odd: none, even: none) = n => if calc.odd(n) { odd } else { even }

#let octique-marker(octique) = (name, color: black) => move(dy: -.07em, octique(
  name,
  color: color,
))
