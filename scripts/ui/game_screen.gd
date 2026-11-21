extends Control
## Game screen: board view (3D or 2D), number pad with remaining badges, notes,
## undo/redo, erase, hint, mistakes (max 3), timer, pause and end overlays,
## autosave and stats. Started via Nav params:
##   {mode: "new", difficulty: int} | {mode: "daily"} | {mode: "resume"}
## `use_3d` selects the 3D board (default) or the 2D fallback.

const Model := preload("res://scripts/game/game_model.gd")
const Generator := preload("res://scripts/logic/generator.gd")
const Daily := preload("res://scripts/logic/daily.gd")
const BoardView := preload("res://scripts/ui/board_view_2d.gd")
const BoardWorld := preload("res://scripts/board3d/world_3d.gd")
const UI := preload("res://scripts/ui/ui_kit.gd")
const Cube := preload("res://scripts/logic/cube_sudoku.gd")
const Glyph := preload("res://scripts/ui/glyph_icon.gd")
const RewardsData := preload("res://scripts/game/rewards_data.gd")
const MEDAL_GLYPHS := {"winner": "trophy", "flawless": "shield", "streak": "flame", "cube": "cube", "speed": "bolt", "expert": "star"}

## Cube Sudoku stats are stored under difficulty + this offset.
const CUBE_STATS_OFFSET := 10

var use_3d := true
var model
var view                      # board_view_2d or world_3d (same API)
var selected := -1
var notes_mode := false
var mode := "new"             # "new" | "daily" | "cube"
var daily_key := ""
var paused := false
var _finished := false
var _title_label: Label
var _hearts: Array = []
var _timer_label: Label
var _pad_buttons: Array[Button] = []
var _pad_badges: Array[Label] = []
var _progress            # bar.gd
var _progress_label: Label
var _pause_stats: HBoxContainer
var _undo_btn: Button
var _redo_btn: Button
var _notes_btn: Button
var _pause_overlay: Control
var _end_overlay: Control
var _last_second := -1

func _ready() -> void:
	var p: Dictionary = Nav.params
	var args := OS.get_cmdline_user_args()
	if "--cube" in args:                       # screenshot helpers (see _demo)
		p = {"mode": "cube", "difficulty": 1}
	if "--dark" in args:
		Settings.theme_name = "dark"
		ThemeManager.apply()
	var want: String = p.get("mode", "new")
	var saved := {}
	if want == "resume":
		saved = SaveGame.load_game()
		want = saved.get("mode", "new")
	mode = want
	model = Model.new(Cube if mode == "cube" else null)
	_build_ui()
	match want:
		"cube":
			if saved.is_empty() or not _resume():
				_start_cube(p.get("difficulty", Generator.Difficulty.EASY))
		"daily":
			if saved.is_empty() or not _resume():
				_start_daily()
		_:
			if saved.is_empty() or not _resume():
				_start_new(p.get("difficulty", Generator.Difficulty.MEDIUM))
	Settings.changed.connect(_apply_settings)
	_apply_settings()
	if "--demo" in OS.get_cmdline_user_args():
		_demo()

func _process(delta: float) -> void:
	if paused:
		return
	model.tick(delta)
	var sec := int(model.elapsed)
	if sec != _last_second:
		_last_second = sec
		_timer_label.text = UI.fmt_time(model.elapsed)

# --- UI construction -------------------------------------------------------

