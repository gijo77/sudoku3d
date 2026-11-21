extends Control
## New game: Classic / Cube switch and one card per level with a difficulty
## meter, clue count, best time, XP and par time (Speedster medal).

const UI := preload("res://scripts/ui/ui_kit.gd")
const Generator := preload("res://scripts/logic/generator.gd")
const Cube := preload("res://scripts/logic/cube_sudoku.gd")
const RewardsData := preload("res://scripts/game/rewards_data.gd")

const LEVEL_COLORS := [Color("4BE3A0"), Color("3EE6FF"), Color("9B8CFF"), Color("FF6FA8")]

var cube := false
var _list: VBoxContainer
var _tip: Label

func _ready() -> void:
	cube = Nav.params.get("cube", false)
	var v := UI.make_screen(self, "New game", "Select protocol", on_back)
	v.add_child(UI.segmented(["Classic 9 × 9", "Cube 4 × 4 × 4"], 1 if cube else 0, func(i: int) -> void:
		cube = i == 1
		_fill()))
	_list = UI.vbox(33)
	v.add_child(_list)
	var tip_card := UI.card(40, Color(ThemeManager.palette["accent2"], 0.3))
	var sb: StyleBoxFlat = tip_card.get_theme_stylebox("panel")
	sb.bg_color = Color(ThemeManager.palette["accent2"], 0.08)
	var row := UI.hbox(32)
	var ic: Control = UI.Glyph.make("hint", 56, ThemeManager.palette["accent2"])
	ic.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	row.add_child(ic)
	_tip = UI.dim("", 35)
	_tip.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(_tip)
	tip_card.add_child(row)
	v.add_child(tip_card)
	v.add_child(UI.spacer())
	v.add_child(UI.mono("3 lives · hints · undo · notes", 26, Color(0, 0, 0, 0), HORIZONTAL_ALIGNMENT_CENTER))
	_fill()

func _fill() -> void:
	for c in _list.get_children():
		c.queue_free()
	for d in Generator.NAMES:
		_list.add_child(_level_card(d))
	_tip.text = ("Each layer is a 4 × 4 Sudoku, and every vertical pillar holds 1 to 4 once. Drag to orbit the cube."
		if cube else "Beat the par time to count toward the Speedster medal. Finish with no mistakes for +30 XP.")

func _level_card(d: int) -> Control:
	var p: Dictionary = ThemeManager.palette
	var col: Color = LEVEL_COLORS[d]
	var row := UI.hbox(40)
	# meter: four rising bars, lit up to this level
	var meter := Control.new()
	meter.custom_minimum_size = Vector2(80, 80)
	meter.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	meter.draw.connect(func() -> void:
		for k in 4:
			var h := 28.0 + k * 17.0
			var c := col if k <= d else Color(ThemeManager.palette["line"], 0.22)
			meter.draw_rect(Rect2(k * 20.0, meter.size.y - h, 14.0, h), c))
	row.add_child(meter)
	var mid := UI.vbox(8)
	mid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	mid.alignment = BoxContainer.ALIGNMENT_CENTER
	var name_row := UI.hbox(22)
	name_row.add_child(UI.title_label(Generator.NAMES[d], 55))
	var clues: int = Cube.TARGET_CLUES[d] if cube else Generator.TARGET_CLUES[d]
	var cl := UI.mono("%d%s clues" % [clues, " of 64" if cube else ""], 25)
	cl.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	name_row.add_child(cl)
	mid.add_child(name_row)
	var best: float = Stats.data.best_time(d + (10 if cube else 0))
	mid.add_child(UI.dim("Best %s" % UI.fmt_time(best) if best >= 0.0 else "No record yet", 33))
	row.add_child(mid)
	var right := UI.vbox(10)
	right.alignment = BoxContainer.ALIGNMENT_CENTER
	var xp := (70 if cube else 60) + int(RewardsData.DIFFICULTY_BONUS[d])
	right.add_child(UI.mono("+%d XP" % xp, 28, p["reward"], HORIZONTAL_ALIGNMENT_RIGHT))
	var par := "4 × 4 layers" if cube else "Par %d min" % int(RewardsData.PAR_TIMES[d] / 60.0)
	right.add_child(UI.mono(par, 24, Color(0, 0, 0, 0), HORIZONTAL_ALIGNMENT_RIGHT))
	row.add_child(right)
	var b := UI.card_button(row, func(): Nav.start_game({"mode": "cube" if cube else "new", "difficulty": d}))
	# accent strip on the left edge
	var strip := ColorRect.new()
	strip.color = col
	strip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	strip.anchor_top = 0.2
	strip.anchor_bottom = 0.8
	strip.offset_left = 0
	strip.offset_right = 8
	b.add_child(strip)
	return b

func on_back() -> void:
	Nav.go("res://scenes/main_menu.tscn")
