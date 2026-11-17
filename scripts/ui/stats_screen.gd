extends Control
## Statistics: games played, win rate, best time per difficulty, daily streak.

const UI := preload("res://scripts/ui/ui_kit.gd")
const Generator := preload("res://scripts/logic/generator.gd")

func _ready() -> void:
	var v := UI.make_screen(self, "Statistics")
	var s = Stats.data
	var panel := PanelContainer.new()
	v.add_child(panel)
	var grid := GridContainer.new()
	grid.columns = 4
	grid.add_theme_constant_override("h_separation", 24)
	grid.add_theme_constant_override("v_separation", 22)
	panel.add_child(grid)
	for h in ["", "Played", "Win %", "Best"]:
		grid.add_child(UI.label(h, 34, HORIZONTAL_ALIGNMENT_CENTER))
	_row(grid, "All", s.played(), s.win_rate(), -1.0)
	for d in Generator.NAMES:
		_row(grid, Generator.NAMES[d], s.played(d), s.win_rate(d), s.best_time(d))
	for c in grid.get_children():
		c.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	v.add_child(UI.label("Daily streak: %d day(s)   |   Dailies done: %d" % [s.daily_streak(UI.today_key()), s.daily.size()], 38, HORIZONTAL_ALIGNMENT_CENTER))
	v.add_child(UI.spacer())
	v.add_child(UI.button("Back", on_back))

func _row(grid: GridContainer, name: String, played: int, rate: float, best: float) -> void:
	grid.add_child(UI.label(name, 40))
	grid.add_child(UI.label(str(played), 40, HORIZONTAL_ALIGNMENT_CENTER))
	grid.add_child(UI.label("%d%%" % int(round(rate * 100.0)) if played > 0 else "-", 40, HORIZONTAL_ALIGNMENT_CENTER))
	grid.add_child(UI.label(UI.fmt_time(best) if best >= 0.0 else "-", 40, HORIZONTAL_ALIGNMENT_CENTER))

func on_back() -> void:
	Nav.go("res://scenes/main_menu.tscn")