func _build_ui() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	UI.background(self)
	var p: Dictionary = ThemeManager.palette
	var margin := MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(margin)
	UI.apply_safe_area(margin, 40)
	var root := VBoxContainer.new()
	root.add_theme_constant_override("separation", 34)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	margin.add_child(root)

	# HUD: pause, mode + timer, lives
	var top := UI.hbox(20)
	root.add_child(top)
	top.add_child(UI.square_button("pause", func(): _set_paused(true)))
	var mid := UI.vbox(0)
	mid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	mid.alignment = BoxContainer.ALIGNMENT_CENTER
	_title_label = UI.mono("", 27, p["accent"], HORIZONTAL_ALIGNMENT_CENTER)
	mid.add_child(_title_label)
	_timer_label = UI.title_label("0:00", 72, HORIZONTAL_ALIGNMENT_CENTER)
	mid.add_child(_timer_label)
	top.add_child(mid)
	var hearts_panel := PanelContainer.new()
	hearts_panel.add_theme_stylebox_override("panel", ThemeManager.glass(38, 26))
	hearts_panel.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	var hearts := UI.hbox(8)
	hearts.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hearts_panel.add_child(hearts)
	top.add_child(hearts_panel)
	for i in Model.MAX_MISTAKES:
		var h: Control = Glyph.make("heart", 50, p["wrong"])
		h.filled = true
		h.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		hearts.add_child(h)
		_hearts.append(h)

	# progress
	var prog := UI.hbox(26)
	_progress = UI.bar(0.0, p["accent"], 12)
	_progress.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	prog.add_child(_progress)
	_progress_label = UI.mono("0% filled", 25)
	prog.add_child(_progress_label)
	root.add_child(prog)

	# board in a glass bay
	var bay := PanelContainer.new()
	bay.size_flags_vertical = Control.SIZE_EXPAND_FILL
	var bay_sb := ThemeManager.glass(60, 20, Color(p["accent"], 0.38), Color(p["accent"], 0.10))
	bay_sb.bg_color = ThemeManager.bay_color()
	bay.add_theme_stylebox_override("panel", bay_sb)
	root.add_child(bay)
	if use_3d:
		var cont := SubViewportContainer.new()
		cont.stretch = true
		cont.custom_minimum_size = Vector2(0, 600)
		bay.add_child(cont)
		var vp := SubViewport.new()
		vp.msaa_3d = Viewport.MSAA_2X if Settings.quality_high else Viewport.MSAA_DISABLED
		vp.handle_input_locally = true
		cont.add_child(vp)
		var w := BoardWorld.new()
		w.cube = mode == "cube"
		vp.add_child(w)
		w.cell_tapped.connect(_on_cell_tapped)
		view = w
	else:
		var ratio := AspectRatioContainer.new()
		ratio.ratio = 1.0
		bay.add_child(ratio)
		var b2d := BoardView.new()
		b2d.cell_tapped.connect(_on_cell_tapped)
		ratio.add_child(b2d)
		view = b2d

	var actions := UI.hbox(24)
	root.add_child(actions)
	_undo_btn = _action("Undo", "undo", _on_undo, actions)
	_redo_btn = _action("Redo", "redo", _on_redo, actions)
	_action("Erase", "erase", _on_erase, actions)
	_notes_btn = _action("Notes off", "notes", _on_notes, actions)
	_notes_btn.toggle_mode = true
	var a2: Color = p["accent2"]
	var on_sb := ThemeManager.glass(44, 10, Color(a2, 0.85), Color(a2, 0.18))
	on_sb.bg_color = Color(a2, 0.18)
	_notes_btn.add_theme_stylebox_override("pressed", on_sb)
	_notes_btn.add_theme_stylebox_override("hover_pressed", on_sb)
	_action("Hint", "hint", _on_hint, actions)

	var pad := UI.hbox(14)
	root.add_child(pad)
	for d in range(1, model.digits + 1):
		var b := UI.button("", _on_digit.bind(d), 190, false)
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var col := UI.vbox(2)
		col.alignment = BoxContainer.ALIGNMENT_CENTER
		col.set_anchors_preset(Control.PRESET_FULL_RECT)
		col.mouse_filter = Control.MOUSE_FILTER_IGNORE
		col.add_child(UI.title_label(str(d), 76 if model.digits > 4 else 90, HORIZONTAL_ALIGNMENT_CENTER))
		var badge := UI.mono("", 24, Color(0, 0, 0, 0), HORIZONTAL_ALIGNMENT_CENTER)
		col.add_child(badge)
		b.add_child(col)
		pad.add_child(b)
		_pad_buttons.append(b)
		_pad_badges.append(badge)

	_pause_overlay = _make_overlay()
	_end_overlay = _make_overlay()
	_build_pause_overlay()
	_build_end_overlay()

func _action(text: String, glyph: String, cb: Callable, parent: Control) -> Button:
	var b := UI.icon_button(text, glyph, cb, 150, 52)
	b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	parent.add_child(b)
	return b

## Opaque full-screen overlay with the grid background (also hides the board
## while paused, to prevent peeking).
func _make_overlay() -> Control:
	var o := Control.new()
	o.set_anchors_preset(Control.PRESET_FULL_RECT)
	o.visible = false
	o.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(o)
	return o

