extends "res://scripts/board3d/board_view_3d.gd"
## 3D Cube Sudoku board: four 4x4 layers stacked vertically (layer 0 at the bottom).
## Reuses the classic board's tiles, highlights and effects; only layout and
## picking differ. Cell index = z*16 + y*4 + x.

const LAYER_SPACING := 2.3
const CUBE_PITCH := 1.12

static func axis(i: int) -> float:
	return (i - 1.5) * CUBE_PITCH

func _cell_pos(i: int) -> Vector3:
	var x := i % 4
	var y := (i / 4) % 4
	var z := i / 16
	return Vector3(axis(x), (z - 1.5) * LAYER_SPACING, axis(y))

func _build_tiles() -> void:
	for z in 4:
		var plate := MeshInstance3D.new()
		var pm := BoxMesh.new()
		var w := CUBE_PITCH * 4 + 0.1
		pm.size = Vector3(w, 0.16, w)
		plate.mesh = pm
		plate.position = Vector3(0, (z - 1.5) * LAYER_SPACING - Layout.TILE_H / 2.0 - 0.1, 0)
		var m := StandardMaterial3D.new()
		m.albedo_color = ThemeManager.palette["plate"]
		m.roughness = 0.7
		plate.material_override = m
		add_child(plate)
	for i in 64:
		_add_tile(i)

## Nearest layer whose tile-top plane the ray hits inside a tile wins.
func pick(camera: Camera3D, screen_pos: Vector2) -> int:
	var from := camera.project_ray_origin(screen_pos)
	var dir := camera.project_ray_normal(screen_pos)
	var best := -1
	var best_t := INF
	for z in 4:
		var y := to_global(Vector3(0, (z - 1.5) * LAYER_SPACING + Layout.TOP_Y, 0)).y
		var hit = Plane(Vector3.UP, y).intersects_ray(from, dir)
		if hit == null:
			continue
		var local := to_local(hit)
		var cx := roundi(local.x / CUBE_PITCH + 1.5)
		var cy := roundi(local.z / CUBE_PITCH + 1.5)
		if cx < 0 or cx > 3 or cy < 0 or cy > 3:
			continue
		if absf(local.x - axis(cx)) > 0.5 + 0.03 or absf(local.z - axis(cy)) > 0.5 + 0.03:
			continue
		var t := from.distance_to(hit)
		if t < best_t:
			best_t = t
			best = z * 16 + cy * 4 + cx
	return best
