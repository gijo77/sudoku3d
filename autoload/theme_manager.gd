extends Node
## Colour palettes and the shared UI Theme. Autoload "ThemeManager".
## Applies the palette named in Settings.theme_name to the whole UI.

signal theme_changed

const PALETTES := {
	"light": {"label": "Light", "bg": Color(0.94, 0.95, 0.98), "panel": Color(1, 1, 1), "text": Color(0.12, 0.14, 0.20), "dim": Color(0.40, 0.44, 0.52), "accent": Color(0.20, 0.45, 0.90)},
	"dark": {"label": "Dark", "bg": Color(0.09, 0.10, 0.14), "panel": Color(0.15, 0.17, 0.23), "text": Color(0.92, 0.94, 0.98), "dim": Color(0.62, 0.66, 0.74), "accent": Color(0.30, 0.52, 0.95)},
	"ocean": {"label": "Ocean", "bg": Color(0.88, 0.95, 0.97), "panel": Color(1, 1, 1), "text": Color(0.06, 0.20, 0.26), "dim": Color(0.30, 0.45, 0.50), "accent": Color(0.0, 0.52, 0.62)},
	"forest": {"label": "Forest", "bg": Color(0.92, 0.96, 0.91), "panel": Color(1, 1, 1), "text": Color(0.10, 0.22, 0.12), "dim": Color(0.35, 0.48, 0.36), "accent": Color(0.20, 0.52, 0.28)},
	"sunset": {"label": "Sunset", "bg": Color(0.99, 0.94, 0.90), "panel": Color(1, 1, 1), "text": Color(0.28, 0.14, 0.10), "dim": Color(0.55, 0.40, 0.35), "accent": Color(0.88, 0.38, 0.22)},
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

func _box(color: Color, radius: int = 28, margin: int = 16) -> StyleBoxFlat:
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
		t.set_stylebox("normal", type, _box(accent))
		t.set_stylebox("hover", type, _box(accent.lightened(0.12)))
		t.set_stylebox("pressed", type, _box(accent.darkened(0.25)))
		t.set_stylebox("hover_pressed", type, _box(accent.darkened(0.25)))
		t.set_stylebox("disabled", type, _box(accent.lerp(palette["bg"], 0.7)))
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
	t.set_stylebox("panel", "PanelContainer", _box(palette["panel"], 36, 36))
	theme = t
