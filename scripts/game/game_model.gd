extends RefCounted
## Game state and rules for one Sudoku game: placing, pencil notes, erase,
## undo/redo, hints, mistakes, timer, win/lose. No scene nodes, so it is fully
## unit-testable and shared by the 2D and 3D views.

const Solver := preload("res://scripts/logic/solver.gd")
const Generator := preload("res://scripts/logic/generator.gd")

const MAX_MISTAKES := 3

enum Result { IGNORED, PLACED_OK, PLACED_WRONG, NOTE_TOGGLED, ERASED }
enum Status { PLAYING, WON, LOST }

var givens: PackedInt32Array = Solver.empty_grid()
var solution: PackedInt32Array = Solver.empty_grid()
var grid: PackedInt32Array = Solver.empty_grid()
## Pencil notes: per-cell 9-bit mask (bit 0 = digit 1).
var notes: PackedInt32Array = Solver.empty_grid()
var mistakes := 0
var hints_used := 0
var elapsed := 0.0
var difficulty := Generator.Difficulty.MEDIUM
var seed_value := 0
var status := Status.PLAYING

var _undo: Array = []
var _redo: Array = []

## Starts a game from generator output ({puzzle, solution, difficulty, seed}).
func start(data: Dictionary) -> void:
	givens = data["puzzle"].duplicate()
	solution = data["solution"].duplicate()
	grid = givens.duplicate()
	notes = Solver.empty_grid()
	difficulty = data.get("difficulty", Generator.Difficulty.MEDIUM)
	seed_value = data.get("seed", 0)
	mistakes = 0
	hints_used = 0
	elapsed = 0.0
	status = Status.PLAYING
	_undo.clear()
	_redo.clear()

func tick(delta: float) -> void:
	if status == Status.PLAYING:
		elapsed += delta

func is_given(idx: int) -> bool:
	return givens[idx] != 0

## True when the cell holds the correct digit (givens included).
func is_correct(idx: int) -> bool:
	return grid[idx] != 0 and grid[idx] == solution[idx]

func is_wrong(idx: int) -> bool:
	return grid[idx] != 0 and grid[idx] != solution[idx]

## Cells the player may still change (empty or holding a wrong digit).
func is_editable(idx: int) -> bool:
	return status == Status.PLAYING and not is_correct(idx)

## How many of digit `d` are still to be placed correctly (for number pad badges).
func remaining(d: int) -> int:
	var placed := 0
	for i in Solver.CELLS:
		if grid[i] == d and solution[i] == d:
			placed += 1
	return 9 - placed

func can_undo() -> bool:
	return status == Status.PLAYING and not _undo.is_empty()

func can_redo() -> bool:
	return status == Status.PLAYING and not _redo.is_empty()

## Enter digit `v` in cell `idx`. Wrong digits are placed (shown red) and cost a mistake.
func place(idx: int, v: int) -> int:
	if not is_editable(idx) or grid[idx] == v or v < 1 or v > 9:
		return Result.IGNORED
	return _set_value(idx, v, true)

func toggle_note(idx: int, v: int) -> int:
	if not is_editable(idx) or grid[idx] != 0 or v < 1 or v > 9:
		return Result.IGNORED
	var change := [idx, grid[idx], notes[idx], grid[idx], notes[idx] ^ (1 << (v - 1))]
	_commit([change], 0)
	return Result.NOTE_TOGGLED

func erase(idx: int) -> int:
	if not is_editable(idx) or (grid[idx] == 0 and notes[idx] == 0):
		return Result.IGNORED
	_commit([[idx, grid[idx], notes[idx], 0, 0]], 0)
	return Result.ERASED

## Reveals a correct digit. Uses `idx` if it is an editable cell, otherwise
## finds a logical hint. Returns the cell index, or -1 if nothing to hint.
func hint(idx: int = -1) -> int:
	if status != Status.PLAYING:
		return -1
	if idx < 0 or not is_editable(idx):
		var clean := givens.duplicate()
		for i in Solver.CELLS:
			if is_correct(i):
				clean[i] = grid[i]
		var h := Solver.find_hint(clean, solution)
		if h.is_empty():
			return -1
		idx = h["index"]
	hints_used += 1
	_set_value(idx, solution[idx], false)
	return idx

func undo() -> bool:
	if not can_undo():
		return false
	var rec: Dictionary = _undo.pop_back()
	_apply(rec["changes"], false)
	_redo.append(rec)
	return true

func redo() -> bool:
	if not can_redo():
		return false
	var rec: Dictionary = _redo.pop_back()
	_apply(rec["changes"], true)
	_undo.append(rec)
	return true

## Mistakes are never refunded by undo.
func _set_value(idx: int, v: int, count_mistake: bool) -> int:
	var changes := [[idx, grid[idx], notes[idx], v, 0]]
	var correct := v == solution[idx]
	if correct:
		# Placing a correct digit removes that note from every peer cell.
		var bit := 1 << (v - 1)
		for i in Solver.CELLS:
			if i != idx and (notes[i] & bit) != 0 and _is_peer(i, idx):
				changes.append([i, grid[i], notes[i], grid[i], notes[i] & ~bit])
	var miss := 0
	if not correct and count_mistake:
		miss = 1
	_commit(changes, miss)
	return Result.PLACED_OK if correct else Result.PLACED_WRONG

func _is_peer(a: int, b: int) -> bool:
	return Solver.row_of(a) == Solver.row_of(b) or Solver.col_of(a) == Solver.col_of(b) \
		or Solver.box_of(a) == Solver.box_of(b)

func _commit(changes: Array, miss: int) -> void:
	_apply(changes, true)
	_undo.append({"changes": changes})
	_redo.clear()
	mistakes += miss
	_update_status()

## change = [idx, old_value, old_notes, new_value, new_notes]
func _apply(changes: Array, forward: bool) -> void:
	for c in changes:
		grid[c[0]] = c[3] if forward else c[1]
		notes[c[0]] = c[4] if forward else c[2]

func _update_status() -> void:
	if mistakes >= MAX_MISTAKES:
		status = Status.LOST
	elif grid == solution:
		status = Status.WON

func to_dict() -> Dictionary:
	return {
		"givens": Array(givens), "solution": Array(solution), "grid": Array(grid),
		"notes": Array(notes), "mistakes": mistakes, "hints_used": hints_used,
		"elapsed": elapsed, "difficulty": difficulty, "seed": seed_value,
	}

func from_dict(d: Dictionary) -> void:
	givens = PackedInt32Array(d["givens"])
	solution = PackedInt32Array(d["solution"])
	grid = PackedInt32Array(d["grid"])
	notes = PackedInt32Array(d["notes"])
	mistakes = int(d["mistakes"])
	hints_used = int(d["hints_used"])
	elapsed = float(d["elapsed"])
	difficulty = int(d["difficulty"])
	seed_value = int(d["seed"])
	status = Status.PLAYING
	_undo.clear()
	_redo.clear()
	_update_status()
