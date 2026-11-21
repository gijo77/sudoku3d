extends Control
## Screen background for the Neon Lattice look: a faint square grid plus an
## optional soft radial glow (e.g. behind the logo or the XP total).

const STEP := 72.0

var glows: Array = []   # [{"pos": Vector2 (0..1 of size), "radius": float, "color": Color}]
var _tex_cache := {}

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	resized.connect(queue_redraw)

## Adds a glow centred at `pos` (fractions of the screen size).
func add_glow(pos: Vector2, radius: float, color: Color) -> void:
	glows.append({"pos": pos, "radius": radius, "color": color})
	queue_redraw()

func _draw() -> void:
	var p: Dictionary = ThemeManager.palette
	draw_rect(Rect2(Vector2.ZERO, size), p["bg"])
	for g in glows:
		var r: float = g["radius"]
		var c: Vector2 = size * Vector2(g["pos"])
		draw_texture_rect(_glow_tex(g["color"]), Rect2(c - Vector2(r, r), Vector2(r, r) * 2.0), false)
	var line := Color(p["line"], 0.06 if ThemeManager.is_light() else 0.07)
	var x := 0.0
	while x < size.x:
		draw_line(Vector2(x, 0), Vector2(x, size.y), line, 2.0)
		x += STEP
	var y := 0.0
	while y < size.y:
		draw_line(Vector2(0, y), Vector2(size.x, y), line, 2.0)
		y += STEP

func _glow_tex(color: Color) -> Texture2D:
	var key := color.to_html()
	if _tex_cache.has(key):
		return _tex_cache[key]
	var grad := Gradient.new()
	grad.set_color(0, color)
	grad.set_color(1, Color(color, 0.0))
	grad.add_point(0.45, Color(color, color.a * 0.45))
	var t := GradientTexture2D.new()
	t.gradient = grad
	t.fill = GradientTexture2D.FILL_RADIAL
	t.fill_from = Vector2(0.5, 0.5)
	t.fill_to = Vector2(1.0, 0.5)
	t.width = 256
	t.height = 256
	_tex_cache[key] = t
	return t
