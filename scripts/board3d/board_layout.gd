extends RefCounted
## Geometry of the 3D board (pure maths, unit-tested). The board lies in the XZ
## plane; tile tops are at y = TOP_Y. Boxes are separated by a wider gap.

const TILE := 1.0
const GAP := 0.05
const BOX_GAP := 0.14
const PITCH := TILE + GAP
const TILE_H := 0.3
const TOP_Y := TILE_H / 2.0

## Centre of row/column `i` (0..8) along one axis.
@warning_ignore("integer_division")
static func axis_pos(i: int) -> float:
	return (i - 4) * PITCH + ((i / 3) - 1) * BOX_GAP

## (x, z) centre of cell `idx`.
static func cell_center(idx: int) -> Vector2:
	return Vector2(axis_pos(idx % 9), axis_pos(idx / 9))

## Row/column index nearest to coordinate `v`, or -1 outside the board.
static func axis_index(v: float) -> int:
	var best := -1
	var best_d := INF
	for i in 9:
		var d := absf(v - axis_pos(i))
		if d < best_d:
			best_d = d
			best = i
	return best if best_d <= TILE / 2.0 + GAP else -1

## Cell under board-local (x, z), or -1.
static func cell_at(x: float, z: float) -> int:
	var c := axis_index(x)
	var r := axis_index(z)
	return -1 if c < 0 or r < 0 else r * 9 + c

## Full width of the board including outer half-pitch margin.
static func extent() -> float:
	return axis_pos(8) - axis_pos(0) + TILE + 2.0 * GAP
