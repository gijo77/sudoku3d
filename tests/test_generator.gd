extends "res://tests/test_case.gd"

const Solver := preload("res://scripts/logic/solver.gd")
const Generator := preload("res://scripts/logic/generator.gd")
const Daily := preload("res://scripts/logic/daily.gd")

func _check_puzzle(r: Dictionary, label: String) -> void:
	var puzzle: PackedInt32Array = r["puzzle"]
	var solution: PackedInt32Array = r["solution"]
	assert_true(Solver.is_solved(solution), label + ": solution valid")
	assert_true(Solver.is_consistent(puzzle), label + ": puzzle consistent")
	assert_eq(Solver.count_solutions(puzzle, 2), 1, label + ": exactly one solution")
	assert_eq(Solver.to_string_grid(Solver.solve(puzzle)), Solver.to_string_grid(solution), label + ": solver reproduces solution")
	var clues := 0
	for i in Solver.CELLS:
		if puzzle[i] != 0:
			clues += 1
			assert_eq(puzzle[i], solution[i], label + ": givens match solution")
	assert_eq(clues, r["clues"], label + ": clue count reported")

func test_random_solution_valid() -> void:
	var rng := RandomNumberGenerator.new()
	for s in 5:
		rng.seed = s
		assert_true(Solver.is_solved(Generator.random_solution(rng)), "seed %d" % s)

func test_easy_unique() -> void:
	for s in 3:
		var r := Generator.generate(Generator.Difficulty.EASY, 100 + s)
		_check_puzzle(r, "easy %d" % s)
		assert_true(r["clues"] <= 40, "easy clue target")

func test_medium_unique() -> void:
	for s in 3:
		var r := Generator.generate(Generator.Difficulty.MEDIUM, 200 + s)
		_check_puzzle(r, "medium %d" % s)
		assert_true(r["clues"] <= 34, "medium clue target")

func test_hard_unique() -> void:
	for s in 3:
		var r := Generator.generate(Generator.Difficulty.HARD, 300 + s)
		_check_puzzle(r, "hard %d" % s)
		assert_true(r["clues"] <= 32, "hard clue count (%d)" % r["clues"])

func test_expert_unique() -> void:
	for s in 3:
		var r := Generator.generate(Generator.Difficulty.EXPERT, 400 + s)
		_check_puzzle(r, "expert %d" % s)
		assert_true(r["clues"] <= 29, "expert clue count (%d)" % r["clues"])

func test_difficulty_ordering() -> void:
	var easy := Generator.generate(Generator.Difficulty.EASY, 7)["clues"] as int
	var expert := Generator.generate(Generator.Difficulty.EXPERT, 7)["clues"] as int
	assert_true(easy > expert, "easy has more clues than expert")

func test_seed_is_deterministic() -> void:
	var a := Generator.generate(Generator.Difficulty.MEDIUM, 12345)
	var b := Generator.generate(Generator.Difficulty.MEDIUM, 12345)
	var c := Generator.generate(Generator.Difficulty.MEDIUM, 54321)
	assert_eq(Solver.to_string_grid(a["puzzle"]), Solver.to_string_grid(b["puzzle"]), "same seed same puzzle")
	assert_true(Solver.to_string_grid(a["puzzle"]) != Solver.to_string_grid(c["puzzle"]), "different seed differs")

func test_daily_same_date_same_puzzle() -> void:
	var a := Daily.puzzle_for_date(2026, 11, 17)
	var b := Daily.puzzle_for_date(2026, 11, 17)
	var c := Daily.puzzle_for_date(2026, 11, 18)
	assert_eq(Solver.to_string_grid(a["puzzle"]), Solver.to_string_grid(b["puzzle"]), "same day")
	assert_true(Solver.to_string_grid(a["puzzle"]) != Solver.to_string_grid(c["puzzle"]), "next day differs")
	_check_puzzle(a, "daily")

func test_daily_seed_and_weekday() -> void:
	assert_eq(Daily.seed_for(2026, 11, 17), 20261117, "seed format")
	assert_eq(Daily.difficulty_for_weekday(0), Generator.Difficulty.EXPERT, "sunday")
	assert_eq(Daily.difficulty_for_weekday(1), Generator.Difficulty.EASY, "monday")
