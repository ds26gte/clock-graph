include reactors

fun clock-hop(n):
  # we could ensure that n is normalized to [0, 360] here itself, 
  # but it's easier to allow n to increase monotonically so a stop-when
  # can be set for a certain num of revolutions -- for debugging
  n + 30
end

radius = 50

fun deg-to-rad(d):
  (d / 180) * PI
end

fun rad-to-deg(r):
  (r / PI) * 180
end

var final-graph = 0
starting-angle = -90

fun draw-sin-curve(theta-range, sin-like-fn, curve-color) block:
  proj-range = for map(theta from theta-range):
    [list: theta, radius * sin-like-fn(deg-to-rad(theta + starting-angle))]
  end
  # spy: proj-range end
  var prev-x = 0
  var prev-y = 0
  var first = true
  for each(poynt from proj-range) block:
    poynt-x = poynt.get(0)
    poynt-y = poynt.get(1)
    rel-poynt-x = poynt-x - prev-x
    rel-poynt-y = poynt-y - prev-y
    graph-seg = line(rel-poynt-x, rel-poynt-y, curve-color)
    this-ph-x = 0 - prev-x
    this-ph-y = if rel-poynt-y > 0: 0 - prev-y else: (0 - prev-y) + rel-poynt-y end
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
  alpha = deg-to-rad(num-modulo(n, 360))
  n2 = rad-to-deg(alpha)
  x-coord = radius * num-cos(alpha)
  y-coord = radius * num-sin(alpha)
  u-circle = circle(radius, 'outline', 'red')
  r-line = place-pinhole(
    if x-coord > 0: 0 else: 0 - x-coord end,
    if y-coord > 0: 0 else: 0 - y-coord end,
    line(x-coord, y-coord, 'darkgreen'))
  final-graph := overlay-align('pinhole', 'pinhole', r-line, u-circle)
  y-axis-line = place-pinhole(0, radius, line(0, 2 * radius, 'orange'))
  final-graph := overlay-align('pinhole', 'pinhole', y-axis-line, final-graph)
  theta-range = range-by(0, (n2 - starting-angle) + 1, 5)
  draw-sin-curve(theta-range, num-sin, 'blue')
  draw-sin-curve(theta-range, num-cos, 'purple')
  final-graph
end

fun stop-clock(n): 
  max-num-revolutions = 100
  n >= (max-num-revolutions * 360)
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
