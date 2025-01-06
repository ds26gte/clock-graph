include reactors

fun deg-to-rad(d):
  num-exact((d / 180) * PI)
end

fun rad-to-deg(r):
  num-exact((r / PI) * 180)
end

# following vars are user-changeable (in interaction pane)

var radius = 150
var angle-incr = deg-to-rad(5)
var max-num-revolutions = 3
var starting-angle = deg-to-rad(-90)
var x-coord-fn = lam(ang): radius * num-cos(ang) end
var y-coord-fn = lam(ang): radius * num-sin(ang) end
var x-scaler = rad-to-deg
var notch-dia = 2

# following should not be changed

one-deg-in-rad = deg-to-rad(1)
thirty-deg-in-rad = deg-to-rad(30)

notch = circle(notch-dia, 'solid', 'black')

fun clock-hop(n):
  # for every reactor tick, clock hops 30°
  n + thirty-deg-in-rad
end

var final-graph = 0

fun draw-coord-curve(theta-range, coord-gen-fn, curve-color, x-axis-p) block:
  proj-range = for map(theta from theta-range):
    [list: x-scaler(theta - starting-angle), coord-gen-fn(theta)]
  end
  # spy: proj-range end
  var prev-x = 0
  var prev-y = 0
  var first = true
  for each(poynt from proj-range) block:
    poynt-x = poynt.get(0)
    poynt-y = if x-axis-p: 0 - poynt.get(1) else: poynt.get(1) end
    rel-poynt-x = poynt-x - prev-x
    rel-poynt-y = poynt-y - prev-y
    graph-seg = line(rel-poynt-x, rel-poynt-y, curve-color)
    this-ph-x = 0 - prev-x
    this-ph-y = if rel-poynt-y < 0: 0 - prev-y else: (0 - prev-y) + rel-poynt-y end
    prev-x := poynt-x
    prev-y := poynt-y
    graph-seg-ph = place-pinhole(this-ph-x, this-ph-y, graph-seg)
    if not(first):
      final-graph := overlay-align('pinhole', 'pinhole',
         graph-seg-ph, final-graph)
    else: first := false
    end
  end
end

fun make-notched-x-axis-line() block:
  x-axis-len = 9 * radius
  var x-axis-line = place-pinhole(0,0, line(x-axis-len, 0, 'orange'))
  notch-range = range-by(0, x-axis-len, 30)
  for map(notch-angle from notch-range):
    x-axis-line := overlay-align('pinhole', 'pinhole', place-pinhole(0 - notch-angle,0, notch), x-axis-line)
  end
  x-axis-line
end

fun draw-clock(n) block:
  # spy: n end
  x-coord = x-coord-fn(n)
  y-coord = y-coord-fn(n)
  containing-rect = place-pinhole(radius, radius, rectangle(9 * radius, 2 * radius, 'outline', 'pink'))
  u-circle = circle(radius, 'outline', 'red')
  circle-in-rect = overlay-align('pinhole', 'pinhole', u-circle, containing-rect)
  r-line = place-pinhole(
    # ensure pinhole at 0,0 end of line
    if x-coord > 0: 0 else: 0 - x-coord end,
    if y-coord > 0: 0 else: 0 - y-coord end,
    line(x-coord, y-coord, 'darkgreen'))
  final-graph := overlay-align('pinhole', 'pinhole', r-line, circle-in-rect)
  y-axis-line = place-pinhole(0, radius, line(0, 2 * radius, 'orange'))
  # x-axis-line = place-pinhole(0, 0, line(9 * radius, 0, 'orange'))
  x-axis-line = make-notched-x-axis-line()
  axes-lines = overlay-align('pinhole', 'pinhole', x-axis-line, y-axis-line)
  final-graph := overlay-align('pinhole', 'pinhole', axes-lines, final-graph)
  theta-range = range-by(starting-angle, n + one-deg-in-rad, angle-incr)
  # spy: theta-range end
  draw-coord-curve(theta-range, x-coord-fn, 'purple', true)
  draw-coord-curve(theta-range, y-coord-fn, 'blue', false)
  final-graph
end

fun stop-clock(n):
  n >= (max-num-revolutions * 2 * PI)
  # false # forever
end

r = reactor:
  init: starting-angle,  # we want initial position to be 12 o'clock
  seconds-per-tick: 1/2,
  on-tick: clock-hop,
  to-draw: draw-clock,
  stop-when: stop-clock
end

fun t():
  interact(r)
end

# vi:ft=pyret
