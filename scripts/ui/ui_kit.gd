extends RefCounted
## Shared building blocks for the Neon Lattice screens: safe-area layout, the
## grid background, headers, glass cards, primary / secondary buttons, chips,
## switches, segmented controls, progress bars and the bottom nav dock.
## Sizes are in the 1080 x 1920 viewport (about 2.75 x the 390 pt design).

const Glyph := preload("res://scripts/ui/glyph_icon.gd")
const Lattice := preload("res://scripts/ui/lattice.gd")

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

static func apply_safe_area(m: MarginContainer, base: int, top_extra: int = 0) -> void:
	var update := func() -> void:
		var mg := safe_margins(m.get_viewport())
		m.add_theme_constant_override("margin_left", base + int(mg["left"]))
		m.add_theme_constant_override("margin_top", base + top_extra + int(mg["top"]))
		m.add_theme_constant_override("margin_right", base + int(mg["right"]))
		m.add_theme_constant_override("margin_bottom", base + int(mg["bottom"]))
	update.call()
	m.resized.connect(update)

## Adds the grid background to `root` and returns it (for glows).
static func background(root: Control) -> Control:
	var bg = Lattice.new()
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.add_child(bg)
	root.move_child(bg, 0)
	return bg

## Full-screen background + margin + vertical box. With a title, adds a header
## (optional back button, small mono kicker above the title).
static func make_screen(root: Control, title: String = "", kicker: String = "", back: Callable = Callable()) -> VBoxContainer:
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	background(root)
	var m := MarginContainer.new()
	m.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.add_child(m)
	apply_safe_area(m, 52)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 36)
	m.add_child(v)
	if title != "":
		v.add_child(header(title, kicker, back))
	return v

static func header(title: String, kicker: String = "", back: Callable = Callable(), right: Control = null) -> Control:
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 36)
	if back.is_valid():
		var b := square_button("back", back)
		b.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		h.add_child(b)
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 2)
	col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	if kicker != "":
		col.add_child(mono(kicker, 27))
	col.add_child(title_label(title, 72))
	h.add_child(col)
	if right:
		right.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		h.add_child(right)
	return h

# --- Text --------------------------------------------------------------------

static func label(text: String, size: int = 38, align: int = HORIZONTAL_ALIGNMENT_LEFT, color: Color = Color(0, 0, 0, 0)) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", size)
	l.horizontal_alignment = align as HorizontalAlignment
	if color.a > 0.0:
		l.add_theme_color_override("font_color", color)
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return l

## Display text (titles, digits, numbers).
static func title_label(text: String, size: int = 72, align: int = HORIZONTAL_ALIGNMENT_LEFT, color: Color = Color(0, 0, 0, 0)) -> Label:
	var l := label(text, size, align, color)
	l.add_theme_font_override("font", ThemeManager.font_head)
	return l

static func heading(text: String, size: int = 84) -> Label:
	return title_label(text, size, HORIZONTAL_ALIGNMENT_CENTER)

## Small upper-case HUD label.
static func mono(text: String, size: int = 28, color: Color = Color(0, 0, 0, 0), align: int = HORIZONTAL_ALIGNMENT_LEFT) -> Label:
	var l := label(text.to_upper(), size, align, color if color.a > 0.0 else ThemeManager.palette["dim"])
	l.add_theme_font_override("font", ThemeManager.font_mono)
	return l

static func dim(text: String, size: int = 34, align: int = HORIZONTAL_ALIGNMENT_LEFT) -> Label:
	var l := label(text, size, align, ThemeManager.palette["dim"])
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	return l

# --- Buttons -----------------------------------------------------------------

static func _hook(b: BaseButton, cb: Callable, click: bool) -> void:
	if click:
		b.pressed.connect(func() -> void: Audio.play("click"))
	if cb.is_valid():
		b.pressed.connect(cb)

## Secondary (glass) button.
static func button(text: String, cb: Callable, height: int = 143, click: bool = true) -> Button:
	var b := Button.new()
	b.text = text
	b.custom_minimum_size = Vector2(0, height)
	_hook(b, cb, click)
	return b

