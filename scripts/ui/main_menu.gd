extends Control
## Main menu (Neon Lattice): rank and streak chips, isometric tile logo, a
## Resume card, New game / Daily / Cube cards and the bottom nav dock.

const UI := preload("res://scripts/ui/ui_kit.gd")
const RewardsData := preload("res://scripts/game/rewards_data.gd")
const Ring := preload("res://scripts/ui/ring.gd")
const IsoArt := preload("res://scripts/ui/iso_art.gd")
const Glyph := preload("res://scripts/ui/glyph_icon.gd")
const Generator := preload("res://scripts/logic/generator.gd")

func _ready() -> void:
	var v := UI.make_screen(self)
	v.add_theme_constant_override("separation", 30)
	var bg: Control = get_child(0)
	bg.add_glow(Vector2(0.5, 0.25), 620.0, Color(ThemeManager.palette["accent"], 0.16))
	var p: Dictionary = ThemeManager.palette

	v.add_child(_top_row())
	var logo: Control = IsoArt.make("logo", 0, 430)
	v.add_child(logo)

	var title := UI.vbox(8)
	var name_row := UI.hbox(0)
	name_row.alignment = BoxContainer.ALIGNMENT_CENTER
	name_row.add_child(UI.title_label("SUDOKU", 110, HORIZONTAL_ALIGNMENT_CENTER))
	name_row.add_child(UI.title_label(" 3D", 110, HORIZONTAL_ALIGNMENT_CENTER, p["accent"]))
	title.add_child(name_row)
	var done: bool = Stats.data.daily_done(UI.today_key())
	var d := Time.get_date_dict_from_system()
	var months := ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"]
	var sub := "Daily grid %s · %d %s" % ["solved" if done else "online", d["day"], months[d["month"] - 1]]
	title.add_child(UI.mono(sub, 28, Color(0, 0, 0, 0), HORIZONTAL_ALIGNMENT_CENTER))
	v.add_child(title)

	if SaveGame.exists():
		var resume := _resume_card()
		if resume:
			v.add_child(resume)

	var grid := GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 33)
	grid.add_theme_constant_override("v_separation", 33)
	v.add_child(grid)
	grid.add_child(_tile_card("New game", "Easy to Expert", "plus", p["accent"], "", func(): Nav.go("res://scenes/difficulty.tscn")))
	grid.add_child(_tile_card("Daily puzzle", "Solved today" if done else "Not solved yet", "calendar", p["accent2"],
		"" if done else "+50 XP", func(): Nav.start_game({"mode": "daily"})))

	v.add_child(_cube_card())
	if OS.has_feature("pc"):
		var q := UI.button("Quit", func(): get_tree().quit(), 110)
		v.add_child(q)
	v.add_child(UI.spacer())
	v.add_child(UI.nav_dock("Home"))

func _top_row() -> Control:
	var p: Dictionary = ThemeManager.palette
	var row := UI.hbox(20)
	var pr: Dictionary = Rewards.data.progress()
	var rank_box := UI.hbox(26)
	rank_box.add_child(Ring.make(84, float(pr["into"]) / float(pr["need"]), str(pr["rank"])))
	var col := UI.vbox(0)
	col.alignment = BoxContainer.ALIGNMENT_CENTER
	col.add_child(UI.mono("Rank %d" % pr["rank"], 24))
	col.add_child(UI.label(RewardsData.title_for_rank(pr["rank"]), 36))
	rank_box.add_child(col)
	var rank_btn := UI.card_button(rank_box, func(): Nav.go("res://scenes/rewards.tscn"))
	_pill_style(rank_btn)
	row.add_child(rank_btn)
	row.add_child(_hfill())
	var streak: int = Stats.data.daily_streak(UI.today_key())
	var s_box := UI.hbox(14)
	var fl: Control = Glyph.make("flame", 50, p["reward"])
	fl.filled = streak > 0
	fl.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	s_box.add_child(fl)
	s_box.add_child(UI.title_label(str(streak), 42, HORIZONTAL_ALIGNMENT_LEFT, p["reward"]))
	var dl := UI.mono("days", 24)
	dl.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	s_box.add_child(dl)
	var s_btn := UI.card_button(s_box, func(): Nav.go("res://scenes/rewards.tscn"))
	_pill_style(s_btn)
	row.add_child(s_btn)
	return row

