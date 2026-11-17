extends Control
## Main menu: Continue (when a save exists), New Game, Daily Puzzle, Statistics, Settings.

const UI := preload("res://scripts/ui/ui_kit.gd")

func _ready() -> void:
	var v := UI.make_screen(self)
	v.alignment = BoxContainer.ALIGNMENT_CENTER
	v.add_theme_constant_override("separation", 30)
	v.add_child(UI.heading("Sudoku 3D", 120))
	v.add_child(UI.spacer())
	if SaveGame.exists():
		v.add_child(UI.button("Continue", func(): Nav.start_game({"mode": "resume"})))
	v.add_child(UI.button("New Game", func(): Nav.go("res://scenes/difficulty.tscn")))
	var done: bool = Stats.data.daily_done(UI.today_key())
	v.add_child(UI.button("Daily Puzzle" + ("  ✓" if done else ""), func(): Nav.start_game({"mode": "daily"})))
	v.add_child(UI.button("Statistics", func(): Nav.go("res://scenes/stats.tscn")))
	v.add_child(UI.button("Settings", func(): Nav.go("res://scenes/settings.tscn")))
	if OS.has_feature("pc"):
		v.add_child(UI.button("Quit", func(): get_tree().quit()))
	v.add_child(UI.spacer())

func on_back() -> void:
	get_tree().quit()
