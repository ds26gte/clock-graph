include reactors

fun deg-to-rad(d):
  (d / 180) * PI
end

var radius = 150
var angle-incr = 5
var max-num-revolutions = 3
var starting-angle = -90
var x-coord-fn = lam(ang): radius * num-cos(deg-to-rad(ang)) end
var y-coord-fn = lam(ang): radius * num-sin(deg-to-rad(ang)) end

# ↑ using var instead of const so user can set them in interaction pane

fun clock-hop(n):
  # for every reactor tick, clock hops 30°
  n + 30
end

var final-graph = 0

fun draw-coord-curve(theta-range, coord-gen-fn, curve-color, x-axis-p) block:
  proj-range = for map(theta from theta-range):
    [list: theta - starting-angle, coord-gen-fn(theta)]
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

fun draw-clock(n) block:
  # spy: n end
  x-coord = x-coord-fn(n)
  y-coord = y-coord-fn(n)
  u-circle = circle(radius, 'outline', 'red')
  r-line = place-pinhole(
    # ensure pinhole at 0,0 end of line
    if x-coord > 0: 0 else: 0 - x-coord end,
    if y-coord > 0: 0 else: 0 - y-coord end,
    line(x-coord, y-coord, 'darkgreen'))
  final-graph := overlay-align('pinhole', 'pinhole', r-line, u-circle)
  y-axis-line = place-pinhole(0, radius, line(0, 2 * radius, 'orange'))
  final-graph := overlay-align('pinhole', 'pinhole', y-axis-line, final-graph)
  theta-range = range-by(starting-angle, n + 1, angle-incr)
  # spy: theta-range end
  draw-coord-curve(theta-range, x-coord-fn, 'purple', true)
  draw-coord-curve(theta-range, y-coord-fn, 'blue', false)
  final-graph
end

fun stop-clock(n):
  n >= (max-num-revolutions * 360)
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