func _build_pause_overlay() -> void:
	var p: Dictionary = ThemeManager.palette
	var v := UI.make_screen(_pause_overlay)
	v.alignment = BoxContainer.ALIGNMENT_CENTER
	var card := UI.card(56, Color(p["accent"], 0.4), Color(p["accent"], 0.08))
	v.add_child(card)
	var c := UI.vbox(44)
	card.add_child(c)
	var head := UI.vbox(10)
	head.add_child(UI.mono("Paused", 30, p["accent"], HORIZONTAL_ALIGNMENT_CENTER))
	head.add_child(UI.title_label("Grid on hold", 84, HORIZONTAL_ALIGNMENT_CENTER))
	head.add_child(UI.dim("The board stays hidden until you resume.", 35, HORIZONTAL_ALIGNMENT_CENTER))
	c.add_child(head)
	_pause_stats = UI.hbox(22)
	c.add_child(_pause_stats)
	var sw := UI.vbox(0)
	sw.add_child(UI.switch_row("Sound effects", "sound", Settings.sound, func(on: bool) -> void: Settings.set_value("sound", on), 124))
	sw.add_child(UI.switch_row("Vibration", "vibration", Settings.vibration, func(on: bool) -> void: Settings.set_value("vibration", on), 124))
	c.add_child(sw)
	var btns := UI.vbox(26)
	btns.add_child(UI.primary("Resume", func(): _set_paused(false), 154, "play"))
	var row := UI.hbox(26)
	var r1 := UI.button("Restart", _restart)
	var r2 := UI.button("Main menu", _to_menu)
	for b in [r1, r2]:
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(b)
	btns.add_child(row)
	c.add_child(btns)
	v.add_child(UI.mono("Progress is saved automatically", 25, Color(0, 0, 0, 0), HORIZONTAL_ALIGNMENT_CENTER))

func _fill_pause_stats() -> void:
	for ch in _pause_stats.get_children():
		ch.queue_free()
	var p: Dictionary = ThemeManager.palette
	_pause_stats.add_child(UI.stat_tile(UI.fmt_time(model.elapsed), "Time"))
	_pause_stats.add_child(UI.stat_tile("%d / %d" % [Model.MAX_MISTAKES - model.mistakes, Model.MAX_MISTAKES], "Lives", p["wrong"]))
	_pause_stats.add_child(UI.stat_tile("%d%%" % int(round(_filled_frac() * 100.0)), "Filled"))

func _filled_frac() -> float:
	var n := 0
	for x in model.grid:
		if x != 0:
			n += 1
	return float(n) / float(model.cells)

## The end overlay is filled in by _finish (win and loss layouts differ).
func _build_end_overlay() -> void:
	pass

# --- Game flow -------------------------------------------------------------

func _start_new(difficulty: int) -> void:
	mode = "new"
	_begin(Generator.generate(difficulty))

func _start_cube(difficulty: int) -> void:
	mode = "cube"
	_begin(Cube.generate(difficulty))

func _start_daily() -> void:
	mode = "daily"
	var d := Time.get_date_dict_from_system()
	daily_key = UI.today_key()
	_begin(Daily.puzzle_for_date(d["year"], d["month"], d["day"]))

func _begin(data: Dictionary) -> void:
	model.start(data)
	selected = -1
	_finished = false
	_last_second = -1
	_end_overlay.visible = false
	_title_label.text = _title_text().to_upper()
	_refresh()

func _title_text() -> String:
	if mode == "daily":
		return "Daily · " + daily_key
	if mode == "cube":
		return "Cube · " + Generator.NAMES[model.difficulty]
	return Generator.NAMES[model.difficulty] + " · Classic"

func _stats_key() -> int:
	return model.difficulty + (CUBE_STATS_OFFSET if mode == "cube" else 0)

func _resume() -> bool:
	var d := SaveGame.load_game()
	if d.is_empty():
		return false
	model.from_dict(d["model"])
	mode = d.get("mode", "new")
	daily_key = d.get("daily_key", "")
	_title_label.text = _title_text().to_upper()
	_last_second = -1
	_refresh()
	return true

## Replays the same puzzle from the start.
func _restart() -> void:
	_set_paused(false)
	_begin({"puzzle": model.givens, "solution": model.solution, "difficulty": model.difficulty, "seed": model.seed_value})

func _to_menu() -> void:
	_save()
	Nav.go("res://scenes/main_menu.tscn")

