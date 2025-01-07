include reactors

fun deg-to-rad(d):
  num-exact((d / 180) * PI)
end

fun rad-to-deg(r):
  num-exact((r / PI) * 180)
end

# following vars are user-changeable (in interaction pane)

var radius = 150
deg-incr = 5
var angle-incr = deg-to-rad(deg-incr)
var max-num-revolutions = 3
var cos-fn = lam(ang): radius * num-cos(ang) end
var sin-fn = lam(ang): radius * num-sin(ang) end
var x-scaler = rad-to-deg
var notch-radius = 2

# following should not be changed

one-deg-in-rad = deg-to-rad(1)
thirty-deg-in-rad = deg-to-rad(30)

notch = circle(notch-radius, 'solid', 'black')

fun clock-hop(n):
  # for every reactor tick, clock hops 30°
  n + thirty-deg-in-rad
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
end

fun make-notched-x-axis-line() block:
  x-axis-len = 9 * radius
  var x-axis-line = place-pinhole(0,0, line(x-axis-len, 0, 'orange'))
  notch-range = range-by(0, x-axis-len, 30)
  # for each angle (represented as length on the x-axis), place the notch's pinhole
  # relative to the axis-pinhole by subtracting the "angle length" relative
  # to the center of the circle and add it to x-axis-line
  for map(notch-angle from notch-range):
    x-axis-line := overlay-align('pinhole', 'pinhole',
    place-pinhole((-1 * notch-angle) + notch-radius, notch-radius, notch), x-axis-line)
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
  u-circle = circle(radius, 'outline', 'red')
  final-graph := overlay-align('pinhole', 'pinhole', u-circle, containing-rect)

  # create the "clock hand"
  r-line = place-pinhole(
    # ensure pinhole at 0,0 end of line
    if x-coord > 0: 0 else: 0 - x-coord end,
    if y-coord > 0: 0 else: 0 - y-coord end,
    line(x-coord, y-coord, 'darkgreen'))

  # create the x- and y-axis, then add them together
  y-axis-line = place-pinhole(0, radius, line(0, 2 * radius, 'orange'))
  x-axis-line = make-notched-x-axis-line()
  axes-lines = overlay-align('pinhole', 'pinhole', x-axis-line, y-axis-line)

  # add the axes to the graph
  final-graph := overlay-align('pinhole', 'pinhole', axes-lines, final-graph)
  theta-range = range-by(0, n + one-deg-in-rad, angle-incr)

  # add the clock hand to the graph
  final-graph := overlay-align('pinhole', 'pinhole', r-line, final-graph)

  # spy: theta-range end
  draw-coord-curve(theta-range, cos-fn, 'purple')
  draw-coord-curve(theta-range, sin-fn, 'blue')
  final-graph
end

fun stop-clock(n):
  n >= (max-num-revolutions * 2 * PI)
  # false # forever
end

r = reactor:
  init: 0,
  seconds-per-tick: 1/2,
  on-tick: clock-hop,
  to-draw: draw-clock,
  stop-when: stop-clock
end

fun t():
  interact(r)
end

# vi:ft=pyret