## Primary button: accent fill with glow, dark ink text.
static func primary(text: String, cb: Callable, height: int = 154, glyph: String = "") -> Button:
	var b := button("" if glyph != "" else text, cb, height)
	ThemeManager.style_primary(b)
	b.add_theme_font_size_override("font_size", 46)
	if glyph != "":
		var row := _center_row(b)
		var ic: Control = Glyph.make(glyph, 48, ThemeManager.palette["ink"])
		ic.filled = glyph == "play"
		row.add_child(ic)
		row.add_child(title_label(text, 46, HORIZONTAL_ALIGNMENT_LEFT, ThemeManager.palette["ink"]))
	return b

static func _center_row(parent: Control) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 22)
	row.set_anchors_preset(Control.PRESET_FULL_RECT)
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(row)
	return row

## Icon-only glass square (back, pause).
static func square_button(glyph: String, cb: Callable, size: int = 121) -> Button:
	var b := button("", cb, size)
	b.custom_minimum_size = Vector2(size, size)
	b.add_theme_stylebox_override("normal", ThemeManager.glass(38, 0))
	var ic: Control = Glyph.make(glyph, size * 0.42, ThemeManager.palette["text"])
	ic.set_anchors_preset(Control.PRESET_CENTER)
	ic.position = -ic.custom_minimum_size / 2.0
	b.add_child(ic)
	return b

## Glass button with an icon above (or beside) a label.
static func icon_button(text: String, glyph: String, cb: Callable, height: int = 140, size: int = 52, horizontal: bool = false) -> Button:
	var b := button("", cb, height)
	var box: BoxContainer = HBoxContainer.new() if horizontal else VBoxContainer.new()
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	box.add_theme_constant_override("separation", 18 if horizontal else 8)
	box.set_anchors_preset(Control.PRESET_FULL_RECT)
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var icon: Control = Glyph.make(glyph, size, ThemeManager.palette["text"])
	icon.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	box.add_child(icon)
	if text != "":
		box.add_child(mono(text, 25, ThemeManager.palette["text"], HORIZONTAL_ALIGNMENT_CENTER) if not horizontal else title_label(text, 44))
	b.add_child(box)
	return b

## A glass button whose content is any control tree (cards on the menus).
## `content` is added inside a margin; all children ignore the mouse.
static func card_button(content: Control, cb: Callable, border: Color = Color(0, 0, 0, 0), glow: Color = Color(0, 0, 0, 0)) -> Button:
	var b := button("", cb, 0)
	var n := ThemeManager.glass(55, 0, border, glow)
	b.add_theme_stylebox_override("normal", n)
	b.add_theme_stylebox_override("hover", n)
	var pr := ThemeManager.glass(55, 0, Color(ThemeManager.palette["accent"], 0.8), glow)
	b.add_theme_stylebox_override("pressed", pr)
	b.add_theme_stylebox_override("hover_pressed", pr)
	var m := MarginContainer.new()
	for side in ["left", "top", "right", "bottom"]:
		m.add_theme_constant_override("margin_" + side, 40)
	m.set_anchors_preset(Control.PRESET_FULL_RECT)
	m.mouse_filter = Control.MOUSE_FILTER_IGNORE
	m.add_child(content)
	b.add_child(m)
	ignore_mouse(content)
	# size the button to its content
	m.minimum_size_changed.connect(func() -> void: b.custom_minimum_size = m.get_combined_minimum_size())
	b.custom_minimum_size = m.get_combined_minimum_size()
	return b

static func ignore_mouse(c: Control) -> void:
	c.mouse_filter = Control.MOUSE_FILTER_IGNORE
	for ch in c.get_children():
		if ch is Control:
			ignore_mouse(ch)

## Rounded icon tile (coloured tint behind a glyph) used on menu cards.
static func icon_tile(glyph: String, col: Color, size: int = 110) -> Control:
	var p := PanelContainer.new()
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(col, 0.13)
	sb.set_border_width_all(2)
	sb.border_color = Color(col, 0.42)
	sb.set_corner_radius_all(int(size * 0.3))
	sb.anti_aliasing = true
	p.add_theme_stylebox_override("panel", sb)
	p.custom_minimum_size = Vector2(size, size)
	p.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	p.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	var ic: Control = Glyph.make(glyph, size * 0.52, col)
	ic.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	ic.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	p.add_child(ic)
	return p

# --- Panels, chips, bars --------------------------------------------------------

