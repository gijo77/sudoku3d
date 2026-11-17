extends Node
## Colour palettes and the shared UI Theme. Autoload "ThemeManager".
## Applies the palette named in Settings.theme_name to the whole UI.

signal theme_changed

## Each palette: UI colours (bg, panel, text, dim, accent) + 3D board colours
## (tile, peer, same, sel, plate, given, player, wrong, note).
const PALETTES := {
	"light": {"label": "Light", "bg": Color(0.94, 0.95, 0.98), "panel": Color(1, 1, 1), "text": Color(0.12, 0.14, 0.20), "dim": Color(0.40, 0.44, 0.52), "accent": Color(0.20, 0.45, 0.90),
		"tile": Color(0.93, 0.93, 0.96), "peer": Color(0.80, 0.87, 0.98), "same": Color(0.62, 0.78, 0.97), "sel": Color(0.45, 0.66, 0.95), "plate": Color(0.15, 0.17, 0.25),
		"given": Color(0.10, 0.12, 0.18), "player": Color(0.12, 0.38, 0.85), "wrong": Color(0.88, 0.15, 0.15), "note": Color(0.40, 0.44, 0.52)},
	"dark": {"label": "Dark", "bg": Color(0.09, 0.10, 0.14), "panel": Color(0.15, 0.17, 0.23), "text": Color(0.92, 0.94, 0.98), "dim": Color(0.62, 0.66, 0.74), "accent": Color(0.30, 0.52, 0.95),
		"tile": Color(0.24, 0.26, 0.34), "peer": Color(0.28, 0.34, 0.50), "same": Color(0.32, 0.44, 0.70), "sel": Color(0.35, 0.55, 0.95), "plate": Color(0.04, 0.05, 0.08),
		"given": Color(0.92, 0.94, 0.98), "player": Color(0.45, 0.70, 1.0), "wrong": Color(1.0, 0.40, 0.40), "note": Color(0.65, 0.69, 0.78)},
	"ocean": {"label": "Ocean", "bg": Color(0.88, 0.95, 0.97), "panel": Color(1, 1, 1), "text": Color(0.06, 0.20, 0.26), "dim": Color(0.30, 0.45, 0.50), "accent": Color(0.0, 0.52, 0.62),
		"tile": Color(0.92, 0.97, 0.97), "peer": Color(0.76, 0.91, 0.93), "same": Color(0.55, 0.82, 0.87), "sel": Color(0.20, 0.68, 0.78), "plate": Color(0.05, 0.25, 0.30),
		"given": Color(0.05, 0.18, 0.22), "player": Color(0.0, 0.40, 0.75), "wrong": Color(0.88, 0.15, 0.15), "note": Color(0.30, 0.45, 0.50)},
	"forest": {"label": "Forest", "bg": Color(0.92, 0.96, 0.91), "panel": Color(1, 1, 1), "text": Color(0.10, 0.22, 0.12), "dim": Color(0.35, 0.48, 0.36), "accent": Color(0.20, 0.52, 0.28),
		"tile": Color(0.93, 0.97, 0.92), "peer": Color(0.80, 0.92, 0.78), "same": Color(0.62, 0.84, 0.62), "sel": Color(0.38, 0.70, 0.42), "plate": Color(0.10, 0.22, 0.12),
		"given": Color(0.08, 0.20, 0.10), "player": Color(0.05, 0.40, 0.65), "wrong": Color(0.88, 0.15, 0.15), "note": Color(0.35, 0.48, 0.36)},
	"sunset": {"label": "Sunset", "bg": Color(0.99, 0.94, 0.90), "panel": Color(1, 1, 1), "text": Color(0.28, 0.14, 0.10), "dim": Color(0.55, 0.40, 0.35), "accent": Color(0.88, 0.38, 0.22),
		"tile": Color(0.97, 0.94, 0.91), "peer": Color(0.98, 0.85, 0.76), "same": Color(0.96, 0.72, 0.58), "sel": Color(0.93, 0.55, 0.38), "plate": Color(0.30, 0.14, 0.12),
		"given": Color(0.25, 0.12, 0.08), "player": Color(0.15, 0.30, 0.75), "wrong": Color(0.85, 0.10, 0.10), "note": Color(0.55, 0.40, 0.35)},
}

var palette: Dictionary = PALETTES["light"]
var theme := Theme.new()

func _ready() -> void:
	Settings.changed.connect(apply)
	apply()

func apply() -> void:
	palette = PALETTES.get(Settings.theme_name, PALETTES["light"])
	_build_theme()
	get_tree().root.theme = theme
	RenderingServer.set_default_clear_color(palette["bg"])
	theme_changed.emit()

func make_box(color: Color, radius: int = 28, margin: int = 16) -> StyleBoxFlat:
	var b := StyleBoxFlat.new()
	b.bg_color = color
	b.set_corner_radius_all(radius)
	b.set_content_margin_all(margin)
	return b

func _build_theme() -> void:
	var t := Theme.new()
	var accent: Color = palette["accent"]
	var text: Color = palette["text"]
	t.set_color("font_color", "Label", text)
	for type in ["Button", "OptionButton"]:
		t.set_stylebox("normal", type, make_box(accent))
		t.set_stylebox("hover", type, make_box(accent.lightened(0.12)))
		t.set_stylebox("pressed", type, make_box(accent.darkened(0.25)))
		t.set_stylebox("hover_pressed", type, make_box(accent.darkened(0.25)))
		t.set_stylebox("disabled", type, make_box(accent.lerp(palette["bg"], 0.7)))
		t.set_stylebox("focus", type, StyleBoxEmpty.new())
		for c in ["font_color", "font_hover_color", "font_pressed_color", "font_hover_pressed_color", "font_focus_color"]:
			t.set_color(c, type, Color.WHITE)
		t.set_color("font_disabled_color", type, Color(1, 1, 1, 0.7))
	t.set_font_size("font_size", "Button", 44)
	t.set_font_size("font_size", "OptionButton", 44)
	t.set_font_size("font_size", "Label", 40)
	t.set_font_size("font_size", "CheckButton", 44)
	for c in ["font_color", "font_hover_color", "font_pressed_color", "font_hover_pressed_color", "font_focus_color"]:
		t.set_color(c, "CheckButton", text)
	t.set_stylebox("panel", "PanelContainer", make_box(palette["panel"], 36, 36))
	theme = t
