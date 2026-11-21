extends Control
## Vector icons and medals drawn in code (no image files). Coordinates are on a 24 x 24 grid.
## kind "glyph": a stroked icon in `color`. kind "medal": a metal disc with a glyph on it.

const GLYPHS := {
	"home": [[[3, 11], [12, 3], [21, 11]], [[5, 10], [5, 20], [19, 20], [19, 10]]],
	"play": [[[8, 5], [19, 12], [8, 19], [8, 5]]],
	"plus": [[[12, 5], [12, 19]], [[5, 12], [19, 12]]],
	"calendar": [[[4, 6], [20, 6], [20, 20], [4, 20], [4, 6]], [[4, 10], [20, 10]], [[8, 3], [8, 7]], [[16, 3], [16, 7]]],
	"cube": [[[12, 3], [20, 7], [20, 17], [12, 21], [4, 17], [4, 7], [12, 3]], [[4, 7], [12, 11], [20, 7]], [[12, 11], [12, 21]]],
	"stats": [[[5, 20], [5, 10]], [[12, 20], [12, 4]], [[19, 20], [19, 12]]],
	"settings": [[[4, 7], [14, 7]], [[18, 7], [20, 7]], [[4, 17], [6, 17]], [[10, 17], [20, 17]], [[14, 5], [14, 9]], [[6, 15], [6, 19]]],
	"hint": [[[9, 18], [15, 18]], [[10, 21], [14, 21]], [[12, 3], [8, 5], [7, 9], [8, 13], [9, 15], [9, 18]], [[12, 3], [16, 5], [17, 9], [16, 13], [15, 15], [15, 18]]],
	"undo": [[[9, 6], [4, 11], [9, 16]], [[4, 11], [13, 11], [19, 17], [19, 19]]],
	"redo": [[[15, 6], [20, 11], [15, 16]], [[20, 11], [11, 11], [5, 17], [5, 19]]],
	"notes": [[[4, 20], [8, 19], [19, 8], [16, 5], [5, 16], [4, 20]], [[14, 7], [17, 10]]],
	"erase": [[[4, 16], [13, 7], [19, 13], [13, 19], [8, 19], [4, 16]], [[13, 19], [20, 19]]],
	"pause": [[[8, 5], [8, 19]], [[16, 5], [16, 19]]],
	"back": [[[15, 5], [8, 12], [15, 19]]],
	"trophy": [[[8, 4], [16, 4], [16, 9], [12, 13], [8, 9], [8, 4]], [[8, 6], [5, 6], [5, 8], [8, 10]], [[16, 6], [19, 6], [19, 8], [16, 10]], [[12, 13], [12, 17]], [[9, 20], [15, 20]]],
	"shield": [[[12, 3], [19, 6], [19, 11], [16, 18], [12, 21], [8, 18], [5, 11], [5, 6], [12, 3]], [[9, 12], [11, 14], [15, 10]]],
	"flame": [[[12, 3], [15, 7], [17, 12], [16, 17], [12, 19], [8, 17], [7, 12], [9, 9], [10, 12], [12, 3]]],
	"bolt": [[[13, 3], [5, 13], [11, 13], [10, 21], [18, 11], [12, 11], [13, 3]]],
	"star": [[[12, 3], [14.7, 8.6], [20.8, 9.5], [16.4, 13.8], [17.4, 19.9], [12, 17], [6.6, 19.9], [7.6, 13.8], [3.2, 9.5], [9.3, 8.6], [12, 3]]],
	"lock": [[[6, 11], [18, 11], [18, 20], [6, 20], [6, 11]], [[8, 11], [8, 8], [10, 5], [14, 5], [16, 8], [16, 11]]],
	"sound": [[[4, 9], [8, 9], [13, 5], [13, 19], [8, 15], [4, 15], [4, 9]], [[16, 9], [18, 12], [16, 15]]],
	"music": [[[9, 18], [9, 5], [19, 3], [19, 16]], [[9, 18], [6, 18]], [[19, 16], [16, 16]]],
	"vibration": [[[8, 4], [16, 4], [16, 20], [8, 20], [8, 4]], [[4, 8], [4, 16]], [[20, 8], [20, 16]]],
	"peers": [[[4, 4], [20, 4], [20, 20], [4, 20], [4, 4]], [[4, 12], [20, 12]], [[12, 4], [12, 20]]],
	"same": [[[5, 5], [11, 5], [11, 11], [5, 11], [5, 5]], [[13, 13], [19, 13], [19, 19], [13, 19], [13, 13]]],
	"heart": [[[12, 20], [6, 14], [4, 10], [6, 6], [9, 5], [12, 8], [15, 5], [18, 6], [20, 10], [18, 14], [12, 20]]],
}

