extends RefCounted
## Sudoku puzzle generator. Builds a random full solution by randomised
## backtracking, then removes clues one at a time, keeping a removal only if
## the puzzle still has exactly ONE solution.

const Solver := preload("res://scripts/logic/solver.gd")

enum Difficulty { EASY, MEDIUM, HARD, EXPERT }

## Target number of clues (givens) left. Removal stops once reached; if the
## uniqueness constraint blocks it the puzzle simply keeps a few more clues.
const TARGET_CLUES := {
	Difficulty.EASY: 40,
	Difficulty.MEDIUM: 34,
	Difficulty.HARD: 30,
	Difficulty.EXPERT: 25,
}

const NAMES := {
	Difficulty.EASY: "Easy",
	Difficulty.MEDIUM: "Medium",
	Difficulty.HARD: "Hard",
	Difficulty.EXPERT: "Expert",
}

## Returns {puzzle, solution, difficulty, seed, clues}. seed < 0 picks a random one.
static func generate(difficulty: int, seed_value: int = -1) -> Dictionary:
	var rng := RandomNumberGenerator.new()
	if seed_value < 0:
		rng.randomize()
		seed_value = int(rng.randi())
	rng.seed = seed_value

	var solution := random_solution(rng)
	var puzzle := solution.duplicate()
	var order := range(Solver.CELLS)
	_shuffle(order, rng)
	var clues := Solver.CELLS
	var target: int = TARGET_CLUES[difficulty]
	for idx in order:
		if clues <= target:
			break
		var kept: int = puzzle[idx]
		puzzle[idx] = 0
		if Solver.count_solutions(puzzle, 2) == 1:
			clues -= 1
		else:
			puzzle[idx] = kept
	return {
		"puzzle": puzzle,
		"solution": solution,
		"difficulty": difficulty,
		"seed": seed_value,
		"clues": clues,
	}

## A random fully-solved grid (MRV backtracking with shuffled digit order).
static func random_solution(rng: RandomNumberGenerator) -> PackedInt32Array:
	var g := Solver.empty_grid()
	_fill(g, rng)
	return g

static func _fill(g: PackedInt32Array, rng: RandomNumberGenerator) -> bool:
	var best := -1
	var best_mask := 0
	var best_n := 10
	for i in Solver.CELLS:
		if g[i] != 0:
			continue
		var m := Solver.candidates(g, i)
		var n := Solver.popcount(m)
		if n == 0:
			return false
		if n < best_n:
			best = i
			best_mask = m
			best_n = n
	if best == -1:
		return true
	var digits := []
	for d in range(1, 10):
		if best_mask & (1 << (d - 1)):
			digits.append(d)
	_shuffle(digits, rng)
	for d in digits:
		g[best] = d
		if _fill(g, rng):
			return true
	g[best] = 0
	return false

static func _shuffle(a: Array, rng: RandomNumberGenerator) -> void:
	for i in range(a.size() - 1, 0, -1):
		var j := rng.randi_range(0, i)
		var t = a[i]
		a[i] = a[j]
		a[j] = t
