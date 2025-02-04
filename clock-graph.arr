include reactors
import constants as Consts
provide from Consts: PI, E end
provide * 
fun deg-to-rad(d):
  num-exact((d / 180) * PI)
end
fun rad-to-deg(r):
  num-exact((r / PI) * 180)
end
# following vars are user-changeable (in interaction pane)
var radius = 100
deg-incr = 5
var angle-incr = deg-to-rad(deg-incr)
var max-num-revolutions = 2
var cos-fn = lam(ang): num-cos(ang) end
var sin-fn = lam(ang): num-sin(ang) end
var user-fn= lam(ang): 0 end
var x-scaler = rad-to-deg
var notch-radius = 2
var sin-color   = 'red'
var cos-color   = 'blue'
var user-fn-color  = 'transparent'
var axis-color  = 'grey'
var clock-color = 'darkgreen'
var draw-moving-line-p = true
var labels      = [list:]
var _num-labels = 4
var angle-adj   = PI / 2
fun make-number-sign(label):
  text(label, 12, 'black')
end
fun make-clock-number-sign(label):
  text(label, 20, clock-color)
end
fun clock-hop(n):
  n + angle-incr
end

fun draw-coord-curve-onto(theta-range, coord-gen-fn, curve-color, img):
  doc: ```
       Draws the curve onto the given image, assuming the pinhole of the image is at (0, h/2)
       where h is the height of the image.
       ```
  # compute the (x,y) coords, flipping the y-value to account for Pyret's y-axis
  proj-range = for map(theta from theta-range):
    {x-scaler(theta); -1 * coord-gen-fn(theta) * radius}
  end
  cases(List) proj-range:
    | empty => raise("No points given!")
    | link(first, rest) =>
      {shadow img; _} = for fold({shadow img; {prev-x; prev-y}} from {img; first}, cur from rest):
        {poynt-x; poynt-y} = cur
        new-img = scene-line(img, prev-x, prev-y + radius, poynt-x, poynt-y + radius, curve-color)
        {new-img; cur}
      end
      if draw-moving-line-p:
        {prev-x; prev-y} = first
        scene-line(img, prev-x, radius, prev-x, prev-y + radius, curve-color)
      else: img
      end
  end
end
fun make-notched-x-axis-line() block:
  n = labels.length()
  x-axis-len = 7.5 * radius
  n-degrees-scaled = x-scaler((2 * PI) / n)
  var x-axis-line = place-pinhole(0,0, line(x-axis-len, 0, axis-color))
  num-notches = num-floor(x-axis-len / n-degrees-scaled)
  notch-range = range-by(0, num-notches, 1)
  notch = circle(notch-radius, 'solid', 'black')
  # for each angle (represented as length on the x-axis), place the notch's pinhole
  # relative to the axis-pinhole by subtracting the "angle length" relative
  # to the center of the circle and add it to x-axis-line
  
  label-indices = range-by(0, labels.length(), 1)
  label-incr    = -1 * deg-to-rad(360 / labels.length())
  label-skips   = labels.length() / _num-labels
  
  for map(notch-num from notch-range) block:
    notch-num-mod-len = num-modulo(notch-num, n)
    label-num = labels.get(notch-num-mod-len)
    notch-angle = notch-num * n-degrees-scaled
    x-axis-line := overlay-align(
      'pinhole', 'pinhole',
      place-pinhole((-1 * notch-angle) + notch-radius, notch-radius, notch), 
      x-axis-line)
    var label = false
    # if the notch-num-mod-len falls on one of the label nums, draw the label
    when num-modulo(notch-num-mod-len, n / _num-labels) == 0 block:
      label := make-number-sign(label-num)
      label := place-pinhole((-1 * notch-angle) + notch-radius, notch-radius - 10, label)
      x-axis-line := overlay-align('pinhole', 'pinhole', label, x-axis-line)
    end
  end
  
  x-axis-line
end

# consumes n (radians) and draws an image
fun draw-clock-and-contents(n):
  beside-list([list:
      draw-clock(n), 
      rectangle(radius, 0, "outline", "white"),
      draw-graph(n)])
