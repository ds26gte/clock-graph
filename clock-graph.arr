include reactors

fun deg-to-rad(d):
  num-exact((d / 180) * PI)
end

fun rad-to-deg(r):
  num-exact((r / PI) * 180)
end

# following vars are user-changeable (in interaction pane)

var radius = 150
deg-incr = 1
var angle-incr = deg-to-rad(deg-incr)
var max-num-revolutions = 3
var cos-fn = lam(ang): radius * num-cos(ang) end
var sin-fn = lam(ang): radius * num-sin(ang) end
var x-scaler = rad-to-deg
var notch-radius = 2
var sin-color   = 'red'
var cos-color   = 'blue'
var axis-color  = 'grey'
var clock-color = 'darkgreen'

# following should not be changed

# one-deg-in-rad = deg-to-rad(1)
# five-deg-in-rad = deg-to-rad(5)

# this is 30, but only because x-scaler is rad-to-deg.
# can't hardwire, because for a different x-scaler, it can be something else
thirty-deg = x-scaler(PI / 6)
# similarly: 90
ninety-deg = x-scaler(PI / 2)

# notch = place-pinhole(notch-radius, notch-radius, circle(notch-radius, 'solid', 'black'))
notch = circle(notch-radius, 'solid', 'black')

fun make-number-sign(num):
  text(num-to-string(num), 12, 'black')
end

fun make-clock-number-sign(num):
  text(num-to-string(num), 20, clock-color)
end

twelve-o-clock = make-clock-number-sign(12)
three-o-clock = make-clock-number-sign(3)
six-o-clock = make-clock-number-sign(6)
nine-o-clock = make-clock-number-sign(9)

x-twelve-o-clock = make-number-sign(12)
x-three-o-clock = make-number-sign(3)
x-six-o-clock = make-number-sign(6)
x-nine-o-clock = make-number-sign(9)

fun clock-hop(n):
  n + angle-incr
end

var final-graph = 0

fun draw-coord-curve(theta-range, coord-gen-fn, curve-color) block:
  # compute the (x,y) coords, flipping the y-value to account for Pyret's y-axis
  proj-range = for map(theta from theta-range):
    [list: x-scaler(theta), -1 * coord-gen-fn(theta)]
  end
  first-coord = proj-range.first
  rest-coords = proj-range.rest
  # spy: proj-range end
  var prev-x = first-coord.get(0)
  var prev-y = first-coord.get(1)
  var first = true

  # starting with the first-coord, draw a segment to the next
  for each(poynt from rest-coords) block:
    poynt-x = poynt.get(0)
    poynt-y = poynt.get(1)

    # Compute the change from the previously-computed point
    rel-poynt-x = -1 * (poynt-x - prev-x)
    rel-poynt-y = -1 * (poynt-y - prev-y)

    # Create the line that represents that change,
    # then set the pinhole of that line
    graph-seg = line(rel-poynt-x, rel-poynt-y, curve-color)
    this-ph-x = 0 - prev-x
    this-ph-y = if rel-poynt-y < 0: 0 - prev-y else: (0 - prev-y) + rel-poynt-y end
    prev-x := poynt-x
    prev-y := poynt-y
    graph-seg-ph = place-pinhole(this-ph-x, this-ph-y, graph-seg)

    # add the segment to the graph
    final-graph := overlay-align('pinhole', 'pinhole', graph-seg-ph, final-graph)
  end
  final-graph := overlay-align('pinhole', 'pinhole',
  # place-pinhole(if prev-x > 0: 0 else: 0 - prev-x end,
  # if prev-y > 0: 0 else: 0 - prev-y end,
  #   line(prev-x, prev-y, curve-color)),
  #   final-graph)
  place-pinhole(0 - prev-x,
  if prev-y > 0: 0 else: 0 - prev-y end,
    line(0, prev-y, curve-color)),
    final-graph)
end

