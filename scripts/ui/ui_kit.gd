extends RefCounted
## Small helpers shared by the menu screens: safe-area aware screen layout,
## headings, buttons and spacers. Colours come from the global Theme.

## Margins (in viewport units) to keep clear of notches / cut-outs / gesture bars.
static func safe_margins(vp: Viewport) -> Dictionary:
	var zero := {"left": 0, "top": 0, "right": 0, "bottom": 0}
	if not OS.has_feature("mobile"):
		return zero
	var win := Vector2(DisplayServer.window_get_size())
	if win.x <= 0.0 or win.y <= 0.0:
		return zero
	var safe := DisplayServer.get_display_safe_area()
	var scr := Vector2(DisplayServer.screen_get_size())
	var vis := vp.get_visible_rect().size
	var sx := vis.x / win.x
	var sy := vis.y / win.y
	return {
		"left": maxf(0.0, safe.position.x) * sx,
		"top": maxf(0.0, safe.position.y) * sy,
		"right": maxf(0.0, scr.x - safe.end.x) * sx,
		"bottom": maxf(0.0, scr.y - safe.end.y) * sy,
	}

static func apply_safe_area(m: MarginContainer, base: int) -> void:
	var update := func() -> void:
		var mg := safe_margins(m.get_viewport())
		m.add_theme_constant_override("margin_left", base + int(mg["left"]))
		m.add_theme_constant_override("margin_top", base + int(mg["top"]))
		m.add_theme_constant_override("margin_right", base + int(mg["right"]))
		m.add_theme_constant_override("margin_bottom", base + int(mg["bottom"]))
	update.call()
	m.resized.connect(update)

## Full-screen margin + vertical box. Returns the box to add content to.
static func make_screen(root: Control, title: String = "") -> VBoxContainer:
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	var m := MarginContainer.new()
	m.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.add_child(m)
	apply_safe_area(m, 48)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 28)
	m.add_child(v)
	if title != "":
		v.add_child(heading(title, 84))
	return v

static func heading(text: String, size: int = 84) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", size)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	return l

static func label(text: String, size: int = 40, align: int = HORIZONTAL_ALIGNMENT_LEFT) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", size)
	l.horizontal_alignment = align as HorizontalAlignment
	return l

static func button(text: String, cb: Callable, height: int = 140, click: bool = true) -> Button:
	var b := Button.new()
	b.text = text
	b.custom_minimum_size = Vector2(0, height)
	if click:
		b.pressed.connect(func() -> void: Audio.play("click"))
	b.pressed.connect(cb)
	return b

const Glyph := preload("res://scripts/ui/glyph_icon.gd")

## Button with a vector icon above a label (menu cards, action bar).
static func icon_button(text: String, glyph: String, cb: Callable, height: int = 140, size: int = 52, horizontal: bool = false) -> Button:
	var b := button("", cb, height)
	var box: BoxContainer = HBoxContainer.new() if horizontal else VBoxContainer.new()
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	box.add_theme_constant_override("separation", 14 if horizontal else 4)
	box.set_anchors_preset(Control.PRESET_FULL_RECT)
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var icon: Control = Glyph.make(glyph, size, Color.WHITE)
	icon.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	box.add_child(icon)
	if text != "":
		var l := Label.new()
		l.text = text
		l.add_theme_font_size_override("font_size", 32 if not horizontal else 44)
		l.add_theme_color_override("font_color", Color.WHITE)
		l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		l.mouse_filter = Control.MOUSE_FILTER_IGNORE
		box.add_child(l)
	b.add_child(box)
	return b

## Toggle buttons: dim when off, accent when on.
static func style_toggle(b: Button) -> void:
	var accent: Color = ThemeManager.palette["accent"]
	var off: Color = accent.lerp(ThemeManager.palette["bg"], 0.65)
	for st in ["normal", "hover"]:
		b.add_theme_stylebox_override(st, ThemeManager.make_box(off))
	for st in ["pressed", "hover_pressed"]:
		b.add_theme_stylebox_override(st, ThemeManager.make_box(accent))
	b.add_theme_color_override("font_color", ThemeManager.palette["text"])
	b.add_theme_color_override("font_hover_color", ThemeManager.palette["text"])
	b.add_theme_color_override("font_pressed_color", Color.WHITE)
	b.add_theme_color_override("font_hover_pressed_color", Color.WHITE)

static func spacer() -> Control:
	var c := Control.new()
	c.size_flags_vertical = Control.SIZE_EXPAND_FILL
	c.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return c

static func fmt_time(seconds: float) -> String:
	var s := int(seconds)
	return "%d:%02d" % [s / 60, s % 60] if seconds >= 0.0 else "--:--"

static func today_key() -> String:
	var d := Time.get_date_dict_from_system()
	return "%04d-%02d-%02d" % [d["year"], d["month"], d["day"]]
