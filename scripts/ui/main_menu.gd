extends Control
## Main menu: tile logo, Continue card, New game / Daily / Cube cards, and a
## bottom row for Statistics, Rewards and Settings.

const UI := preload("res://scripts/ui/ui_kit.gd")
const RewardsData := preload("res://scripts/game/rewards_data.gd")

func _ready() -> void:
	var v := UI.make_screen(self)
	v.add_theme_constant_override("separation", 26)
	v.add_child(UI.spacer())
	v.add_child(_logo())
	v.add_child(UI.heading("Sudoku 3D", 112))
	var pr: Dictionary = Rewards.data.progress()
	var chip := UI.label("Rank %d · %s" % [pr["rank"], RewardsData.title_for_rank(pr["rank"])], 38, HORIZONTAL_ALIGNMENT_CENTER)
	chip.add_theme_color_override("font_color", ThemeManager.palette["dim"])
	v.add_child(chip)
	v.add_child(UI.spacer())
	if SaveGame.exists():
		v.add_child(UI.icon_button("Continue", "play", func(): Nav.start_game({"mode": "resume"}), 150, 60, true))
	var grid := GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 24)
	grid.add_theme_constant_override("v_separation", 24)
	v.add_child(grid)
	var new_b := UI.icon_button("New game", "plus", func(): Nav.go("res://scenes/difficulty.tscn"), 210, 64)
	var done: bool = Stats.data.daily_done(UI.today_key())
	var daily_b := UI.icon_button("Daily puzzle" + ("  ✓" if done else ""), "calendar", func(): Nav.start_game({"mode": "daily"}), 210, 64)
	for b in [new_b, daily_b]:
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		grid.add_child(b)
	v.add_child(UI.icon_button("Cube Sudoku  (bonus)", "cube", func(): Nav.go("res://scenes/difficulty.tscn", {"cube": true}), 130, 56, true))
	var nav := HBoxContainer.new()
	nav.add_theme_constant_override("separation", 20)
	v.add_child(nav)
	for item in [["Stats", "stats", "res://scenes/stats.tscn"], ["Rewards", "trophy", "res://scenes/rewards.tscn"], ["Settings", "settings", "res://scenes/settings.tscn"]]:
		var path: String = item[2]
		var b := UI.icon_button(item[0], item[1], func(): Nav.go(path), 160, 50)
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		nav.add_child(b)
	if OS.has_feature("pc"):
		v.add_child(UI.button("Quit", func(): get_tree().quit(), 110))
	v.add_child(UI.spacer())

## A small 3 x 3 patch of raised tiles, the middle one highlighted.
func _logo() -> Control:
	var grid := GridContainer.new()
	grid.columns = 3
	grid.add_theme_constant_override("h_separation", 12)
	grid.add_theme_constant_override("v_separation", 12)
	grid.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	var digits := ["5", "3", "", "", "7", "", "", "", "9"]
	for i in 9:
		var p: Dictionary = ThemeManager.palette
		var hot := i == 4
		var t := PanelContainer.new()
		t.custom_minimum_size = Vector2(120, 120)
		t.add_theme_stylebox_override("panel", ThemeManager.make_box(p["sel"] if hot else p["tile"], 22, 6))
		var l := UI.label(digits[i], 64, HORIZONTAL_ALIGNMENT_CENTER)
		l.add_theme_color_override("font_color", Color.WHITE if hot else p["given"])
		l.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		t.add_child(l)
		grid.add_child(t)
	return grid

func on_back() -> void:
	get_tree().quit()
