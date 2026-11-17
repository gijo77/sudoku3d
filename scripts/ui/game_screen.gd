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

var use_3d := true
var model := Model.new()
var view                      # board_view_2d or world_3d (same API)
var selected := -1
var notes_mode := false
var mode := "new"             # "new" | "daily"
var daily_key := ""
var paused := false
var _finished := false
var _title_label: Label
var _mistakes_label: Label
var _timer_label: Label
var _pad_buttons: Array[Button] = []
var _pad_badges: Array[Label] = []
var _undo_btn: Button
var _redo_btn: Button
var _notes_btn: Button
var _pause_overlay: Control
var _end_overlay: Control
var _end_title: Label
var _end_text: Label
var _retry_btn: Button
var _last_second := -1

func _ready() -> void:
	_build_ui()
	var p: Dictionary = Nav.params
	match p.get("mode", "new"):
		"resume":
			if not _resume():
				_start_new(Generator.Difficulty.MEDIUM)
		"daily":
			_start_daily()
		_:
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
	var margin := MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(margin)
	UI.apply_safe_area(margin, 36)
	var root := VBoxContainer.new()
	root.add_theme_constant_override("separation", 24)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	margin.add_child(root)

	var top := HBoxContainer.new()
	top.add_theme_constant_override("separation", 20)
	root.add_child(top)
	var pause_btn := UI.button("II", func(): _set_paused(true), 100)
	pause_btn.custom_minimum_size.x = 130
	top.add_child(pause_btn)
	_title_label = UI.label("", 44, HORIZONTAL_ALIGNMENT_CENTER)
	_title_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_title_label.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	top.add_child(_title_label)
	_timer_label = UI.label("0:00", 48, HORIZONTAL_ALIGNMENT_RIGHT)
	_timer_label.custom_minimum_size.x = 150
	_timer_label.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	top.add_child(_timer_label)

	_mistakes_label = UI.label("", 40, HORIZONTAL_ALIGNMENT_CENTER)
	root.add_child(_mistakes_label)

	if use_3d:
		var cont := SubViewportContainer.new()
		cont.stretch = true
		cont.size_flags_vertical = Control.SIZE_EXPAND_FILL
		cont.custom_minimum_size = Vector2(0, 600)
		root.add_child(cont)
		var vp := SubViewport.new()
		vp.msaa_3d = Viewport.MSAA_2X
		vp.handle_input_locally = true
		cont.add_child(vp)
		var w := BoardWorld.new()
		vp.add_child(w)
		w.cell_tapped.connect(_on_cell_tapped)
		view = w
	else:
		var ratio := AspectRatioContainer.new()
		ratio.ratio = 1.0
		ratio.size_flags_vertical = Control.SIZE_EXPAND_FILL
		root.add_child(ratio)
		var b2d := BoardView.new()
		b2d.cell_tapped.connect(_on_cell_tapped)
		ratio.add_child(b2d)
		view = b2d

	var actions := HBoxContainer.new()
	actions.add_theme_constant_override("separation", 14)
	root.add_child(actions)
	_undo_btn = _action("Undo", _on_undo, actions)
	_redo_btn = _action("Redo", _on_redo, actions)
	_action("Erase", _on_erase, actions)
	_notes_btn = _action("Notes", _on_notes, actions)
	_notes_btn.toggle_mode = true
	_action("Hint", _on_hint, actions)

	var pad := HBoxContainer.new()
	pad.add_theme_constant_override("separation", 8)
	root.add_child(pad)
	for d in range(1, 10):
		var b := UI.button(str(d), _on_digit.bind(d), 170)
		b.add_theme_font_size_override("font_size", 64)
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var badge := Label.new()
		badge.add_theme_font_size_override("font_size", 28)
		badge.add_theme_color_override("font_color", Color(1, 1, 1, 0.85))
		badge.set_anchors_preset(Control.PRESET_TOP_RIGHT)
		badge.position = Vector2(-4, 4)
		badge.grow_horizontal = Control.GROW_DIRECTION_BEGIN
		b.add_child(badge)
		pad.add_child(b)
		_pad_buttons.append(b)
		_pad_badges.append(badge)

	_pause_overlay = _make_overlay()
	_end_overlay = _make_overlay()
	_build_pause_overlay()
	_build_end_overlay()

func _action(text: String, cb: Callable, parent: Control) -> Button:
	var b := UI.button(text, cb, 100)
	b.add_theme_font_size_override("font_size", 34)
	b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	parent.add_child(b)
	return b

## Opaque full-screen overlay (also hides the board while paused, to prevent peeking).
func _make_overlay() -> Control:
	var o := ColorRect.new()
	o.set_anchors_preset(Control.PRESET_FULL_RECT)
	o.color = ThemeManager.palette["bg"]
	o.visible = false
	add_child(o)
	return o

