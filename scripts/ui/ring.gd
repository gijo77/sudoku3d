extends Control
## Progress ring with a big centre value and a small caption (rank, resume %).

var frac := 0.0
var value := ""
var caption := ""
var color := Color.WHITE
var thickness := 0.12          # of the ring diameter
var value_size := 0.34         # font size as a fraction of the diameter
var glow := true

static func make(diameter: float, f: float, val: String, cap: String = "", col: Color = Color(0, 0, 0, 0)) -> Control:
	var r = load("res://scripts/ui/ring.gd").new()
	r.custom_minimum_size = Vector2(diameter, diameter)
	r.frac = clampf(f, 0.0, 1.0)
	r.value = val
	r.caption = cap
	r.color = col if col.a > 0.0 else ThemeManager.palette["accent"]
	r.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return r

func _draw() -> void:
	var d := minf(size.x, size.y)
	var c := size / 2.0
	var w := d * thickness
	var rad := d / 2.0 - w / 2.0 - (d * 0.04 if glow else 0.0)
	var p: Dictionary = ThemeManager.palette
	draw_circle(c, rad - w / 2.0, Color(p["bg"], 0.85))
	draw_arc(c, rad, 0.0, TAU, 72, Color(p["line"], 0.18), w, true)
	if frac > 0.0:
		var a0 := -PI / 2.0
		var a1 := a0 + TAU * frac
		if glow:
			draw_arc(c, rad, a0, a1, 72, Color(color, 0.22), w * 1.9, true)
		draw_arc(c, rad, a0, a1, 72, color, w, true)
	var f: Font = ThemeManager.font_head
	var vs := int(d * value_size)
	var vw := f.get_string_size(value, HORIZONTAL_ALIGNMENT_LEFT, -1, vs).x
	var vy := c.y + vs * 0.36 - (d * 0.06 if caption != "" else 0.0)
	draw_string(f, Vector2(c.x - vw / 2.0, vy), value, HORIZONTAL_ALIGNMENT_LEFT, -1, vs, p["text"])
	if caption != "":
		var m: Font = ThemeManager.font_mono
		var cs := int(d * 0.1)
		var cw := m.get_string_size(caption, HORIZONTAL_ALIGNMENT_LEFT, -1, cs).x
		draw_string(m, Vector2(c.x - cw / 2.0, vy + cs * 1.5), caption, HORIZONTAL_ALIGNMENT_LEFT, -1, cs, p["dim"])
