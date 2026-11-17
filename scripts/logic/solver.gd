extends RefCounted
## Pure-logic Sudoku solver / validator. No scene nodes, fully unit-testable.
##
## A grid is a PackedInt32Array of 81 ints, row-major, 0 = empty, 1..9 = digit.
## Candidate sets are 9-bit masks (bit 0 = digit 1).

const CELLS := 81
const ALL_MASK := 0x1FF

@warning_ignore("integer_division")
static func row_of(i: int) -> int:
	return i / 9

static func col_of(i: int) -> int:
	return i % 9

@warning_ignore("integer_division")
static func box_of(i: int) -> int:
	return (i / 27) * 3 + (i % 9) / 3

static func popcount(m: int) -> int:
	var n := 0
	while m != 0:
		m &= m - 1
		n += 1
	return n

## Digit (1..9) for a single-bit mask.
static func bit_to_digit(bit: int) -> int:
	var v := 1
	while bit > 1:
		bit >>= 1
		v += 1
	return v

static func empty_grid() -> PackedInt32Array:
	var g := PackedInt32Array()
	g.resize(CELLS)
	return g

## Builds a grid from an 81-char string ('0' or '.' = empty).
static func from_string(s: String) -> PackedInt32Array:
	var g := empty_grid()
	for i in mini(s.length(), CELLS):
		var ch := s[i]
		g[i] = 0 if ch == "." else clampi(int(ch), 0, 9)
	return g

static func to_string_grid(g: PackedInt32Array) -> String:
	var s := ""
	for v in g:
		s += str(v)
	return s

## Mask of digits already used in the row, column and box of `idx` (ignores idx itself).
static func used_mask(g: PackedInt32Array, idx: int) -> int:
	var r := row_of(idx)
	var c := col_of(idx)
	var b := box_of(idx)
	var m := 0
	for i in CELLS:
		if i == idx or g[i] == 0:
			continue
		if row_of(i) == r or col_of(i) == c or box_of(i) == b:
			m |= 1 << (g[i] - 1)
	return m

static func candidates(g: PackedInt32Array, idx: int) -> int:
	return ALL_MASK & ~used_mask(g, idx)

## True if placing `v` at `idx` conflicts with no other filled cell.
static func is_valid_placement(g: PackedInt32Array, idx: int, v: int) -> bool:
	return v >= 1 and v <= 9 and (used_mask(g, idx) & (1 << (v - 1))) == 0

## Indices of every filled cell that shares its digit with another cell in a unit.
static func find_conflicts(g: PackedInt32Array) -> PackedInt32Array:
	var bad := PackedInt32Array()
	for i in CELLS:
		if g[i] != 0 and (used_mask(g, i) & (1 << (g[i] - 1))) != 0:
			bad.append(i)
	return bad

static func is_consistent(g: PackedInt32Array) -> bool:
	return find_conflicts(g).is_empty()

static func is_complete(g: PackedInt32Array) -> bool:
	for v in g:
		if v == 0:
			return false
	return true

## Complete AND conflict-free.
static func is_solved(g: PackedInt32Array) -> bool:
	return g.size() == CELLS and is_complete(g) and is_consistent(g)

## Returns the (first) solution, or an empty array if none exists.
static func solve(g: PackedInt32Array) -> PackedInt32Array:
	var found: Array = []
	_search(g, 1, found)
	return found[0] if not found.is_empty() else PackedInt32Array()

## Counts solutions, stopping early at `limit` (use 2 for a uniqueness check).
static func count_solutions(g: PackedInt32Array, limit: int = 2) -> int:
	return _search(g, limit, [])

static func has_unique_solution(g: PackedInt32Array) -> bool:
	return count_solutions(g, 2) == 1

## Backtracking with minimum-remaining-values cell choice. Bitmasks per unit.
static func _search(g: PackedInt32Array, limit: int, found: Array) -> int:
	if g.size() != CELLS or not is_consistent(g):
		return 0
	var work := g.duplicate()
	var rows := PackedInt32Array([0, 0, 0, 0, 0, 0, 0, 0, 0])
	var cols := rows.duplicate()
	var boxes := rows.duplicate()
	for i in CELLS:
		if work[i] != 0:
			var bit := 1 << (work[i] - 1)
			rows[row_of(i)] |= bit
			cols[col_of(i)] |= bit
			boxes[box_of(i)] |= bit
	return _count(work, rows, cols, boxes, limit, found)

static func _count(g: PackedInt32Array, rows: PackedInt32Array, cols: PackedInt32Array,
		boxes: PackedInt32Array, limit: int, found: Array) -> int:
	var best := -1
	var best_mask := 0
	var best_n := 10
	for i in CELLS:
		if g[i] != 0:
			continue
		var m := ALL_MASK & ~(rows[row_of(i)] | cols[col_of(i)] | boxes[box_of(i)])
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
	var r := row_of(best)
	var c := col_of(best)
	var b := box_of(best)
	var total := 0
	var m := best_mask
	while m != 0:
		var bit := m & -m
		m ^= bit
		g[best] = bit_to_digit(bit)
		rows[r] |= bit
		cols[c] |= bit
		boxes[b] |= bit
		total += _count(g, rows, cols, boxes, limit - total, found)
		g[best] = 0
		rows[r] &= ~bit
		cols[c] &= ~bit
		boxes[b] &= ~bit
		if total >= limit:
			return total
	return total

## Finds a logical hint. Tries naked single, then hidden single, then falls back
## to revealing a cell from `solution`. Returns {index, value, technique} or {}
## when the grid is already full.
static func find_hint(g: PackedInt32Array, solution: PackedInt32Array) -> Dictionary:
	for i in CELLS:
		if g[i] == 0:
			var m := candidates(g, i)
			if popcount(m) == 1:
				return {"index": i, "value": bit_to_digit(m), "technique": "naked_single"}
	for unit in _all_units():
		for d in range(1, 10):
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

static func _all_units() -> Array:
	var units: Array = []
	for k in 9:
		var row := PackedInt32Array()
		var col := PackedInt32Array()
		var box := PackedInt32Array()
		for j in 9:
			row.append(k * 9 + j)
			col.append(j * 9 + k)
			box.append(((k / 3) * 3 + j / 3) * 9 + (k % 3) * 3 + j % 3)
		units.append(row)
		units.append(col)
		units.append(box)
	return units