func _save() -> void:
	if model.status == Model.Status.PLAYING:
		SaveGame.save_game({"mode": mode, "daily_key": daily_key, "model": model.to_dict()})
	else:
		SaveGame.clear()

func _set_paused(on: bool) -> void:
	if _finished:
		return
	paused = on
	_pause_overlay.visible = on
	if on:
		_fill_pause_stats()
		_save()

func _apply_settings() -> void:
	if use_3d:
		view.board.highlight_peers = Settings.highlight_peers
		view.board.highlight_same = Settings.highlight_same
	else:
		view.highlight_peers = Settings.highlight_peers
		view.highlight_same = Settings.highlight_same
	view.set_state(model, selected)

func _refresh() -> void:
	view.set_state(model, selected)
	var p: Dictionary = ThemeManager.palette
	for i in _hearts.size():
		var alive: bool = i < Model.MAX_MISTAKES - model.mistakes
		_hearts[i].color = p["wrong"] if alive else Color(p["line"], 0.35)
		_hearts[i].filled = alive
		_hearts[i].queue_redraw()
	var sel_digit: int = model.grid[selected] if selected >= 0 else 0
	for d in range(1, model.digits + 1):
		var left: int = model.remaining(d)
		var b: Button = _pad_buttons[d - 1]
		_pad_badges[d - 1].text = str(left) if left > 0 else "done"
		b.disabled = left == 0
		if d == sel_digit and left > 0:
			var hot := ThemeManager.glass(44, 10, Color(p["accent"], 0.75))
			hot.bg_color = Color(p["accent"], 0.14)
			b.add_theme_stylebox_override("normal", hot)
		else:
			b.remove_theme_stylebox_override("normal")
	_undo_btn.disabled = not model.can_undo()
	_redo_btn.disabled = not model.can_redo()
	_timer_label.text = UI.fmt_time(model.elapsed)
	var f := _filled_frac()
	_progress.frac = f
	_progress_label.text = "%d%% FILLED" % int(round(f * 100.0))
	if model.status != Model.Status.PLAYING and not _finished:
		_finish(model.status == Model.Status.WON)
	else:
		_save()

func _finish(won: bool) -> void:
	_finished = true
	SaveGame.clear()
	var new_best: bool = Stats.data.record(_stats_key(), won, model.elapsed)
	var first_daily := false
	if won and mode == "daily":
		first_daily = Stats.data.record_daily(daily_key, model.elapsed)
	Stats.save()
	var reward: Dictionary = Rewards.data.apply_result(model.difficulty, won, model.mistakes, model.elapsed,
		mode == "cube", first_daily, Stats.data.daily_streak(UI.today_key()))
	Rewards.save()
	if won:
		_build_win(reward, new_best, first_daily)
	else:
		_build_loss(reward)
	AdsHook.on_game_finished()
	var delay := 2.2 if won else 0.7   # let the win celebration play first
	get_tree().create_timer(delay).timeout.connect(func() -> void:
		_end_overlay.visible = true)

func _clear_end() -> VBoxContainer:
	for c in _end_overlay.get_children():
		_end_overlay.remove_child(c)
		c.queue_free()
	var v := UI.make_screen(_end_overlay)
	v.add_theme_constant_override("separation", 40)
	return v

func _level_text() -> String:
	if mode == "daily":
		return "Daily"
	return ("Cube " if mode == "cube" else "") + Generator.NAMES[model.difficulty]