func _hfill() -> Control:
	var c := Control.new()
	c.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	c.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return c

## Rounded pill look for the small top chips.
func _pill_style(b: Button) -> void:
	var n := ThemeManager.glass(66, 0)
	b.add_theme_stylebox_override("normal", n)
	b.add_theme_stylebox_override("hover", n)
	var m: MarginContainer = b.get_child(0)
	m.add_theme_constant_override("margin_left", 20)
	m.add_theme_constant_override("margin_right", 38)
	m.add_theme_constant_override("margin_top", 18)
	m.add_theme_constant_override("margin_bottom", 18)

func _resume_card() -> Control:
	var saved: Dictionary = SaveGame.load_game()
	if saved.is_empty() or not saved.has("model"):
		return null
	var md: Dictionary = saved["model"]
	var grid: Array = md.get("grid", [])
	var filled := 0
	for x in grid:
		if int(x) != 0:
			filled += 1
	var frac := float(filled) / maxf(1.0, float(grid.size()))
	var mode: String = saved.get("mode", "new")
	var diff_name: String = Generator.NAMES.get(int(md.get("difficulty", 1)), "Medium")
	var what := "Daily puzzle" if mode == "daily" else ("Cube " + diff_name.to_lower() if mode == "cube" else diff_name + " puzzle")
	var lives := 3 - int(md.get("mistakes", 0))
	var p: Dictionary = ThemeManager.palette
	var row := UI.hbox(38)
	row.add_child(Ring.make(150, frac, "%d%%" % int(round(frac * 100.0))))
	var col := UI.vbox(8)
	col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	col.alignment = BoxContainer.ALIGNMENT_CENTER
	col.add_child(UI.mono("Resume", 28, p["accent"]))
	col.add_child(UI.title_label(what, 52))
	col.add_child(UI.dim("%s elapsed · %d %s left" % [UI.fmt_time(float(md.get("elapsed", 0.0))), lives, "life" if lives == 1 else "lives"], 33))
	row.add_child(col)
	var go := PanelContainer.new()
	go.add_theme_stylebox_override("panel", ThemeManager.fill(p["accent"], 38, 0))
	go.custom_minimum_size = Vector2(132, 132)
	go.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	var ic: Control = Glyph.make("play", 60, p["ink"])
	ic.filled = true
	ic.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	ic.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	go.add_child(ic)
	row.add_child(go)
	return UI.card_button(row, func(): Nav.start_game({"mode": "resume"}), Color(p["accent"], 0.5), Color(p["accent"], 0.12))

func _tile_card(title: String, sub: String, glyph: String, col: Color, tag: String, cb: Callable) -> Control:
	var v := UI.vbox(50)
	var top := UI.hbox(0)
	top.add_child(UI.icon_tile(glyph, col))
	top.add_child(_hfill())
	if tag != "":
		var p: Dictionary = ThemeManager.palette
		var t := UI.chip(tag, p["ink"] if not ThemeManager.is_light() else Color.WHITE, p["reward"])
		t.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
		top.add_child(t)
	v.add_child(top)
	var txt := UI.vbox(6)
	txt.add_child(UI.title_label(title, 46))
	txt.add_child(UI.dim(sub, 33))
	v.add_child(txt)
	var b := UI.card_button(v, cb)
	b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	return b

func _cube_card() -> Control:
	var p: Dictionary = ThemeManager.palette
	var row := UI.hbox(38)
	row.add_child(UI.icon_tile("cube", p["accent"]))
	var col := UI.vbox(6)
	col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	col.alignment = BoxContainer.ALIGNMENT_CENTER
	col.add_child(UI.title_label("Cube Sudoku", 46))
	col.add_child(UI.dim("4 × 4 × 4 · rotate the grid in 3D", 33))
	row.add_child(col)
	row.add_child(UI.chip("Bonus", p["accent"], Color(0, 0, 0, 0), Color(p["accent"], 0.5)))
	return UI.card_button(row, func(): Nav.go("res://scenes/difficulty.tscn", {"cube": true}))

func on_back() -> void:
	get_tree().quit()
