extends RefCounted
## "3D Cube Sudoku" (bonus mode): a 4x4x4 cube of cells holding digits 1-4.
## Rules: each of the 4 horizontal layers is a valid 4x4 Sudoku (rows, columns and
## 2x2 boxes), AND every vertical pillar (same row/column through all layers)
## holds 1-4 exactly once. Cell index = z*16 + y*4 + x  (z = layer, 0 = bottom).
##
## Also acts as a "rules" adapter for GameModel: CELLS, DIGITS, is_peer, units_at, find_hint.
## Contains its own solver / uniqueness check / generator (the cube is tiny, so a
## simple MRV backtracking search is plenty fast).

const CELLS := 64
const DIGITS := 4
const ALL_MASK := 0xF

const TARGET_CLUES := {0: 36, 1: 30, 2: 26, 3: 22}   # Easy .. Expert (Generator.Difficulty order)

static var _peers: Array = []
static var _units: Array = []

static func x_of(i: int) -> int:
	return i % 4

@warning_ignore("integer_division")
static func y_of(i: int) -> int:
	return (i / 4) % 4

@warning_ignore("integer_division")
static func z_of(i: int) -> int:
	return i / 16

@warning_ignore("integer_division")
static func _box_of(i: int) -> int:
	return (y_of(i) / 2) * 2 + x_of(i) / 2

static func _build() -> void:
	if not _peers.is_empty():
		return
	for i in CELLS:
		var list := PackedInt32Array()
		for j in CELLS:
			if j != i and _related(i, j):
				list.append(j)
		_peers.append(list)
	for z in 4:
		for k in 4:
			var row := []
			var col := []
			var box := []
			for j in 4:
				row.append(z * 16 + k * 4 + j)
				col.append(z * 16 + j * 4 + k)
			for i in 16:
				if _box_of(z * 16 + i) == k:
					box.append(z * 16 + i)
			_units.append(row)
			_units.append(col)
			_units.append(box)
	for p in 16:
		var pillar := []
		for z in 4:
			pillar.append(z * 16 + p)
		_units.append(pillar)

static func _related(a: int, b: int) -> bool:
	if z_of(a) == z_of(b):
		return y_of(a) == y_of(b) or x_of(a) == x_of(b) or _box_of(a) == _box_of(b)
	return x_of(a) == x_of(b) and y_of(a) == y_of(b)   # same pillar

static func peers_of(i: int) -> PackedInt32Array:
	_build()
	return _peers[i]

static func is_peer(a: int, b: int) -> bool:
	return a != b and _related(a, b)

## Every unit (rows, columns, boxes per layer, plus pillars) as cell-index arrays.
static func all_units() -> Array:
	_build()
	return _units

## Units containing `idx` (layer row, column, box and the pillar).
static func units_at(idx: int) -> Array:
	var out := []
	for u in all_units():
		if idx in u:
			out.append(u)
	return out

static func empty_grid() -> PackedInt32Array:
	var g := PackedInt32Array()
	g.resize(CELLS)
	return g

static func popcount(m: int) -> int:
	var n := 0
	while m != 0:
		m &= m - 1
		n += 1
	return n

static func bit_to_digit(bit: int) -> int:
	var v := 1
	while bit > 1:
		bit >>= 1
		v += 1
	return v

static func candidates(g: PackedInt32Array, idx: int) -> int:
	var used := 0
	for p in peers_of(idx):
		if g[p] != 0:
			used |= 1 << (g[p] - 1)
	return ALL_MASK & ~used

static func find_conflicts(g: PackedInt32Array) -> PackedInt32Array:
	var bad := PackedInt32Array()
	for i in CELLS:
		if g[i] == 0:
			continue
		for p in peers_of(i):
			if g[p] == g[i]:
				bad.append(i)
				break
	return bad

static func is_solved(g: PackedInt32Array) -> bool:
	if g.size() != CELLS:
		return false
	for v in g:
		if v == 0:
			return false
	return find_conflicts(g).is_empty()

