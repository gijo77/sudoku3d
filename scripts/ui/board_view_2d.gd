extends Control
## 2D board renderer + input (prototype view; the 3D board replaces it in M3).
## Draws cells, highlights, digits and pencil notes with _draw().

signal cell_tapped(idx: int)

const Solver := preload("res://scripts/logic/solver.gd")

var model                      # game_model.gd instance
var selected := -1
var highlight_peers := true    # row / column / box
var highlight_same := true     # same digit everywhere

const C_BG := Color(1, 1, 1)
const C_PEER := Color(0.88, 0.92, 0.98)
const C_SAME := Color(0.74, 0.84, 0.97)
const C_SELECTED := Color(0.55, 0.72, 0.96)
const C_GIVEN := Color(0.10, 0.12, 0.18)
const C_PLAYER := Color(0.12, 0.38, 0.85)
const C_WRONG := Color(0.85, 0.15, 0.15)
const C_NOTE := Color(0.40, 0.44, 0.52)
const C_THIN := Color(0.72, 0.75, 0.80)
const C_THICK := Color(0.12, 0.14, 0.20)

## View API shared with the 3D board.
func set_state(m, sel: int) -> void:
	model = m
	selected = sel
	queue_redraw()

func play_result(_result: int, _idx: int) -> void:
	pass

func play_wave(_cells: Array, _origin: int) -> void:
	pass

func play_win() -> void:
	pass

func _side() -> float:
	return minf(size.x, size.y)

func _draw() -> void:
	if model == null:
		return
	var side := _side()
	var s := side / 9.0
	var font := ThemeDB.fallback_font
	draw_rect(Rect2(0, 0, side, side), C_BG)
	var sel_digit: int = model.grid[selected] if selected >= 0 else 0
	for i in Solver.CELLS:
		var x := Solver.col_of(i) * s
		var y := Solver.row_of(i) * s
		var rect := Rect2(x, y, s, s)
		var bg := C_BG
		if selected >= 0:
			if i == selected:
				bg = C_SELECTED
			elif highlight_same and sel_digit != 0 and model.grid[i] == sel_digit:
				bg = C_SAME
			elif highlight_peers and (Solver.row_of(i) == Solver.row_of(selected) \
					or Solver.col_of(i) == Solver.col_of(selected) \
					or Solver.box_of(i) == Solver.box_of(selected)):
				bg = C_PEER
		if bg != C_BG:
			draw_rect(rect, bg)
		var v: int = model.grid[i]
		if v != 0:
			var col := C_GIVEN if model.is_given(i) else (C_WRONG if model.is_wrong(i) else C_PLAYER)
			var fs := int(s * 0.62)
			draw_string(font, Vector2(x, y + s * 0.5 + fs * 0.36), str(v),
				HORIZONTAL_ALIGNMENT_CENTER, s, fs, col)
		elif model.notes[i] != 0:
			var ns := int(s * 0.24)
			for d in range(1, 10):
				if model.notes[i] & (1 << (d - 1)):
					var nx := x + ((d - 1) % 3) * s / 3.0
					var ny := y + ((d - 1) / 3) * s / 3.0
					draw_string(font, Vector2(nx, ny + s / 3.0 * 0.5 + ns * 0.36), str(d),
						HORIZONTAL_ALIGNMENT_CENTER, s / 3.0, ns, C_NOTE)
	for k in 10:
		var thick := k % 3 == 0
		var p := k * s
		var w := 4.0 if thick else 1.5
		var c := C_THICK if thick else C_THIN
		draw_line(Vector2(p, 0), Vector2(p, side), c, w)
		draw_line(Vector2(0, p), Vector2(side, p), c, w)

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		var s := _side() / 9.0
		var col := int(event.position.x / s)
		var row := int(event.position.y / s)
		if col >= 0 and col < 9 and row >= 0 and row < 9:
			cell_tapped.emit(row * 9 + col)
