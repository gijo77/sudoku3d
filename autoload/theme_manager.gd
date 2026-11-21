extends Node
## Colour palettes, fonts and the shared UI Theme. Autoload "ThemeManager".
## Applies the palette named in Settings.theme_name to the whole UI.
##
## Look: "Neon Lattice" - a deep ground, glass panels with a thin hairline and
## glow that carries meaning: accent = focus / action, accent2 = related / notes,
## reward = XP and medals, wrong = errors.

signal theme_changed

## Each palette: UI colours (bg, panel, line, text, dim, accent, ink, accent2,
## reward) + 3D board colours (tile, peer, same, sel, plate, given, player,
## wrong, note). `ink` is the text colour on an accent fill.
const PALETTES := {
	"light": {"label": "Light", "bg": Color("EEF2FB"), "panel": Color("FFFFFF"), "line": Color("2457D6"), "text": Color("101631"), "dim": Color("56607F"),
		"accent": Color("2457D6"), "ink": Color("FFFFFF"), "accent2": Color("7A5CFF"), "reward": Color("B86E00"),
		"tile": Color("FFFFFF"), "peer": Color("DCE6FB"), "same": Color("CFC4FF"), "sel": Color("2457D6"), "plate": Color("C9D3EC"),
		"given": Color("101631"), "player": Color("2457D6"), "wrong": Color("D61F45"), "note": Color("56607F")},
	"dark": {"label": "Dark", "bg": Color("060A17"), "panel": Color("111A38"), "line": Color("82A5FF"), "text": Color("E8EEFF"), "dim": Color("8C9BC7"),
		"accent": Color("3EE6FF"), "ink": Color("04121A"), "accent2": Color("9B8CFF"), "reward": Color("FFB547"),
		"tile": Color("15224A"), "peer": Color("1A3A63"), "same": Color("3B3478"), "sel": Color("3EE6FF"), "plate": Color("0B1330"),
		"given": Color("E8EEFF"), "player": Color("3EE6FF"), "wrong": Color("FF5C7A"), "note": Color("8C9BC7")},
	"ocean": {"label": "Ocean", "bg": Color("04161F"), "panel": Color("0B2A36"), "line": Color("6FD6E6"), "text": Color("E4F8FB"), "dim": Color("86AEB8"),
		"accent": Color("21C7D9"), "ink": Color("03252B"), "accent2": Color("5BA8FF"), "reward": Color("FFC15E"),
		"tile": Color("0F3442"), "peer": Color("15485A"), "same": Color("1F3F78"), "sel": Color("21C7D9"), "plate": Color("06202B"),
		"given": Color("E4F8FB"), "player": Color("21C7D9"), "wrong": Color("FF6B7F"), "note": Color("86AEB8")},
	"forest": {"label": "Forest", "bg": Color("04140E"), "panel": Color("0C2B1F"), "line": Color("7FE3B5"), "text": Color("E6FBEF"), "dim": Color("8DB5A0"),
		"accent": Color("4BE3A0"), "ink": Color("06281A"), "accent2": Color("C6F25A"), "reward": Color("FFC15E"),
		"tile": Color("10362A"), "peer": Color("164A39"), "same": Color("3C4F1C"), "sel": Color("4BE3A0"), "plate": Color("07211A"),
		"given": Color("E6FBEF"), "player": Color("4BE3A0"), "wrong": Color("FF6B7F"), "note": Color("8DB5A0")},
	"sunset": {"label": "Sunset", "bg": Color("180A10"), "panel": Color("33141F"), "line": Color("FFA27A"), "text": Color("FFEDE6"), "dim": Color("C39A90"),
		"accent": Color("FF8A4C"), "ink": Color("2E1206"), "accent2": Color("FF5C9A"), "reward": Color("FFC15E"),
		"tile": Color("3A1822"), "peer": Color("4E2027"), "same": Color("5A1F3E"), "sel": Color("FF8A4C"), "plate": Color("220C14"),
		"given": Color("FFEDE6"), "player": Color("FF8A4C"), "wrong": Color("FF5C7A"), "note": Color("C39A90")},
}

## Optional bundled fonts (SIL OFL). When a file is missing the engine font is
## used, embolded / spaced to approximate the design.
const FONT_FILES := {
	"head": "res://assets/fonts/SpaceGrotesk.ttf",
	"body": "res://assets/fonts/Inter.ttf",
	"mono": "res://assets/fonts/JetBrainsMono.ttf",
}

var palette: Dictionary = PALETTES["dark"]
var theme := Theme.new()
var font_head: FontVariation
var font_body: FontVariation
var font_mono: FontVariation

func _ready() -> void:
	_load_fonts()
	Settings.changed.connect(apply)
	apply()

func apply() -> void:
	palette = PALETTES.get(Settings.theme_name, PALETTES["dark"])
	_build_theme()
	get_tree().root.theme = theme
	RenderingServer.set_default_clear_color(palette["bg"])
	theme_changed.emit()

