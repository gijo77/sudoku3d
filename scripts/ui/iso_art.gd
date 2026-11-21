extends Control
## Isometric art drawn in code.
## kind "logo": a 3 x 3 patch of raised tiles with a glowing centre tile (main menu).
## kind "cube": a wireframe cube with 3 x 3 faces (splash screen).

var kind := "logo"
var digits := ["5", "3", "", "", "7", "8", "", "1", "9"]

static func make(art: String, w: float, h: float) -> Control:
	var a = load("res://scripts/ui/iso_art.gd").new()
	a.kind = art
	a.custom_minimum_size = Vector2(w, h)
	a.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return a

func _draw() -> void:
	if kind == "cube":
		_draw_cube()
	else:
		_draw_logo()

# --- Logo --------------------------------------------------------------------

func _iso(x: float, y: float, o: Vector2, a: float, b: float) -> Vector2:
	return o + Vector2((x - y) * a, (x + y) * b)

func _draw_logo() -> void:
	var p: Dictionary = ThemeManager.palette
	var a := minf(size.x / 6.4, size.y / 3.9)
	var b := a * 0.58
	var o := Vector2(size.x / 2.0, size.y / 2.0 - 3.0 * b - a * 0.12)
	var h := a * 0.2
	var g := 0.07
	var accent: Color = p["accent"]
	# glow under the centre tile
	var cc := _iso(1.5, 1.5, o, a, b)
	for k in 6:
		draw_circle(cc, a * (1.5 - k * 0.18), Color(accent, 0.035 + k * 0.012))
	var order := []
	for j in 3:
		for i in 3:
			order.append([i + j, i, j])
	order.sort_custom(func(l, r): return l[0] < r[0])
	var f: Font = ThemeManager.font_head
	for e in order:
		var i: int = e[1]
		var j: int = e[2]
		var idx := j * 3 + i
		var hot := idx == 4
		var face: Color = accent if hot else p["tile"]
		var side: Color = accent.darkened(0.45) if hot else p["tile"].darkened(0.45)
		var x0 := i + g
		var x1 := i + 1 - g
		var y0 := j + g
		var y1 := j + 1 - g
		var lift := Vector2(0, -h * 0.6) if hot else Vector2.ZERO
		var t00 := _iso(x0, y0, o, a, b) + lift
		var t10 := _iso(x1, y0, o, a, b) + lift
		var t11 := _iso(x1, y1, o, a, b) + lift
		var t01 := _iso(x0, y1, o, a, b) + lift
		var dh := Vector2(0, h)
		draw_colored_polygon(PackedVector2Array([t10, t11, t11 + dh, t10 + dh]), side)
		draw_colored_polygon(PackedVector2Array([t11, t01, t01 + dh, t11 + dh]), side.darkened(0.15))
		draw_colored_polygon(PackedVector2Array([t00, t10, t11, t01]), face)
		var edge := Color(Color.WHITE, 0.55) if hot else Color(p["line"], 0.35)
		draw_polyline(PackedVector2Array([t00, t10, t11, t01, t00]), edge, 2.0, true)
		var dg: String = digits[idx]
		if dg != "":
			var fs := int(a * 0.62)
			var c := (t00 + t11) / 2.0
			var w := f.get_string_size(dg, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x
			var col: Color = p["ink"] if hot else (p["accent2"] if idx in [5, 7] else p["given"])
			draw_string(f, c + Vector2(-w / 2.0, fs * 0.34), dg, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, col)

# --- Wire cube ---------------------------------------------------------------

func _draw_cube() -> void:
	var p: Dictionary = ThemeManager.palette
	var s := minf(size.x, size.y) * 0.3
	var c := size / 2.0
	var ax := Vector2(cos(PI / 6.0), sin(PI / 6.0)) * s * 1.15   # x axis (right, down)
	var ay := Vector2(-cos(PI / 6.0), sin(PI / 6.0)) * s * 1.15  # y axis (left, down)
	var az := Vector2(0, -s * 1.15)                              # up
	var o := c - (ax + ay + az) / 2.0 + Vector2(0, s * 0.1)
	var accent: Color = p["accent"]
	var a2: Color = p["accent2"]
	for k in 5:
		draw_circle(c, s * (2.0 - k * 0.3), Color(accent, 0.03 + k * 0.01))
	# top face (z = 1), left face (y = 1), right face (x = 1)
	var top := func(u, v): return o + az + ax * u + ay * v
	var left := func(u, v): return o + ay + ax * u + az * v
	var right := func(u, v): return o + ax + ay * u + az * v
	_face(top, accent, 4)
	_face(left, accent, -1)
	_face(right, a2, -1)

func _face(fn: Callable, col: Color, hot: int) -> void:
	var quad := PackedVector2Array([fn.call(0.0, 0.0), fn.call(1.0, 0.0), fn.call(1.0, 1.0), fn.call(0.0, 1.0)])
	draw_colored_polygon(quad, Color(col, 0.07))
	if hot >= 0:
		var u := float(hot % 3) / 3.0
		var v := float(hot / 3) / 3.0
		var t := 1.0 / 3.0
		draw_colored_polygon(PackedVector2Array([fn.call(u, v), fn.call(u + t, v), fn.call(u + t, v + t), fn.call(u, v + t)]), Color(col, 0.6))
	for k in range(1, 3):
		var f := float(k) / 3.0
		draw_line(fn.call(f, 0.0), fn.call(f, 1.0), Color(col, 0.3), 2.0, true)
		draw_line(fn.call(0.0, f), fn.call(1.0, f), Color(col, 0.3), 2.0, true)
	quad.append(quad[0])
	draw_polyline(quad, Color(col, 0.9), 4.0, true)
