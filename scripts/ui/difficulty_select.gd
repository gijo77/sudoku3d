extends Control
## Difficulty select with each level's best time.

const UI := preload("res://scripts/ui/ui_kit.gd")
const Generator := preload("res://scripts/logic/generator.gd")

func _ready() -> void:
	var cube: bool = Nav.params.get("cube", false)
	var v := UI.make_screen(self, "Cube Sudoku" if cube else "New Game")
	v.add_child(UI.spacer())
	for d in Generator.NAMES:
		var best: float = Stats.data.best_time(d + (10 if cube else 0))
		var sub := "best %s" % UI.fmt_time(best) if best >= 0.0 else "no record yet"
		v.add_child(UI.button("%s   (%s)" % [Generator.NAMES[d], sub], func(): Nav.start_game({"mode": "cube" if cube else "new", "difficulty": d}), 170))
	v.add_child(UI.spacer())
	v.add_child(UI.button("Back", on_back))

func on_back() -> void:
	Nav.go("res://scenes/main_menu.tscn")