const METALS := {
	1: {"top": Color("F5BD91"), "bot": Color("8E4217"), "in_top": Color("E58E58"), "in_bot": Color("C4672F"), "ink": Color("40190A")},
	2: {"top": Color("F4F6FB"), "bot": Color("7C849B"), "in_top": Color("D9DEEB"), "in_bot": Color("A9B0C4"), "ink": Color("2B3047")},
	3: {"top": Color("FFE08A"), "bot": Color("B9791C"), "in_top": Color("FFD36B"), "in_bot": Color("E0A02F"), "ink": Color("4A2C05")},
}

var glyph := "home"
var kind := "glyph"          # "glyph" | "medal"
var tier := 3                # medals: 0 locked, 1 bronze, 2 silver, 3 gold
var color := Color.WHITE
var filled := false

static func make(glyph_name: String, size: float, col: Color = Color.WHITE) -> Control:
	var g = load("res://scripts/ui/glyph_icon.gd").new()
	g.glyph = glyph_name
	g.color = col
	g.custom_minimum_size = Vector2(size, size)
	g.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return g

static func make_medal(glyph_name: String, medal_tier: int, size: float) -> Control:
	var g = load("res://scripts/ui/glyph_icon.gd").new()
	g.glyph = glyph_name
	g.kind = "medal"
	g.tier = medal_tier
	g.custom_minimum_size = Vector2(size, size)
	g.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return g

func _draw() -> void:
	var s := minf(size.x, size.y)
	if s <= 0.0:
		return
	var off := Vector2((size.x - s) * 0.5, (size.y - s) * 0.5)
	if kind == "medal":
		_draw_medal(off, s)
	else:
		_draw_glyph(off, s, 1.0, color, maxf(2.0, s / 12.0))

func _pt(p: Array, off: Vector2, s: float, scale: float, pad: float) -> Vector2:
	var u := s / 24.0
	return off + Vector2(pad + float(p[0]) * u * scale, pad + float(p[1]) * u * scale)

func _draw_glyph(off: Vector2, s: float, scale: float, col: Color, width: float, pad: float = 0.0) -> void:
	for path in GLYPHS.get(glyph, []):
		var pts := PackedVector2Array()
		for p in path:
			pts.append(_pt(p, off, s, scale, pad))
		if filled and pts.size() > 2:
			draw_colored_polygon(pts, col)
		draw_polyline(pts, col, width, true)

func _disc(c: Vector2, r: float, top: Color, bot: Color) -> void:
	var pts := PackedVector2Array()
	var cols := PackedColorArray()
	for i in 48:
		var a := TAU * float(i) / 48.0
		var p := c + Vector2(cos(a), sin(a)) * r
		pts.append(p)
		cols.append(top.lerp(bot, clampf((p.y - (c.y - r)) / (2.0 * r), 0.0, 1.0)))
	draw_polygon(pts, cols)

func _draw_medal(off: Vector2, s: float) -> void:
	var c := off + Vector2(s, s) * 0.5
	var r := s * 0.48
	if tier <= 0:
		_disc(c, r, Color("3A3F63"), Color("262A47"))
		_disc(c, r * 0.76, Color("1B1F3B"), Color("1B1F3B"))
		var ink := Color("5E6491")
		_draw_glyph(off, s, 0.56, ink, maxf(2.0, s / 22.0), s * 0.22)
		return
	var m: Dictionary = METALS[clampi(tier, 1, 3)]
	r *= 0.88
	for k in 5:   # soft neon halo in the metal's colour
		draw_circle(c, r * (1.14 - k * 0.025), Color(m["in_top"], 0.05 + k * 0.02))
	_disc(c, r, m["top"], m["bot"])
	draw_arc(c, r - 1.0, 0.0, TAU, 48, Color(1, 1, 1, 0.4), maxf(1.5, s / 36.0), true)
	_disc(c, r * 0.76, m["in_top"].lerp(m["in_bot"], 0.0), m["in_bot"])
	_draw_glyph(off, s, 0.56, m["ink"], maxf(2.0, s / 22.0), s * 0.22)
	# soft gloss on the upper part
	draw_arc(c + Vector2(0, -r * 0.2), r * 0.6, deg_to_rad(215), deg_to_rad(325), 16, Color(1, 1, 1, 0.35), maxf(2.0, s / 18.0), true)
