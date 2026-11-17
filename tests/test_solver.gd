extends "res://tests/test_case.gd"

const Solver := preload("res://scripts/logic/solver.gd")

const PUZZLE := "530070000600195000098000060800060003400803001700020006060000280000419005000080079"
const SOLUTION := "534678912672195348198342567859761423426853791713924856961537284287419635345286179"

func test_solves_known_puzzle() -> void:
	var s := Solver.solve(Solver.from_string(PUZZLE))
	assert_eq(Solver.to_string_grid(s), SOLUTION, "known puzzle solution")

func test_solution_is_solved() -> void:
	assert_true(Solver.is_solved(Solver.from_string(SOLUTION)), "solution valid")
	assert_true(not Solver.is_solved(Solver.from_string(PUZZLE)), "puzzle not complete")

func test_detects_row_col_box_conflicts() -> void:
	var g := Solver.empty_grid()
	g[0] = 5
	g[8] = 5  # same row
	assert_eq(Solver.find_conflicts(g).size(), 2, "row conflict")
	g = Solver.empty_grid()
	g[0] = 5
	g[72] = 5  # same column
	assert_eq(Solver.find_conflicts(g).size(), 2, "column conflict")
	g = Solver.empty_grid()
	g[0] = 5
	g[20] = 5  # same box (row 2, col 2)
	assert_eq(Solver.find_conflicts(g).size(), 2, "box conflict")
	g = Solver.empty_grid()
	g[0] = 5
	g[10] = 6
	assert_true(Solver.is_consistent(g), "no conflict")

func test_valid_placement() -> void:
	var g := Solver.from_string(PUZZLE)
	assert_true(Solver.is_valid_placement(g, 2, 4), "4 fits at r0c2")
	assert_true(not Solver.is_valid_placement(g, 2, 5), "5 clashes in row")

func test_count_solutions_unique() -> void:
	assert_eq(Solver.count_solutions(Solver.from_string(PUZZLE), 2), 1, "known puzzle unique")
	assert_true(Solver.has_unique_solution(Solver.from_string(PUZZLE)), "has_unique_solution")

func test_count_solutions_multiple() -> void:
	assert_eq(Solver.count_solutions(Solver.empty_grid(), 2), 2, "empty grid has many (capped at limit)")
	# A sparse grid (only the first row filled) is hugely ambiguous.
	var g := Solver.empty_grid()
	for i in 9:
		g[i] = i + 1
	assert_eq(Solver.count_solutions(g, 2), 2, "sparse puzzle has 2+ solutions")
	# Removing one clue from a unique puzzle in a way that opens an ambiguity:
	# blank every cell of the known solution except 17 -> many solutions.
	var h := Solver.from_string(SOLUTION)
	for i in range(17, 81):
		h[i] = 0
	assert_eq(Solver.count_solutions(h, 2), 2, "17 givens of a solution, not unique here")

func test_count_solutions_none() -> void:
	var g := Solver.from_string(PUZZLE)
	g[2] = 5  # conflicts with 5 in row 0
	assert_eq(Solver.count_solutions(g, 2), 0, "inconsistent grid")
	var h := Solver.empty_grid()
	# Cell 0 has no candidates: row has 1-8, column has 9.
	for i in range(1, 9):
		h[i] = i
	h[9] = 9
	assert_eq(Solver.count_solutions(h, 2), 0, "dead-end grid")
	assert_eq(Solver.solve(h).size(), 0, "solve returns empty")

func test_solve_does_not_mutate_input() -> void:
	var g := Solver.from_string(PUZZLE)
	Solver.solve(g)
	Solver.count_solutions(g, 2)
	assert_eq(Solver.to_string_grid(g), PUZZLE, "input untouched")

func test_hint_matches_solution() -> void:
	var g := Solver.from_string(PUZZLE)
	var sol := Solver.from_string(SOLUTION)
	var h := Solver.find_hint(g, sol)
	assert_true(not h.is_empty(), "hint exists")
	assert_eq(h["value"], sol[h["index"]], "hint value correct")
	assert_eq(g[h["index"]], 0, "hint on empty cell")
	assert_true(Solver.find_hint(sol, sol).is_empty(), "no hint for full grid")