## Colour of the glass "bay" the 3D board sits in (panel over background).
func bay_color() -> Color:
	return palette["bg"].lerp(palette["panel"], 0.6)

func is_light() -> bool:
	return palette["bg"].get_luminance() > 0.5

func _load_fonts() -> void:
	font_head = _variant("head", 600, 0.55, 0)
	font_body = _variant("body", 400, 0.0, 0)
	font_mono = _variant("mono", 600, 0.35, 3)

func _variant(kind: String, weight: int, fallback_bold: float, spacing: int) -> FontVariation:
	var v := FontVariation.new()
	var path: String = FONT_FILES[kind]
	if ResourceLoader.exists(path):
		v.base_font = load(path)
		v.variation_opentype = {"wght": weight}
	else:
		v.base_font = ThemeDB.fallback_font
		v.variation_embolden = fallback_bold
	v.spacing_glyph = spacing
	return v

# --- Style boxes -------------------------------------------------------------

## Glass panel: translucent panel colour, 2 px hairline border, optional glow.
func glass(radius: int = 52, margin: int = 40, border: Color = Color(0, 0, 0, 0), glow: Color = Color(0, 0, 0, 0)) -> StyleBoxFlat:
	var b := StyleBoxFlat.new()
	var p: Color = palette["panel"]
	b.bg_color = Color(p, 0.94 if is_light() else 0.80)
	b.set_corner_radius_all(radius)
	b.set_content_margin_all(margin)
	b.set_border_width_all(2)
	b.border_color = border if border.a > 0.0 else Color(palette["line"], 0.22)
	b.anti_aliasing = true
	if glow.a > 0.0:
		b.shadow_color = glow
		b.shadow_size = 22
	elif is_light():
		b.shadow_color = Color(0.1, 0.15, 0.35, 0.10)
		b.shadow_size = 14
		b.shadow_offset = Vector2(0, 6)
	return b

## Solid fill (primary buttons, selected states). `glow` adds a soft halo in the same colour.
func fill(color: Color, radius: int = 44, margin: int = 24, glow: bool = true) -> StyleBoxFlat:
	var b := StyleBoxFlat.new()
	b.bg_color = color
	b.set_corner_radius_all(radius)
	b.set_content_margin_all(margin)
	b.anti_aliasing = true
	if glow:
		b.shadow_color = Color(color, 0.42)
		b.shadow_size = 24
	return b

## Kept for older call sites: a filled box (raised = glow).
func make_box(color: Color, radius: int = 28, margin: int = 16, raised: bool = true) -> StyleBoxFlat:
	return fill(color, radius, margin, raised)

## Applies the primary (accent fill) look to a button.
func style_primary(b: Button) -> void:
	var a: Color = palette["accent"]
	b.add_theme_stylebox_override("normal", fill(a, 44))
	b.add_theme_stylebox_override("hover", fill(a.lightened(0.1), 44))
	b.add_theme_stylebox_override("pressed", fill(a.darkened(0.15), 44, 24, false))
	b.add_theme_stylebox_override("hover_pressed", fill(a.darkened(0.15), 44, 24, false))
	b.add_theme_stylebox_override("disabled", fill(Color(a, 0.35), 44, 24, false))
	for c in ["font_color", "font_hover_color", "font_pressed_color", "font_hover_pressed_color", "font_focus_color", "font_disabled_color"]:
		b.add_theme_color_override(c, palette["ink"])
	b.add_theme_font_override("font", font_head)

func _build_theme() -> void:
	var t := Theme.new()
	var text: Color = palette["text"]
	t.default_font = font_body
	t.set_color("font_color", "Label", text)
	t.set_font_size("font_size", "Label", 38)
	for type in ["Button", "OptionButton"]:
		t.set_stylebox("normal", type, glass(44, 24))
		t.set_stylebox("hover", type, glass(44, 24, Color(palette["accent"], 0.45)))
		t.set_stylebox("pressed", type, glass(44, 24, Color(palette["accent"], 0.8)))
		t.set_stylebox("hover_pressed", type, glass(44, 24, Color(palette["accent"], 0.8)))
		var dis := glass(44, 24)
		dis.bg_color = Color(dis.bg_color, 0.4)
		t.set_stylebox("disabled", type, dis)
		t.set_stylebox("focus", type, StyleBoxEmpty.new())
		for c in ["font_color", "font_hover_color", "font_pressed_color", "font_hover_pressed_color", "font_focus_color"]:
			t.set_color(c, type, text)
		t.set_color("font_disabled_color", type, Color(text, 0.35))
		t.set_font("font", type, font_head)
		t.set_font_size("font_size", type, 42)
	t.set_stylebox("panel", "PanelContainer", glass())
	t.set_stylebox("panel", "ScrollContainer", StyleBoxEmpty.new())
	theme = t
