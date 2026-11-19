extends Control
## Settings: sound, music, vibration, highlights, graphics, rank-gated themes and the privacy policy.

const UI := preload("res://scripts/ui/ui_kit.gd")
const RewardsData := preload("res://scripts/game/rewards_data.gd")

const PRIVACY_URL := "https://gijo77.github.io/sudoku3d/"

func _ready() -> void:
	var v := UI.make_screen(self, "Settings")
	var panel := PanelContainer.new()
	v.add_child(panel)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 22)
	panel.add_child(box)
	_toggle(box, "Sound effects", "sound")
	_toggle(box, "Music", "music")
	_toggle(box, "Vibration", "vibration")
	_toggle(box, "Highlight row / column / box", "highlight_peers")
	_toggle(box, "Highlight same numbers", "highlight_same")
	_toggle(box, "High quality graphics", "quality_high")
	v.add_child(UI.label("Theme", 48))
	v.add_child(_theme_row())
	var hint := UI.label("Ocean, Forest and Sunset unlock as you rank up.", 30)
	hint.add_theme_color_override("font_color", ThemeManager.palette["dim"])
	v.add_child(hint)
	v.add_child(UI.spacer())
	v.add_child(UI.button("Privacy policy", func(): OS.shell_open(PRIVACY_URL), 110))
	v.add_child(UI.button("Back", on_back))

## One raised tile per theme; locked themes show their unlock rank and cannot be picked.
func _theme_row() -> Control:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	for key in ThemeManager.PALETTES:
		var p: Dictionary = ThemeManager.PALETTES[key]
		var open: bool = Rewards.data.theme_unlocked(key)
		var b := Button.new()
		b.custom_minimum_size = Vector2(0, 170)
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		b.disabled = not open
		b.text = "%s\n%s" % [p["label"], "" if open else "Rank %d" % RewardsData.theme_rank(key)]
		b.add_theme_font_size_override("font_size", 28)
		var face: Color = p["accent"] if open else p["tile"].darkened(0.3)
		for st in ["normal", "hover", "pressed", "hover_pressed", "disabled"]:
			var sb := ThemeManager.make_box(face, 24, 8)
			if key == Settings.theme_name:
				sb.border_width_left = 6
				sb.border_width_right = 6
				sb.border_width_top = 6
				sb.border_color = ThemeManager.palette["accent"].lightened(0.2)
			b.add_theme_stylebox_override(st, sb)
		b.add_theme_color_override("font_color", Color.WHITE)
		b.add_theme_color_override("font_hover_color", Color.WHITE)
		b.add_theme_color_override("font_pressed_color", Color.WHITE)
		b.add_theme_color_override("font_disabled_color", Color(1, 1, 1, 0.85))
		var k: String = key
		b.pressed.connect(func() -> void:
			Audio.play("click")
			Settings.set_value("theme_name", k)
			Nav.go("res://scenes/settings.tscn"))
		row.add_child(b)
	return row

func _toggle(parent: Control, text: String, key: String) -> void:
	var b := Button.new()
	b.toggle_mode = true
	b.button_pressed = Settings.get(key)
	b.custom_minimum_size = Vector2(0, 110)
	b.alignment = HORIZONTAL_ALIGNMENT_LEFT
	UI.style_toggle(b)
	var upd := func() -> void:
		b.text = "%s:  %s" % [text, "ON" if b.button_pressed else "OFF"]
	upd.call()
	b.toggled.connect(func(on: bool) -> void:
		upd.call()
		Settings.set_value(key, on))
	parent.add_child(b)

func on_back() -> void:
	Nav.go("res://scenes/main_menu.tscn")