func _overlay_box(overlay: Control, title: String) -> VBoxContainer:
	var v := UI.make_screen(overlay)
	v.alignment = BoxContainer.ALIGNMENT_CENTER
	var t := UI.heading(title, 100)
	t.name = "Title"
	v.add_child(t)
	return v

func _build_pause_overlay() -> void:
	var v := _overlay_box(_pause_overlay, "Paused")
	v.add_child(UI.button("Resume", func(): _set_paused(false)))
	v.add_child(UI.button("Restart", _restart))
	v.add_child(UI.button("Main menu", _to_menu))

func _build_end_overlay() -> void:
	var v := _overlay_box(_end_overlay, "")
	_end_title = v.get_node("Title")
	_end_text = UI.label("", 44, HORIZONTAL_ALIGNMENT_CENTER)
	_end_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	v.add_child(_end_text)
	v.add_child(UI.button("New game", func(): Nav.go("res://scenes/difficulty.tscn")))
	_retry_btn = UI.button("Try this puzzle again", _restart)
	v.add_child(_retry_btn)
	v.add_child(UI.button("Main menu", _to_menu))

# --- Game flow -------------------------------------------------------------

func _start_new(difficulty: int) -> void:
	mode = "new"
	_begin(Generator.generate(difficulty))

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
	_title_label.text = ("Daily  " + daily_key) if mode == "daily" else Generator.NAMES[model.difficulty]
	_refresh()

func _resume() -> bool:
	var d := SaveGame.load_game()
	if d.is_empty():
		return false
	model.from_dict(d["model"])
	mode = d.get("mode", "new")
	daily_key = d.get("daily_key", "")
	_title_label.text = ("Daily  " + daily_key) if mode == "daily" else Generator.NAMES[model.difficulty]
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
	_mistakes_label.text = "Mistakes: %d / %d" % [model.mistakes, Model.MAX_MISTAKES]
	for d in range(1, 10):
		var left: int = model.remaining(d)
		_pad_badges[d - 1].text = str(left) if left > 0 else ""
		_pad_buttons[d - 1].disabled = left == 0
	_undo_btn.disabled = not model.can_undo()
	_redo_btn.disabled = not model.can_redo()
	_timer_label.text = UI.fmt_time(model.elapsed)
	if model.status != Model.Status.PLAYING and not _finished:
		_finish(model.status == Model.Status.WON)
	else:
		_save()

func _finish(won: bool) -> void:
	_finished = true
	SaveGame.clear()
	var new_best: bool = Stats.data.record(model.difficulty, won, model.elapsed)
	var first_daily := false
	if won and mode == "daily":
		first_daily = Stats.data.record_daily(daily_key, model.elapsed)
	Stats.save()
	AdsHook.on_game_finished()
	if won:
		var txt := "Solved in %s with %d mistake(s)." % [UI.fmt_time(model.elapsed), model.mistakes]
		if new_best:
			txt += "\nNew best time!"
		if first_daily:
			txt += "\nDaily streak: %d day(s)" % Stats.data.daily_streak(daily_key)
		_end_title.text = "You win!"
		_end_text.text = txt
		_retry_btn.visible = false
	else:
		_end_title.text = "Game over"
		_end_text.text = "Too many mistakes."
		_retry_btn.visible = true
	var delay := 2.2 if won else 0.7   # let the win celebration play first
	get_tree().create_timer(delay).timeout.connect(func() -> void:
		_end_overlay.visible = true)

# --- Input -----------------------------------------------------------------

func _on_cell_tapped(idx: int) -> void:
	selected = idx
	_refresh()

func _on_digit(d: int) -> void:
	if selected < 0 or paused:
		return
	if notes_mode:
		model.toggle_note(selected, d)
		_refresh()
	else:
		var r := model.place(selected, d)
		_refresh()
		_celebrate(r, selected)

## Plays tile + completion animations after a placement (no-ops in 2D).
func _celebrate(result: int, idx: int) -> void:
	view.play_result(result, idx)
	if result == Model.Result.PLACED_WRONG and Settings.vibration:
		Input.vibrate_handheld(80)
	if result == Model.Result.PLACED_OK:
		for unit in model.completed_units_at(idx):
			view.play_wave(unit, idx)
	if model.status == Model.Status.WON:
		view.play_win()

func _on_erase() -> void:
	if selected >= 0:
		model.erase(selected)
		_refresh()

func _on_undo() -> void:
	model.undo()
	_refresh()

func _on_redo() -> void:
	model.redo()
	_refresh()

func _on_notes() -> void:
	notes_mode = _notes_btn.button_pressed

func _on_hint() -> void:
	var idx := model.hint(selected)
	if idx >= 0:
		selected = idx
	_refresh()
	if idx >= 0:
		_celebrate(Model.Result.PLACED_OK, idx)

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
	if "--win" in OS.get_cmdline_user_args():
		for i in 81:
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
		view.rig._apply()
