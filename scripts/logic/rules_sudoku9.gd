extends RefCounted
## Rules adapter for classic 9x9 Sudoku (the "rules" interface used by GameModel).
## Interface: CELLS, DIGITS, is_peer(a,b), units_at(idx), find_hint(grid, solution).

const Solver := preload("res://scripts/logic/solver.gd")

const CELLS := 81
const DIGITS := 9

static func is_peer(a: int, b: int) -> bool:
	return Solver.row_of(a) == Solver.row_of(b) or Solver.col_of(a) == Solver.col_of(b) \
		or Solver.box_of(a) == Solver.box_of(b)

## Row, column and box (as cell-index arrays) containing `idx`.
static func units_at(idx: int) -> Array:
	var row := []
	var col := []
	var box := []
	for i in CELLS:
		if Solver.row_of(i) == Solver.row_of(idx):
			row.append(i)
		if Solver.col_of(i) == Solver.col_of(idx):
			col.append(i)
		if Solver.box_of(i) == Solver.box_of(idx):
			box.append(i)
	return [row, col, box]

static func find_hint(grid: PackedInt32Array, solution: PackedInt32Array) -> Dictionary:
	return Solver.find_hint(grid, solution)
