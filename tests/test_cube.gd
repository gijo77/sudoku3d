extends "res://tests/test_case.gd"

const Cube := preload("res://scripts/logic/cube_sudoku.gd")
const Model := preload("res://scripts/game/game_model.gd")

func _model(seed_value: int = 3, diff: int = 0):
	var m = Model.new(Cube)
	m.start(Cube.generate(diff, seed_value))
	return m

func test_peer_structure() -> void:
	for i in 64:
		assert_eq(Cube.peers_of(i).size(), 10, "cell %d has 3 row + 3 col + 1 box + 3 pillar peers" % i)
	assert_true(Cube.is_peer(0, 16), "same pillar")
	assert_true(Cube.is_peer(0, 3), "same row")
	assert_true(Cube.is_peer(0, 12), "same column")
	assert_true(Cube.is_peer(0, 5), "same 2x2 box")
	assert_true(not Cube.is_peer(0, 21), "different layer, different pillar")
	assert_true(not Cube.is_peer(0, 10), "same layer, unrelated")

func test_units() -> void:
	assert_eq(Cube.all_units().size(), 4 * 12 + 16, "48 layer units + 16 pillars")
	assert_eq(Cube.units_at(0).size(), 4, "row, column, box, pillar")
	for u in Cube.all_units():
		assert_eq(u.size(), 4, "unit size")

func test_random_solutions_valid() -> void:
	var rng := RandomNumberGenerator.new()
	for s in 5:
		rng.seed = s
		var sol := Cube.random_solution(rng)
		assert_true(Cube.is_solved(sol), "solution %d valid" % s)
		for u in Cube.all_units():
			var seen := 0
			for i in u:
				seen |= 1 << (sol[i] - 1)
			assert_eq(seen, 0xF, "every unit holds 1-4")

func test_generated_puzzles_unique() -> void:
	for d in 4:
		for s in 3:
			var r := Cube.generate(d, 500 + d * 10 + s)
			var puz: PackedInt32Array = r["puzzle"]
			assert_eq(Cube.count_solutions(puz, 2), 1, "diff %d seed %d unique" % [d, s])
			assert_eq(Cube.solve(puz), r["solution"], "solver reproduces solution")
			assert_true(r["clues"] <= Cube.TARGET_CLUES[d] + 6, "clues %d near target (diff %d)" % [r["clues"], d])
	var easy := Cube.generate(0, 9)["clues"] as int
	var expert := Cube.generate(3, 9)["clues"] as int
	assert_true(easy > expert, "easy has more clues than expert")

func test_deterministic() -> void:
	assert_eq(Cube.generate(1, 42)["puzzle"], Cube.generate(1, 42)["puzzle"], "same seed same puzzle")

func test_conflict_detection() -> void:
	var g := Cube.empty_grid()
	g[0] = 2
	g[16] = 2  # same pillar
	assert_eq(Cube.find_conflicts(g).size(), 2, "pillar conflict")
	g = Cube.empty_grid()
	g[0] = 2
	g[5] = 2  # same box
	assert_eq(Cube.find_conflicts(g).size(), 2, "box conflict")

func test_model_with_cube_rules() -> void:
	var m = _model()
	assert_eq(m.cells, 64, "64 cells")
	assert_eq(m.digits, 4, "4 digits")
	var total := 0
	for d in range(1, 5):
		total += m.remaining(d)
	assert_eq(total, m.givens.count(0), "remaining equals empty cells")
	var i: int = m.grid.find(0)
	assert_eq(m.place(i, m.solution[i]), Model.Result.PLACED_OK, "place correct")
	assert_eq(m.place(m.grid.find(0), 5), Model.Result.IGNORED, "digit 5 invalid in cube")
	var j: int = m.grid.find(0)
	assert_eq(m.place(j, (m.solution[j] % 4) + 1), Model.Result.PLACED_WRONG, "wrong digit")
	assert_eq(m.mistakes, 1, "mistake counted")

func test_model_hint_and_win() -> void:
	var m = _model(11, 1)
	var h: int = m.hint()
	assert_eq(m.grid[h], m.solution[h], "hint correct")
	for i in 64:
		if m.grid[i] == 0:
			m.place(i, m.solution[i])
	assert_eq(m.status, Model.Status.WON, "won")

func test_model_completed_units() -> void:
	var m = _model(5, 0)
	var target: int = m.grid.find(0)
	for i in 64:
		if m.grid[i] == 0 and i != target:
			m.place(i, m.solution[i])
	m.place(target, m.solution[target])
	assert_eq(m.completed_units_at(target).size(), 4, "row, column, box and pillar done")