end
fun draw-clock(n):
  # spy: n end
  # compute (x,y) coords of point around the circle
  # since it's a clock, "0" is technically 12 o'clock
  # instead of 3. Adjust by subtracting PI/2.
  adj-n = n - angle-adj
  x-coord = cos-fn(adj-n) * radius
  y-coord = sin-fn(adj-n) * radius
  containing-rect = square(2 * radius, "solid", "white")
  u-circle = circle(radius, 'outline', clock-color)
  # iterate through the labels, drawing the label ever <label-skips>
  label-skips   = labels.length() / _num-labels
  label-indices = range-by(0, labels.length(), label-skips)
  label-incr    = -1 * deg-to-rad(360 / labels.length())
  placed-labels = for map(index from label-indices) block:
    clock-x = sin(index * label-incr) * (radius - 12)
    clock-y = cos(index * label-incr) * (radius - 12)
    label-img = make-clock-number-sign(labels.get(index))
    place-pinhole(
      clock-x + (image-width(label-img) / 2), 
      clock-y + ((image-height(label-img) / 2) - 2), 
      label-img)
  end
  vertical-axis = place-pinhole(0, radius, line(0, radius * 2, axis-color))
  horiz-axis = place-pinhole(radius, 0, line(radius * 2, 0, axis-color))
  r-line = place-pinhole(
    # ensure pinhole at 0,0 end of line
    if x-coord > 0: 0 else: 0 - x-coord end,
    if y-coord > 0: 0 else: 0 - y-coord end,
    line(x-coord, y-coord, 'darkgreen'))
  along-x-drop = place-pinhole(if x-coord > 0: 0 else: 0 - x-coord end, 0 - y-coord, line(x-coord,0, sin-color))
  along-y-drop = place-pinhole(0 - x-coord, if y-coord > 0: 0 else: 0 - y-coord end, line(0,y-coord, cos-color))
  overlay-list([list: u-circle, vertical-axis, horiz-axis, r-line, along-x-drop, along-y-drop] 
      + placed-labels + [list: containing-rect])
end
fun draw-graph(n):
  containing-rect = place-pinhole(0, radius, rectangle(7.5 * radius, 2 * radius, "outline", "white"))
  # create the x- and y-axis, then add them together
  y-axis-line = place-pinhole(0, radius, line(0, 2 * radius, axis-color))
  x-axis-numbers = [list: 12, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11]
  x-axis-line = make-notched-x-axis-line()
  axes-lines = overlay(x-axis-line, y-axis-line)
  theta-range = range-by(0, n + angle-incr, angle-incr)
  draw-coord-curve-onto(
    theta-range, cos-fn, cos-color,
    draw-coord-curve-onto(
      theta-range, sin-fn, sin-color,
      draw-coord-curve-onto(
        theta-range, user-fn, user-fn-color,
        overlay(axes-lines, containing-rect))))
end
# Stop after 2 revolutions (adjusting for the deg-incr offset
fun stop-clock(n):
  n >= ((max-num-revolutions * 2 * PI) - (deg-incr / 360))
  # false # forever
end
fun start-clock(spt, slices, label-count) block:  
  
  if is-link(slices) block: 
    labels     := slices
    _num-labels := slices.length()
  else:
    # check for proper numbers
    when (num-modulo(slices, label-count) <> 0):
      raise("Cannot draw unit clock: " +
        num-to-string(slices) + 
        " does not divide evenly by " + 
        num-to-string(label-count))
    end
    labels     := link(slices, range-by(1,slices,1)).map(num-to-string)
    _num-labels := label-count # how many evenly-spaced labels should we show?
  end
  r = reactor:
    init: 0,
    seconds-per-tick: spt,
    on-tick: clock-hop,
    to-draw: draw-clock-and-contents,
    stop-when: stop-clock
  end
  interact(r)
end
fun start-clock2(spt, slices, label-count, f) block:
  user-fn := f
  user-fn-color := 'orange'
  start-clock(spt, slices, label-count)
end