func _build_win(res: Dictionary, new_best: bool, first_daily: bool) -> void:
	var p: Dictionary = ThemeManager.palette
	var v := _clear_end()
	var bg: Control = _end_overlay.get_child(0)
	bg.add_glow(Vector2(0.5, 0.12), 760.0, Color(p["reward"], 0.16))
	# results scroll (several medals can drop at once); buttons stay pinned below
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	v.add_child(scroll)
	var outer := v
	v = UI.vbox(40)
	v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(v)
	var head := UI.vbox(12)
	head.add_child(UI.mono("Grid solved · " + _level_text(), 30, Color("4BE3A0") if not ThemeManager.is_light() else Color("0E8A55"), HORIZONTAL_ALIGNMENT_CENTER))
	head.add_child(UI.title_label("Clean solve" if model.mistakes == 0 else "Solved", 96, HORIZONTAL_ALIGNMENT_CENTER))
	var sub := "%s · %d %s" % [UI.fmt_time(model.elapsed), model.mistakes, "mistake" if model.mistakes == 1 else "mistakes"]
	if mode != "cube":
		sub += " · par %d min" % int(RewardsData.PAR_TIMES[clampi(model.difficulty, 0, 3)] / 60.0)
	head.add_child(UI.mono(sub, 27, Color(0, 0, 0, 0), HORIZONTAL_ALIGNMENT_CENTER))
	if new_best:
		head.add_child(UI.mono("New best time", 27, p["accent"], HORIZONTAL_ALIGNMENT_CENTER))
	if first_daily:
		head.add_child(UI.mono("Daily streak · %d days" % Stats.data.daily_streak(daily_key), 27, p["reward"], HORIZONTAL_ALIGNMENT_CENTER))
	v.add_child(head)
	var xp := UI.vbox(0)
	xp.add_child(UI.title_label("+%d" % res["xp"], 150, HORIZONTAL_ALIGNMENT_CENTER, p["reward"]))
	xp.add_child(UI.mono("XP earned", 30, p["reward"], HORIZONTAL_ALIGNMENT_CENTER))
	v.add_child(xp)
	v.add_child(_xp_card(res))
	for m in res["new_medals"]:
		v.add_child(_medal_card(m))
	for key in res["new_themes"]:
		var t := UI.card(36, Color(p["accent"], 0.5))
		t.add_child(UI.title_label("Unlocked: %s theme" % ThemeManager.PALETTES[key]["label"], 44, HORIZONTAL_ALIGNMENT_CENTER, p["accent"]))
		v.add_child(t)
	v = outer
	v.add_child(UI.primary("Next puzzle", func(): Nav.go("res://scenes/difficulty.tscn", {"cube": mode == "cube"})))
	var row := UI.hbox(26)
	var r1 := UI.button("View rewards", func(): Nav.go("res://scenes/rewards.tscn"))
	var r2 := UI.button("Main menu", _to_menu)
	for b in [r1, r2]:
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(b)
	v.add_child(row)

## XP breakdown rows plus the rank bar (earlier XP in cyan, this game's XP in amber).
func _xp_card(res: Dictionary) -> Control:
	var p: Dictionary = ThemeManager.palette
	var card := UI.card(44)
	var v := UI.vbox(0)
	card.add_child(v)
	for part in res["parts"]:
		var r := UI.hbox(10)
		r.custom_minimum_size.y = 88
		var l := UI.label(part[0], 38)
		l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		l.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		r.add_child(l)
		var amt := UI.title_label("+%d" % part[1], 42)
		amt.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		r.add_child(amt)
		v.add_child(r)
		var d := ColorRect.new()
		d.color = Color(p["line"], 0.14)
		d.custom_minimum_size = Vector2(0, 2)
		v.add_child(d)
	var pr: Dictionary = Rewards.data.progress()
	var gap := UI.vbox(16)
	gap.add_child(Control.new())
	var rr := UI.hbox(10)
	var rt := UI.title_label("Rank %d · %s" % [pr["rank"], RewardsData.title_for_rank(pr["rank"])], 42)
	rt.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	rr.add_child(rt)
	var xl := UI.mono("%d / %d XP" % [pr["into"], pr["need"]], 25)
	xl.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	rr.add_child(xl)
	gap.add_child(rr)
	var now := float(pr["into"]) / float(pr["need"])
	var before := now - float(res["xp"]) / float(pr["need"])
	var ranked_up: bool = res["rank_after"] > res["rank_before"]
	gap.add_child(UI.bar(now, p["reward"], 22, -1.0 if ranked_up else maxf(0.0, before), p["accent"]))
	if ranked_up:
		gap.add_child(UI.mono("Rank up · now Rank %d" % res["rank_after"], 26, p["accent"]))
	else:
		gap.add_child(UI.dim("%d XP to Rank %d · %s" % [int(pr["need"]) - int(pr["into"]), int(pr["rank"]) + 1, RewardsData.title_for_rank(int(pr["rank"]) + 1)], 33))
	v.add_child(gap)
	return card

