extends Control
## Game screen: board view (3D or 2D), number pad with remaining badges, notes,
## undo/redo, erase, hint, mistakes (max 3), timer. UI is built in code.
## `use_3d` selects the 3D board (default) or the 2D fallback.

const Model := preload("res://scripts/game/game_model.gd")
const Generator := preload("res://scripts/logic/generator.gd")
const BoardView := preload("res://scripts/ui/board_view_2d.gd")
const BoardWorld := preload("res://scripts/board3d/world_3d.gd")

var use_3d := true
var model := Model.new()
var view                      # board_view_2d or world_3d (same API)
var selected := -1
var _end_shown := false
var notes_mode := false
var _mistakes_label: Label
var _timer_label: Label
var _diff_option: OptionButton
var _pad_buttons: Array[Button] = []
var _pad_badges: Array[Label] = []
var _undo_btn: Button
var _redo_btn: Button
var _notes_btn: Button
var _end_dialog: AcceptDialog
var _last_second := -1

func _ready() -> void:
	RenderingServer.set_default_clear_color(Color(0.94, 0.95, 0.98))
	var th := Theme.new()
	th.set_color("font_color", "Label", Color(0.12, 0.14, 0.20))
	theme = th
	_build_ui()
	_new_game(Generator.Difficulty.MEDIUM)
	if "--demo" in OS.get_cmdline_user_args():
		_demo()

func _process(delta: float) -> void:
	model.tick(delta)
	var sec := int(model.elapsed)
	if sec != _last_second:
		_last_second = sec
		_timer_label.text = "%02d:%02d" % [sec / 60, sec % 60]

# --- UI construction -------------------------------------------------------

func _build_ui() -> void:
	var margin := MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	for side in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 40)
	add_child(margin)
	var root := VBoxContainer.new()
	root.add_theme_constant_override("separation", 28)
	margin.add_child(root)

	var top := HBoxContainer.new()
	top.add_theme_constant_override("separation", 20)
	root.add_child(top)
	_diff_option = OptionButton.new()
	for d in Generator.NAMES:
		_diff_option.add_item(Generator.NAMES[d], d)
	_diff_option.select(Generator.Difficulty.MEDIUM)
	_diff_option.add_theme_font_size_override("font_size", 40)
	_diff_option.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top.add_child(_diff_option)
	var new_btn := _button("New game", 40)
	new_btn.pressed.connect(func(): _new_game(_diff_option.get_selected_id()))
	top.add_child(new_btn)

	var info := HBoxContainer.new()
	root.add_child(info)
	_mistakes_label = Label.new()
	_mistakes_label.add_theme_font_size_override("font_size", 44)
	_mistakes_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	info.add_child(_mistakes_label)
	_timer_label = Label.new()
	_timer_label.add_theme_font_size_override("font_size", 44)
	info.add_child(_timer_label)

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
		var b := _button(str(d), 64)
		b.custom_minimum_size = Vector2(0, 190)
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		b.pressed.connect(_on_digit.bind(d))
		var badge := Label.new()
		badge.add_theme_font_size_override("font_size", 28)
		badge.add_theme_color_override("font_color", Color(0.85, 0.88, 1.0))
		badge.set_anchors_preset(Control.PRESET_TOP_RIGHT)
		badge.position = Vector2(-4, 4)
		badge.grow_horizontal = Control.GROW_DIRECTION_BEGIN
		b.add_child(badge)
		pad.add_child(b)
		_pad_buttons.append(b)
		_pad_badges.append(badge)

	_end_dialog = AcceptDialog.new()
	_end_dialog.ok_button_text = "New game"
	_end_dialog.confirmed.connect(func(): _new_game(_diff_option.get_selected_id()))
	add_child(_end_dialog)

func _button(text: String, font_size: int) -> Button:
	var b := Button.new()
	b.text = text
	b.add_theme_font_size_override("font_size", font_size)
	return b

func _action(text: String, cb: Callable, parent: Control) -> Button:
	var b := _button(text, 36)
	b.custom_minimum_size = Vector2(0, 110)
	b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	b.pressed.connect(cb)
	parent.add_child(b)
	return b

# --- Game flow -------------------------------------------------------------

func _new_game(difficulty: int) -> void:
	model.start(Generator.generate(difficulty))
	selected = -1
	_end_shown = false
	_last_second = -1
	_refresh()

func _refresh() -> void:
	view.set_state(model, selected)
	_mistakes_label.text = "Mistakes: %d / %d" % [model.mistakes, Model.MAX_MISTAKES]
	for d in range(1, 10):
		var left: int = model.remaining(d)
		_pad_badges[d - 1].text = str(left) if left > 0 else ""
		_pad_buttons[d - 1].disabled = left == 0
	_undo_btn.disabled = not model.can_undo()
	_redo_btn.disabled = not model.can_redo()
	if model.status != Model.Status.PLAYING and not _end_shown:
		_end_shown = true
		var won := model.status == Model.Status.WON
		var delay := 2.2 if won else 0.6   # let the win celebration play first
		get_tree().create_timer(delay).timeout.connect(func() -> void:
			if won:
				_show_end("You win!", "Solved in %s with %d mistakes." % [_timer_label.text, model.mistakes])
			else:
				_show_end("Game over", "Too many mistakes."))

func _show_end(title: String, text: String) -> void:
	_end_dialog.title = title
	_end_dialog.dialog_text = text
	_end_dialog.popup_centered(Vector2i(700, 300))

func _on_cell_tapped(idx: int) -> void:
	selected = idx
	_refresh()

func _on_digit(d: int) -> void:
	if selected < 0:
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

## Desktop convenience: number keys, backspace, arrows, N for notes, Z undo.
func _unhandled_key_input(event: InputEvent) -> void:
	if not (event is InputEventKey and event.pressed):
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

## Screenshot helper: `godot --path . --write-movie out.png -- --demo`.
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
