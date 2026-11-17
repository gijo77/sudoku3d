extends Control
## Settings: sound, music, vibration, theme, highlight options.

const UI := preload("res://scripts/ui/ui_kit.gd")

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
	var row := HBoxContainer.new()
	row.add_child(UI.label("Theme", 44))
	row.get_child(0).size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var opt := OptionButton.new()
	opt.custom_minimum_size = Vector2(380, 110)
	var i := 0
	for key in ThemeManager.PALETTES:
		opt.add_item(ThemeManager.PALETTES[key]["label"], i)
		opt.set_item_metadata(i, key)
		if key == Settings.theme_name:
			opt.select(i)
		i += 1
	opt.item_selected.connect(func(idx: int) -> void: Settings.set_value("theme_name", opt.get_item_metadata(idx)))
	row.add_child(opt)
	box.add_child(row)
	v.add_child(UI.spacer())
	v.add_child(UI.button("Back", on_back))

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