static func card(margin: int = 40, border: Color = Color(0, 0, 0, 0), glow: Color = Color(0, 0, 0, 0)) -> PanelContainer:
	var p := PanelContainer.new()
	p.add_theme_stylebox_override("panel", ThemeManager.glass(55, margin, border, glow))
	return p

## Small rounded tag (e.g. "+50 XP", "Bonus").
static func chip(text: String, fg: Color, bg: Color = Color(0, 0, 0, 0), border: Color = Color(0, 0, 0, 0)) -> Control:
	var p := PanelContainer.new()
	var sb := StyleBoxFlat.new()
	sb.bg_color = bg
	sb.set_corner_radius_all(16)
	sb.content_margin_left = 20
	sb.content_margin_right = 20
	sb.content_margin_top = 8
	sb.content_margin_bottom = 8
	if border.a > 0.0:
		sb.set_border_width_all(2)
		sb.border_color = border
	p.add_theme_stylebox_override("panel", sb)
	p.add_child(mono(text, 24, fg))
	p.size_flags_horizontal = Control.SIZE_SHRINK_END
	p.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	p.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return p

## Thin progress bar (see bar.gd); set `.frac` later to animate it.
static func bar(frac: float, col: Color, height: int = 12, back_frac: float = -1.0, back_col: Color = Color(0, 0, 0, 0)) -> Control:
	var c = load("res://scripts/ui/bar.gd").new()
	c.custom_minimum_size = Vector2(0, height)
	c.color = col
	c.frac = frac
	c.back_frac = back_frac
	c.back_color = back_col
	return c

static func _pill(c: CanvasItem, rect: Rect2, col: Color, r: float) -> void:
	var sb := StyleBoxFlat.new()
	sb.bg_color = col
	sb.set_corner_radius_all(int(r))
	sb.anti_aliasing = true
	sb.draw(c.get_canvas_item(), rect)

## Value + caption tile (pause / end screens, stats).
static func stat_tile(value: String, caption: String, col: Color = Color(0, 0, 0, 0)) -> Control:
	var p := PanelContainer.new()
	var sb := ThemeManager.glass(40, 26)
	sb.bg_color = Color(ThemeManager.palette["accent"], 0.06)
	sb.border_color = Color(ThemeManager.palette["line"], 0.16)
	p.add_theme_stylebox_override("panel", sb)
	p.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var v := VBoxContainer.new()
	v.alignment = BoxContainer.ALIGNMENT_CENTER
	v.add_theme_constant_override("separation", 6)
	v.add_child(title_label(value, 56, HORIZONTAL_ALIGNMENT_CENTER, col))
	v.add_child(mono(caption, 24, Color(0, 0, 0, 0), HORIZONTAL_ALIGNMENT_CENTER))
	p.add_child(v)
	return p

# --- Controls ------------------------------------------------------------------

## Settings-style switch row: icon, label and a glowing switch on the right.
static func switch_row(text: String, glyph: String, on: bool, cb: Callable, height: int = 138) -> Button:
	var b := Button.new()
	b.toggle_mode = true
	b.button_pressed = on
	b.custom_minimum_size = Vector2(0, height)
	var empty := StyleBoxEmpty.new()
	for st in ["normal", "hover", "pressed", "hover_pressed", "focus"]:
		b.add_theme_stylebox_override(st, empty)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 32)
	row.set_anchors_preset(Control.PRESET_FULL_RECT)
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	b.add_child(row)
	var p: Dictionary = ThemeManager.palette
	var ic: Control = Glyph.make(glyph, 56, p["accent"] if on else p["dim"])
	ic.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(ic)
	var l := label(text, 40)
	l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	l.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(l)
	var sw := Control.new()
	sw.custom_minimum_size = Vector2(127, 72)
	sw.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	sw.mouse_filter = Control.MOUSE_FILTER_IGNORE
	sw.draw.connect(func() -> void:
		var pal: Dictionary = ThemeManager.palette
		var o := b.button_pressed
		var track: Color = pal["accent"] if o else Color(pal["line"], 0.22)
		if o:
			_pill(sw, Rect2(-6, -6, sw.size.x + 12, sw.size.y + 12), Color(pal["accent"], 0.2), 42)
		_pill(sw, Rect2(Vector2.ZERO, sw.size), track, 36)
		var r := 27.0
		var cx := sw.size.x - 36.0 if o else 36.0
		sw.draw_circle(Vector2(cx, sw.size.y / 2.0), r, pal["ink"] if o else pal["dim"]))
	row.add_child(sw)
	b.toggled.connect(func(v: bool) -> void:
		Audio.play("click")
		ic.color = ThemeManager.palette["accent"] if v else ThemeManager.palette["dim"]
		ic.queue_redraw()
		sw.queue_redraw()
		cb.call(v))
	return b

