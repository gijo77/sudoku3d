extends Control
## Thin glowing progress bar. `back_frac` >= 0 draws a second fill on top
## (e.g. XP before a win, under the amber XP after it).

var frac := 0.0:
	set(v):
		frac = v
		queue_redraw()
var color := Color.WHITE
var back_frac := -1.0
var back_color := Color.WHITE

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	size_flags_horizontal = Control.SIZE_EXPAND_FILL

func _pill(rect: Rect2, col: Color, r: float) -> void:
	var sb := StyleBoxFlat.new()
	sb.bg_color = col
	sb.set_corner_radius_all(int(r))
	sb.anti_aliasing = true
	draw_style_box(sb, rect)

func _draw() -> void:
	var h := size.y
	var r := h / 2.0
	_pill(Rect2(Vector2.ZERO, size), Color(ThemeManager.palette["line"], 0.16), r)
	var f := clampf(frac, 0.0, 1.0)
	if f > 0.0:
		_pill(Rect2(-3, -5, size.x * f + 6, h + 10), Color(color, 0.22), r + 5)
		_pill(Rect2(0, 0, maxf(size.x * f, h), h), color, r)
	if back_frac > 0.0:
		_pill(Rect2(0, 0, maxf(size.x * clampf(back_frac, 0.0, 1.0), h), h), back_color, r)
