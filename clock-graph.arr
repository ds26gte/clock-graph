include reactors

fun clock-hop(n):
  # we could ensure that n is normalized to [0, 360] here itself, 
  # but it's easier to allow n to increase monotonically so a stop-when
  # can be set for a certain num of revolutions -- for debugging
  n + 30
end

radius = 50

fun degrees-to-radians(d):
  # probably a primitive, but can't find it
  (d / 180) * PI
end

fun draw-clock(n):  # block?
  alpha = degrees-to-radians(num-modulo(n, 360))
  x-coord = radius * num-cos(alpha)
  y-coord = radius * num-sin(alpha)
  # unfortunately (top,left) of the entire bounding box is taken as the line's origin
  # so we have to do some arith to get the true overlay offset
  x-offset = if x-coord < 0: radius + x-coord else: radius end
  y-offset = if y-coord < 0: radius + y-coord else: radius end
  overlay-xy(circle(radius, "outline", "red"),
    x-offset, y-offset,
    line(x-coord, y-coord, 'blue'))
end

fun stop-clock(n): 
  max_num_revolutions = 10
  n >= (max_num_revolutions * 360)
end

r = reactor:
  init: -90,  # we want initial position to be 12 o'clock
  seconds-per-tick: 1/2,
  on-tick: clock-hop,
  to-draw: draw-clock,
  stop-when: stop-clock
end

fun t():
  interact(r)
end