func _medal_card(m: Dictionary) -> Control:
	var info: Dictionary = {}
	for d in RewardsData.MEDALS:
		if d["id"] == m["id"]:
			info = d
	var tier: int = m["tier"]
	var metal: Color = Glyph.METALS[clampi(tier, 1, 3)]["in_top"]
	var card := UI.card(40, Color(metal, 0.5))
	var row := UI.hbox(40)
	card.add_child(row)
	var icon: Control = Glyph.make_medal(MEDAL_GLYPHS[m["id"]], tier, 170)
	row.add_child(icon)
	var col := UI.vbox(8)
	col.alignment = BoxContainer.ALIGNMENT_CENTER
	col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	col.add_child(UI.mono("New medal", 26, metal))
	col.add_child(UI.title_label("%s %s" % [RewardsData.TIER_NAMES[tier], info["name"]], 52))
	var count: int = int(Rewards.data.counters[info["counter"]])
	var next := "Top tier reached" if tier >= 3 else "%s at %d" % [RewardsData.TIER_NAMES[tier + 1], int(info["tiers"][tier])]
	col.add_child(UI.dim("%s · %d so far · %s" % [info["desc"], count, next], 31))
	row.add_child(col)
	return card

func _build_loss(res: Dictionary) -> void:
	var p: Dictionary = ThemeManager.palette
	var v := _clear_end()
	var bg: Control = _end_overlay.get_child(0)
	bg.add_glow(Vector2(0.5, 0.2), 640.0, Color(p["wrong"], 0.14))
	v.add_child(UI.spacer())
	var hearts := UI.hbox(36)
	hearts.alignment = BoxContainer.ALIGNMENT_CENTER
	for i in 3:
		var h: Control = Glyph.make("heart", 120, Color(p["wrong"], 0.55))
		hearts.add_child(h)
	v.add_child(hearts)
	var head := UI.vbox(16)
	head.add_child(UI.mono("Signal lost · " + _level_text(), 30, p["wrong"], HORIZONTAL_ALIGNMENT_CENTER))
	head.add_child(UI.title_label("Out of lives", 100, HORIZONTAL_ALIGNMENT_CENTER))
	head.add_child(UI.dim("Three wrong digits end the run. Your grid is still here if you want another go.", 38, HORIZONTAL_ALIGNMENT_CENTER))
	v.add_child(head)
	var tiles := UI.hbox(22)
	tiles.add_child(UI.stat_tile("%d%%" % int(round(_filled_frac() * 100.0)), "Filled"))
	tiles.add_child(UI.stat_tile(UI.fmt_time(model.elapsed), "Time"))
	tiles.add_child(UI.stat_tile("+%d" % res["xp"], "Good try XP", p["reward"]))
	v.add_child(tiles)
	var tip := UI.card(40, Color(p["accent2"], 0.3))
	var tsb: StyleBoxFlat = tip.get_theme_stylebox("panel")
	tsb.bg_color = Color(p["accent2"], 0.08)
	var tr := UI.hbox(32)
	var ic: Control = Glyph.make("notes", 56, p["accent2"])
	ic.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	tr.add_child(ic)
	var tl := UI.dim("Tip: switch on Notes and pencil in candidates before you commit a digit. Notes never cost a life.", 35)
	tl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	tr.add_child(tl)
	tip.add_child(tr)
	v.add_child(tip)
	v.add_child(UI.spacer())
	v.add_child(UI.primary("Try this grid again", _restart, 154, "undo"))
	var row := UI.hbox(26)
	var r1 := UI.button("New game", func(): Nav.go("res://scenes/difficulty.tscn", {"cube": mode == "cube"}))
	var r2 := UI.button("Main menu", _to_menu)
	for b in [r1, r2]:
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(b)
	v.add_child(row)

# --- Input -----------------------------------------------------------------

func _on_cell_tapped(idx: int) -> void:
	Audio.play("select")
	selected = idx
	_refresh()

func _on_digit(d: int) -> void:
	if selected < 0 or paused:
		return
	if notes_mode:
		model.toggle_note(selected, d)
		_refresh()
	else:
		var r: int = model.place(selected, d)
		_refresh()
		_celebrate(r, selected)

## Plays tile + completion animations after a placement (no-ops in 2D).
func _celebrate(result: int, idx: int) -> void:
	view.play_result(result, idx)
	if result == Model.Result.PLACED_WRONG:
		Audio.play("wrong")
		if Settings.vibration:
			Input.vibrate_handheld(80)
	elif result == Model.Result.PLACED_OK:
		Audio.play("place")
		var units: Array = model.completed_units_at(idx)
		for unit in units:
			view.play_wave(unit, idx)
		if not units.is_empty() and model.status == Model.Status.PLAYING:
			Audio.play("complete")
	if model.status == Model.Status.WON:
		Audio.play("win")
		view.play_win()
	elif model.status == Model.Status.LOST:
		Audio.play("lose")

