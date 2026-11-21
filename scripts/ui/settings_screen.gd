extends Control
## Settings: grouped switches, the rank-gated theme picker and the privacy policy.

const UI := preload("res://scripts/ui/ui_kit.gd")
const Glyph := preload("res://scripts/ui/glyph_icon.gd")
const RewardsData := preload("res://scripts/game/rewards_data.gd")

const PRIVACY_URL := "https://gijo77.github.io/sudoku3d/"
const THEME_SWATCH := {"light": Color("E9EEFA"), "dark": Color("3EE6FF"), "ocean": Color("21C7D9"), "forest": Color("4BE3A0"), "sunset": Color("FF8A4C")}

func _ready() -> void:
	var v := UI.make_screen(self, "Settings", "System")
	v.add_theme_constant_override("separation", 30)
	v.add_child(_group("Sound and feel", [["Sound effects", "sound", "sound"], ["Music", "music", "music"], ["Vibration", "vibration", "vibration"]]))
	v.add_child(_group("Board", [["Highlight row, column, box", "highlight_peers", "peers"], ["Highlight same numbers", "highlight_same", "same"], ["High quality 3D", "quality_high", "cube"]]))
	var tv := UI.vbox(14)
	tv.add_child(UI.mono("Theme", 25))
	tv.add_child(_theme_row())
	v.add_child(tv)
	v.add_child(_privacy_row())
	v.add_child(UI.spacer())
	v.add_child(UI.nav_dock("Settings"))

func _group(title: String, items: Array) -> Control:
	var v := UI.vbox(14)
	v.add_child(UI.mono(title, 25))
	var card := UI.card(0)
	var sb: StyleBoxFlat = card.get_theme_stylebox("panel")
	sb.content_margin_left = 40
	sb.content_margin_right = 40
	var col := UI.vbox(0)
	card.add_child(col)
	for i in items.size():
		var it: Array = items[i]
		var key: String = it[1]
		col.add_child(UI.switch_row(it[0], it[2], Settings.get(key), func(on: bool) -> void: Settings.set_value(key, on), 122))
		if i < items.size() - 1:
			var d := ColorRect.new()
			d.color = Color(ThemeManager.palette["line"], 0.12)
			d.custom_minimum_size = Vector2(0, 2)
			d.mouse_filter = Control.MOUSE_FILTER_IGNORE
			col.add_child(d)
	v.add_child(card)
	return v

## One tile per theme; locked themes show their unlock rank and cannot be picked.
func _theme_row() -> Control:
	var p: Dictionary = ThemeManager.palette
	var row := UI.hbox(22)
	for key in ThemeManager.PALETTES:
		var open: bool = Rewards.data.theme_unlocked(key)
		var cur: bool = key == Settings.theme_name
		var b := Button.new()
		b.custom_minimum_size = Vector2(0, 250)
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		b.disabled = not open
		var e := StyleBoxEmpty.new()
		for st in ["normal", "hover", "pressed", "hover_pressed", "disabled", "focus"]:
			b.add_theme_stylebox_override(st, e)
		var col := UI.vbox(10)
		col.set_anchors_preset(Control.PRESET_FULL_RECT)
		b.add_child(col)
		var tile := PanelContainer.new()
		tile.custom_minimum_size = Vector2(0, 150)
		var sb: StyleBoxFlat
		if open:
			sb = ThemeManager.fill(THEME_SWATCH[key], 33, 0, cur)
			if cur:
				sb.set_border_width_all(5)
				sb.border_color = Color.WHITE
		else:
			sb = ThemeManager.glass(33, 0, Color(p["line"], 0.35))
		tile.add_theme_stylebox_override("panel", sb)
		if not open:
			var lk: Control = Glyph.make("lock", 46, p["dim"])
			lk.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
			lk.size_flags_vertical = Control.SIZE_SHRINK_CENTER
			tile.add_child(lk)
		col.add_child(tile)
		col.add_child(UI.label(ThemeManager.PALETTES[key]["label"], 31, HORIZONTAL_ALIGNMENT_CENTER))
		col.add_child(UI.mono("Active" if cur else ("Open" if open else "Rank %d" % RewardsData.theme_rank(key)), 22, Color(0, 0, 0, 0), HORIZONTAL_ALIGNMENT_CENTER))
		UI.ignore_mouse(col)
		var k: String = key
		b.pressed.connect(func() -> void:
			Audio.play("click")
			Settings.set_value("theme_name", k)
			Nav.go("res://scenes/settings.tscn"))
		row.add_child(b)
	return row

func _privacy_row() -> Control:
	var p: Dictionary = ThemeManager.palette
	var row := UI.hbox(32)
	var ic: Control = Glyph.make("shield", 56, p["accent"])
	ic.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(ic)
	var l := UI.label("Privacy policy", 40)
	l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	l.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(l)
	var ver := UI.mono("v%s · offline" % ProjectSettings.get_setting("application/config/version", "1.1"), 24)
	ver.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(ver)
	return UI.card_button(row, func(): OS.shell_open(PRIVACY_URL))

func on_back() -> void:
	Nav.go("res://scenes/main_menu.tscn")