## Segmented control in a glass pill. `cb` receives the chosen index.
static func segmented(options: Array, index: int, cb: Callable, height: int = 121) -> Control:
	var p := PanelContainer.new()
	p.add_theme_stylebox_override("panel", ThemeManager.glass(44, 14))
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	p.add_child(row)
	var btns: Array = []
	for i in options.size():
		var b := Button.new()
		b.text = options[i]
		b.custom_minimum_size = Vector2(0, height)
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		b.add_theme_font_size_override("font_size", 38)
		row.add_child(b)
		btns.append(b)
	var paint := func(sel: int) -> void:
		for i in btns.size():
			var b: Button = btns[i]
			if i == sel:
				ThemeManager.style_primary(b)
				b.add_theme_stylebox_override("normal", ThemeManager.fill(ThemeManager.palette["accent"], 34, 16))
			else:
				var e := StyleBoxEmpty.new()
				for st in ["normal", "hover", "pressed", "hover_pressed"]:
					b.add_theme_stylebox_override(st, e)
				for c in ["font_color", "font_hover_color", "font_pressed_color", "font_hover_pressed_color"]:
					b.add_theme_color_override(c, ThemeManager.palette["dim"])
	paint.call(index)
	for i in btns.size():
		btns[i].pressed.connect(func() -> void:
			Audio.play("click")
			paint.call(i)
			cb.call(i))
	return p

const NAV_ITEMS := [["Home", "home", "res://scenes/main_menu.tscn"], ["Stats", "stats", "res://scenes/stats.tscn"],
	["Rewards", "trophy", "res://scenes/rewards.tscn"], ["Settings", "settings", "res://scenes/settings.tscn"]]

## Bottom navigation dock; `current` is the active item's name.
static func nav_dock(current: String) -> Control:
	var p := PanelContainer.new()
	p.add_theme_stylebox_override("panel", ThemeManager.glass(66, 22))
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	p.add_child(row)
	var pal: Dictionary = ThemeManager.palette
	for item in NAV_ITEMS:
		var active: bool = item[0] == current
		var path: String = item[2]
		var b := Button.new()
		b.custom_minimum_size = Vector2(0, 160)
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var face := StyleBoxEmpty.new() as StyleBox
		if active:
			var sb := StyleBoxFlat.new()
			sb.bg_color = Color(pal["accent"], 0.13)
			sb.set_corner_radius_all(44)
			face = sb
		for st in ["normal", "hover", "pressed", "hover_pressed"]:
			b.add_theme_stylebox_override(st, face)
		var col := VBoxContainer.new()
		col.alignment = BoxContainer.ALIGNMENT_CENTER
		col.add_theme_constant_override("separation", 10)
		col.set_anchors_preset(Control.PRESET_FULL_RECT)
		col.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var c: Color = pal["accent"] if active else pal["dim"]
		var ic: Control = Glyph.make(item[1], 60, c)
		ic.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		col.add_child(ic)
		col.add_child(mono(item[0], 24, c, HORIZONTAL_ALIGNMENT_CENTER))
		b.add_child(col)
		if not active:
			_hook(b, func(): Nav.go(path), true)
		row.add_child(b)
	return p

# --- Misc ----------------------------------------------------------------------

static func spacer() -> Control:
	var c := Control.new()
	c.size_flags_vertical = Control.SIZE_EXPAND_FILL
	c.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return c

static func hbox(sep: int = 24) -> HBoxContainer:
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", sep)
	return h

static func vbox(sep: int = 24) -> VBoxContainer:
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", sep)
	return v

static func fmt_time(seconds: float) -> String:
	var s := int(seconds)
	return "%d:%02d" % [s / 60, s % 60] if seconds >= 0.0 else "--:--"

static func today_key() -> String:
	var d := Time.get_date_dict_from_system()
	return "%04d-%02d-%02d" % [d["year"], d["month"], d["day"]]
