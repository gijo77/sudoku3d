extends "res://tests/test_case.gd"

const Model := preload("res://scripts/game/game_model.gd")
const Solver := preload("res://scripts/logic/solver.gd")
const Generator := preload("res://scripts/logic/generator.gd")

func _new() -> Object:
	var m = Model.new()
	m.start(Generator.generate(Generator.Difficulty.EASY, 42))
	return m

func _first_empty(m) -> int:
	for i in 81:
		if m.grid[i] == 0:
			return i
	return -1

func _wrong_digit(m, idx: int) -> int:
	return (m.solution[idx] % 9) + 1

func test_givens_are_locked() -> void:
	var m = _new()
	var gi := -1
	for i in 81:
		if m.is_given(i):
			gi = i
			break
	assert_eq(m.place(gi, _wrong_digit(m, gi)), Model.Result.IGNORED, "cannot overwrite a given")
	assert_eq(m.erase(gi), Model.Result.IGNORED, "cannot erase a given")

func test_correct_placement() -> void:
	var m = _new()
	var i := _first_empty(m)
	assert_eq(m.place(i, m.solution[i]), Model.Result.PLACED_OK, "ok")
	assert_eq(m.grid[i], m.solution[i], "digit set")
	assert_eq(m.mistakes, 0, "no mistake")
	assert_eq(m.place(i, _wrong_digit(m, i)), Model.Result.IGNORED, "correct cell locked")

func test_mistakes_and_lose() -> void:
	var m = _new()
	var placed := 0
	for i in 81:
		if m.grid[i] == 0 and placed < 3:
			assert_eq(m.place(i, _wrong_digit(m, i)), Model.Result.PLACED_WRONG, "wrong")
			assert_true(m.is_wrong(i), "flagged wrong")
			placed += 1
	assert_eq(m.mistakes, 3, "three mistakes")
	assert_eq(m.status, Model.Status.LOST, "lost")
	var j := _first_empty(m)
	assert_eq(m.place(j, m.solution[j] if j >= 0 else 1), Model.Result.IGNORED, "no input after loss")

func test_wrong_digit_can_be_erased_and_replaced() -> void:
	var m = _new()
	var i := _first_empty(m)
	m.place(i, _wrong_digit(m, i))
	assert_eq(m.erase(i), Model.Result.ERASED, "erase wrong")
	assert_eq(m.grid[i], 0, "empty")
	m.place(i, _wrong_digit(m, i))
	assert_eq(m.place(i, m.solution[i]), Model.Result.PLACED_OK, "overwrite wrong with right")

func test_notes_toggle_and_cleared_in_peers() -> void:
	var m = _new()
	var i := _first_empty(m)
	var d: int = m.solution[i]
	assert_eq(m.toggle_note(i, d), Model.Result.NOTE_TOGGLED, "note on")
	assert_eq(m.notes[i], 1 << (d - 1), "bit set")
	m.toggle_note(i, d)
	assert_eq(m.notes[i], 0, "note off")
	# Put the note on a peer, then place the digit: peer note must vanish.
	var peer := -1
	for k in 81:
		if k != i and m.grid[k] == 0 and Solver.row_of(k) == Solver.row_of(i):
			peer = k
			break
	if peer >= 0:
		m.toggle_note(peer, d)
		m.place(i, d)
		assert_eq(m.notes[peer] & (1 << (d - 1)), 0, "peer note cleared")
	assert_eq(m.toggle_note(i, d), Model.Result.IGNORED, "no notes on filled cell")

func test_undo_redo() -> void:
	var m = _new()
	var i := _first_empty(m)
	m.place(i, m.solution[i])
	assert_true(m.undo(), "undo")
	assert_eq(m.grid[i], 0, "reverted")
	assert_true(m.redo(), "redo")
	assert_eq(m.grid[i], m.solution[i], "reapplied")
	assert_true(not m.redo(), "nothing more to redo")
	m.undo()
	m.toggle_note(i, 3)
	assert_true(not m.can_redo(), "new action clears redo")

func test_undo_does_not_refund_mistakes() -> void:
	var m = _new()
	var i := _first_empty(m)
	m.place(i, _wrong_digit(m, i))
	m.undo()
	assert_eq(m.mistakes, 1, "mistake stays")

func test_remaining_counts() -> void:
	var m = _new()
	var total := 0
	for d in range(1, 10):
		total += m.remaining(d)
	assert_eq(total, m.givens.count(0), "remaining == empty cells")
	var i := _first_empty(m)
	var d: int = m.solution[i]
	var before: int = m.remaining(d)
	m.place(i, _wrong_digit(m, i))
	assert_eq(m.remaining(d), before, "wrong digit does not reduce remaining")
	m.place(i, d)
	assert_eq(m.remaining(d), before - 1, "correct digit reduces remaining")

func test_hint_reveals_correct_digit() -> void:
	var m = _new()
	var idx: int = m.hint()
	assert_true(idx >= 0, "hint found")
	assert_eq(m.grid[idx], m.solution[idx], "correct")
	assert_eq(m.hints_used, 1, "counted")
	assert_eq(m.mistakes, 0, "no mistake from hint")
	var i := _first_empty(m)
	assert_eq(m.hint(i), i, "hint on selected cell")

func test_win() -> void:
	var m = _new()
	for i in 81:
		if m.grid[i] == 0:
			m.place(i, m.solution[i])
	assert_eq(m.status, Model.Status.WON, "won")
	assert_eq(m.mistakes, 0, "flawless")

func test_timer_stops_when_finished() -> void:
	var m = _new()
	m.tick(1.5)
	assert_eq(m.elapsed, 1.5, "ticks")
	for i in 81:
		if m.grid[i] == 0:
			m.place(i, m.solution[i])
	m.tick(5.0)
	assert_eq(m.elapsed, 1.5, "stopped after win")

func test_serialize_roundtrip() -> void:
	var m = _new()
	var i := _first_empty(m)
	m.place(i, m.solution[i])
	m.toggle_note(_first_empty(m), 4)
	m.tick(12.0)
	var m2 = Model.new()
	m2.from_dict(JSON.parse_string(JSON.stringify(m.to_dict())))
	assert_eq(Solver.to_string_grid(m2.grid), Solver.to_string_grid(m.grid), "grid")
	assert_eq(m2.notes, m.notes, "notes")
	assert_eq(m2.elapsed, 12.0, "elapsed")
	assert_eq(m2.mistakes, m.mistakes, "mistakes")

func test_completed_units() -> void:
	var m = _new()
	var target := _first_empty(m)
	for i in 81:
		if m.grid[i] == 0 and i != target:
			m.place(i, m.solution[i])
	assert_eq(m.completed_units_at(target).size(), 0, "nothing complete yet")
	m.place(target, m.solution[target])
	assert_eq(m.completed_units_at(target).size(), 3, "row, column and box complete")