fun make-notched-x-axis-line() block:
  x-axis-len = 10 * radius
  var x-axis-line = place-pinhole(radius,0, line(x-axis-len, 0, axis-color))
  num-notches = num-floor(x-axis-len / thirty-deg)
  notch-range = range-by(0, num-notches, 1)
  # for each angle (represented as length on the x-axis), place the notch's pinhole
  # relative to the axis-pinhole by subtracting the "angle length" relative
  # to the center of the circle and add it to x-axis-line
  for map(notch-num from notch-range) block:
    notch-num-within-12 = num-modulo(notch-num, 12)
    notch-angle = notch-num * thirty-deg
    x-axis-line := overlay-align('pinhole', 'pinhole',
    place-pinhole((-1 * notch-angle) + notch-radius, notch-radius, notch), x-axis-line)
    # if at an angle corresponding to 3,6,9,12 o'clock, add label
    var marker = 'ignore'
    if notch-num-within-12 == 3:
      marker := x-three-o-clock
    else if notch-num-within-12 == 6:
      marker := x-six-o-clock
    else if notch-num-within-12 == 9:
      marker := x-nine-o-clock
    else if notch-num-within-12 == 0:
      marker := x-twelve-o-clock
    else:
      marker := 'ignore'
    end
    if (notch-num-within-12 == 3) or (notch-num-within-12 == 6) or (notch-num-within-12 == 9) or (notch-num-within-12 == 0):
      x-axis-line := overlay-align('pinhole', 'pinhole',
      place-pinhole((-1 * notch-angle) + notch-radius, notch-radius - 10, marker),
      x-axis-line)
    else:
      marker := 'ignore'
    end
  end
  x-axis-line
end

# consumes n (radians) and draws an image
fun draw-clock(n) block:
  # spy: n end
  # compute (x,y) coords of point around the circle
  # since it's a clock, "0" is technically 12 o'clock
  # instead of 3. Adjust by subtracting PI/2.
  nn = n - (PI / 2)
  x-coord = cos-fn(nn)
  y-coord = sin-fn(nn)
  containing-rect = place-pinhole(radius, radius, rectangle(9 * radius, 2 * radius, 'outline', 'pink'))
  var u-circle = circle(radius, 'outline', clock-color)

  # mark clock face with 3,6,9,12
  u-circle := overlay-align('pinhole', 'pinhole', u-circle,
    place-pinhole(0, radius - 5, twelve-o-clock))
  u-circle := overlay-align('pinhole', 'pinhole', u-circle,
    place-pinhole((-1 * radius) + 15, -5, three-o-clock))
  u-circle := overlay-align('pinhole', 'pinhole', u-circle,
    place-pinhole(-5, (-1 * radius) + 20, six-o-clock))
  u-circle := overlay-align('pinhole', 'pinhole', u-circle,
    place-pinhole(radius - 5, 0, nine-o-clock))

  final-graph := overlay-align('pinhole', 'pinhole', u-circle, containing-rect)

  # create the "clock hand"
  r-line = place-pinhole(
    # ensure pinhole at 0,0 end of line
    if x-coord > 0: 0 else: 0 - x-coord end,
    if y-coord > 0: 0 else: 0 - y-coord end,
    line(x-coord, y-coord, 'darkgreen'))

  # create the x- and y-axis, then add them together
  y-axis-line = place-pinhole(0, radius, line(0, 2 * radius, axis-color))
  x-axis-line = make-notched-x-axis-line()
  axes-lines = overlay-align('pinhole', 'pinhole', x-axis-line, y-axis-line)

  # add the axes to the graph
  final-graph := overlay-align('pinhole', 'pinhole', axes-lines, final-graph)
  theta-range = range-by(0, n + angle-incr, angle-incr)

  # add the clock hand to the graph
  final-graph := overlay-align('pinhole', 'pinhole', r-line, final-graph)

  # add clock hand projection lines to graph


  along-x-drop = place-pinhole(if x-coord > 0: 0 else: 0 - x-coord end, 0 - y-coord, line(x-coord,0, sin-color))
  along-y-drop = place-pinhole(0 - x-coord, if y-coord > 0: 0 else: 0 - y-coord end, line(0,y-coord, cos-color))

  final-graph := overlay-align('pinhole', 'pinhole', along-x-drop, final-graph)
  final-graph := overlay-align('pinhole', 'pinhole', along-y-drop, final-graph)

  # spy: theta-range end
  draw-coord-curve(theta-range, cos-fn, cos-color)
  draw-coord-curve(theta-range, sin-fn, sin-color)
  final-graph
end

fun stop-clock(n):
  n >= (max-num-revolutions * 2 * PI)
  # false # forever
end

r = reactor:
  init: 0,
  seconds-per-tick: 1/10,
  on-tick: clock-hop,
  to-draw: draw-clock,
  stop-when: stop-clock
end

fun t():
  interact(r)
end

# vi:ft=pyret