func _on_erase() -> void:
	if selected >= 0:
		if model.erase(selected) == Model.Result.ERASED:
			Audio.play("erase")
		_refresh()

func _on_undo() -> void:
	model.undo()
	_refresh()

func _on_redo() -> void:
	model.redo()
	_refresh()

func _on_notes() -> void:
	notes_mode = _notes_btn.button_pressed
	var box: Node = _notes_btn.get_child(0)
	var l: Label = box.get_child(1)
	l.text = "NOTES ON" if notes_mode else "NOTES OFF"
	l.add_theme_color_override("font_color", ThemeManager.palette["accent2"] if notes_mode else ThemeManager.palette["text"])

func _on_hint() -> void:
	var idx: int = model.hint(selected)
	if idx >= 0:
		selected = idx
	_refresh()
	if idx >= 0:
		Audio.play("hint")
		view.play_result(Model.Result.PLACED_OK, idx)
		for unit in model.completed_units_at(idx):
			view.play_wave(unit, idx)
		if model.status == Model.Status.WON:
			Audio.play("win")
			view.play_win()

## Android back button / Escape.
func on_back() -> void:
	if _end_overlay.visible:
		_to_menu()
	elif paused:
		_set_paused(false)
	else:
		_set_paused(true)

## Pause + save whenever the app loses focus or goes to the background.
func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_PAUSED or what == NOTIFICATION_APPLICATION_FOCUS_OUT:
		if is_node_ready() and not _finished and not ("--demo" in OS.get_cmdline_user_args()):
			_set_paused(true)

## Desktop convenience: number keys, backspace, arrows, N for notes, Z undo, H hint.
func _unhandled_key_input(event: InputEvent) -> void:
	if not (event is InputEventKey and event.pressed) or paused:
		return
	var k: int = event.keycode
	if k >= KEY_1 and k <= KEY_9:
		_on_digit(k - KEY_0)
	elif k == KEY_BACKSPACE or k == KEY_DELETE:
		_on_erase()
	elif k == KEY_N:
		_notes_btn.button_pressed = not _notes_btn.button_pressed
		_on_notes()
	elif k == KEY_Z:
		_on_undo()
	elif k == KEY_H:
		_on_hint()
	elif k >= KEY_LEFT and k <= KEY_DOWN and selected >= 0:
		var s: int = selected
		match k:
			KEY_LEFT: s = s - 1 if s % 9 > 0 else s
			KEY_RIGHT: s = s + 1 if s % 9 < 8 else s
			KEY_UP: s = s - 9 if s >= 9 else s
			KEY_DOWN: s = s + 9 if s < 72 else s
		_on_cell_tapped(s)

## Screenshot helper: `godot --path . --write-movie out.png -- --demo` (+ `--win`).
func _demo() -> void:
	await get_tree().create_timer(0.3).timeout
	if "--pause" in OS.get_cmdline_user_args():
		_set_paused(true)
		return
	if "--lose" in OS.get_cmdline_user_args():
		for i in model.cells:
			if model.grid[i] == 0 and model.status == Model.Status.PLAYING:
				model.place(i, (model.solution[i] % model.digits) + 1)
		_refresh()
		return
	if "--win" in OS.get_cmdline_user_args():
		for i in model.cells:
			if model.grid[i] == 0:
				model.place(i, model.solution[i])
		_refresh()
		_celebrate(Model.Result.PLACED_OK, 40)
		return
	for n in 4:
		_on_hint()
	selected = -1
	for i in 81:
		if model.grid[i] == 0:
			selected = i
			break
	model.toggle_note(selected, 3)
	model.toggle_note(selected, 7)
	var j := selected + 1
	while model.grid[j] != 0:
		j += 1
	model.place(j, (model.solution[j] % 9) + 1)
	_refresh()
	view.play_result(Model.Result.PLACED_WRONG, j)
	if use_3d:
		view.rig.yaw = 12.0
		if "--top" in OS.get_cmdline_user_args():
			view.rig.pitch = 80.0
		view.rig._apply()