static func solve(g: PackedInt32Array) -> PackedInt32Array:
	var found: Array = []
	_search(g, 1, found)
	return found[0] if not found.is_empty() else PackedInt32Array()

static func count_solutions(g: PackedInt32Array, limit: int = 2) -> int:
	return _search(g, limit, [])

static func _search(g: PackedInt32Array, limit: int, found: Array) -> int:
	if g.size() != CELLS or not find_conflicts(g).is_empty():
		return 0
	return _count(g.duplicate(), limit, found)

static func _count(g: PackedInt32Array, limit: int, found: Array) -> int:
	var best := -1
	var best_mask := 0
	var best_n := 10
	for i in CELLS:
		if g[i] != 0:
			continue
		var m := candidates(g, i)
		var n := popcount(m)
		if n == 0:
			return 0
		if n < best_n:
			best = i
			best_mask = m
			best_n = n
			if n == 1:
				break
	if best == -1:
		if found.is_empty():
			found.append(g.duplicate())
		return 1
	var total := 0
	var m := best_mask
	while m != 0:
		var bit := m & -m
		m ^= bit
		g[best] = bit_to_digit(bit)
		total += _count(g, limit - total, found)
		g[best] = 0
		if total >= limit:
			return total
	return total

## Naked single, then hidden single, then reveal from the solution.
static func find_hint(g: PackedInt32Array, solution: PackedInt32Array) -> Dictionary:
	for i in CELLS:
		if g[i] == 0:
			var m := candidates(g, i)
			if popcount(m) == 1:
				return {"index": i, "value": bit_to_digit(m), "technique": "naked_single"}
	for unit in all_units():
		for d in range(1, DIGITS + 1):
			var spot := -1
			var count := 0
			var present := false
			for i in unit:
				if g[i] == d:
					present = true
					break
				if g[i] == 0 and (candidates(g, i) & (1 << (d - 1))) != 0:
					spot = i
					count += 1
			if not present and count == 1:
				return {"index": spot, "value": d, "technique": "hidden_single"}
	for i in CELLS:
		if g[i] == 0 and solution.size() == CELLS:
			return {"index": i, "value": solution[i], "technique": "reveal"}
	return {}

# --- generator ---------------------------------------------------------------

## Returns {puzzle, solution, difficulty, seed, clues} like Generator.generate().
static func generate(difficulty: int, seed_value: int = -1) -> Dictionary:
	var rng := RandomNumberGenerator.new()
	if seed_value < 0:
		rng.randomize()
		seed_value = int(rng.randi())
	rng.seed = seed_value
	var solution := random_solution(rng)
	var puzzle := solution.duplicate()
	var order := range(CELLS)
	_shuffle(order, rng)
	var clues := CELLS
	var target: int = TARGET_CLUES[difficulty]
	for idx in order:
		if clues <= target:
			break
		var kept: int = puzzle[idx]
		puzzle[idx] = 0
		if count_solutions(puzzle, 2) == 1:
			clues -= 1
		else:
			puzzle[idx] = kept
	return {"puzzle": puzzle, "solution": solution, "difficulty": difficulty, "seed": seed_value, "clues": clues}

static func random_solution(rng: RandomNumberGenerator) -> PackedInt32Array:
	var g := empty_grid()
	_fill(g, rng)
	return g

static func _fill(g: PackedInt32Array, rng: RandomNumberGenerator) -> bool:
	var best := -1
	var best_mask := 0
	var best_n := 10
	for i in CELLS:
		if g[i] != 0:
			continue
		var m := candidates(g, i)
		var n := popcount(m)
		if n == 0:
			return false
		if n < best_n:
			best = i
			best_mask = m
			best_n = n
	if best == -1:
		return true
	var ds := []
	for d in range(1, DIGITS + 1):
		if best_mask & (1 << (d - 1)):
			ds.append(d)
	_shuffle(ds, rng)
	for d in ds:
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
