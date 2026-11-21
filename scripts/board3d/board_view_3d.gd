extends Node3D
## The 3D board: 81 tiles on a base plate, tap picking by ray/plane
## intersection, highlight state, and celebration effects.

const Layout := preload("res://scripts/board3d/board_layout.gd")
const Assets := preload("res://scripts/board3d/board_assets.gd")
const Tile := preload("res://scripts/board3d/tile3d.gd")
const Model := preload("res://scripts/game/game_model.gd")

var highlight_peers := true
var highlight_same := true
var assets
var tiles: Array = []
var confetti: GPUParticles3D

func _ready() -> void:
	assets = Assets.new()
	_build_tiles()
	_build_confetti()

## Classic 9x9: base plate + 81 tiles in the XZ plane.
func _build_tiles() -> void:
	var plate := MeshInstance3D.new()
	var pm := BoxMesh.new()
	var w := Layout.extent()
	pm.size = Vector3(w, 0.3, w)
	plate.mesh = pm
	plate.position.y = -Layout.TILE_H / 2.0 - 0.1
	var m := StandardMaterial3D.new()
	m.albedo_color = ThemeManager.palette["plate"]
	m.roughness = 0.7
	plate.material_override = m
	add_child(plate)
	_build_lines(w)
	for i in 81:
		_add_tile(i)

## Glowing divider bars in the gaps between the 3 x 3 boxes plus a rim.
func _build_lines(w: float) -> void:
	var mat: StandardMaterial3D = assets.line_mat()
	var y := -Layout.TILE_H / 2.0 + 0.03
	var cuts := [(Layout.axis_pos(2) + Layout.axis_pos(3)) / 2.0, (Layout.axis_pos(5) + Layout.axis_pos(6)) / 2.0]
	var half := w / 2.0
	for c in cuts:
		_bar(Vector3(c, y, 0), Vector3(0.045, 0.03, w - 0.1), mat)
		_bar(Vector3(0, y, c), Vector3(w - 0.1, 0.03, 0.045), mat)
	for sgn in [-1.0, 1.0]:
		_bar(Vector3(sgn * half, y - 0.05, 0), Vector3(0.05, 0.05, w + 0.05), mat)
		_bar(Vector3(0, y - 0.05, sgn * half), Vector3(w + 0.05, 0.05, 0.05), mat)

func _bar(pos: Vector3, sz: Vector3, mat: Material) -> void:
	var mi := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = sz
	mi.mesh = bm
	mi.material_override = mat
	mi.position = pos
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(mi)

func _add_tile(i: int) -> void:
	var t = Node3D.new()
	t.set_script(Tile)
	add_child(t)
	t.setup(i, assets, _cell_pos(i))
	tiles.append(t)

## Board-local position of a cell's tile.
func _cell_pos(i: int) -> Vector3:
	var c := Layout.cell_center(i)
	return Vector3(c.x, 0, c.y)

func set_state(model, selected: int) -> void:
	var sel_digit: int = model.grid[selected] if selected >= 0 else 0
	for i in tiles.size():
		var bg: int = Assets.Bg.NORMAL
		if selected >= 0:
			if i == selected:
				bg = Assets.Bg.SELECTED
			elif highlight_same and sel_digit != 0 and model.grid[i] == sel_digit:
				bg = Assets.Bg.SAME
			elif highlight_peers and model.rules.is_peer(i, selected):
				bg = Assets.Bg.PEER
		var kind: int = Assets.Kind.GIVEN if model.is_given(i) else \
			(Assets.Kind.WRONG if model.is_wrong(i) else Assets.Kind.PLAYER)
		tiles[i].apply(bg, model.grid[i], kind, model.notes[i])

## Ray from a screen position (viewport coords) onto the tile-top plane -> cell or -1.
func pick(camera: Camera3D, screen_pos: Vector2) -> int:
	var from := camera.project_ray_origin(screen_pos)
	var dir := camera.project_ray_normal(screen_pos)
	var plane := Plane(Vector3.UP, to_global(Vector3(0, Layout.TOP_Y, 0)).y)
	var hit = plane.intersects_ray(from, dir)
	if hit == null:
		return -1
	var local := to_local(hit)
	return Layout.cell_at(local.x, local.z)

func play_result(result: int, idx: int) -> void:
	if result == Model.Result.PLACED_OK:
		tiles[idx].pop()
	elif result == Model.Result.PLACED_WRONG:
		tiles[idx].pop()
		tiles[idx].shake()

## Wave across `cells` (a completed row / column / box), rippling out from `origin`.
func play_wave(cells: Array, origin: int) -> void:
	var o := _cell_pos(origin)
	for c in cells:
		tiles[c].wave(o.distance_to(_cell_pos(c)) * 0.07)

func play_win() -> void:
	for i in tiles.size():
		tiles[i].wave(_cell_pos(i).length() * 0.07)
	confetti.restart()
	confetti.emitting = true

func _build_confetti() -> void:
	confetti = GPUParticles3D.new()
	confetti.position = Vector3(0, 2.0, 0)
	confetti.amount = 140
	confetti.lifetime = 2.6
	confetti.one_shot = true
	confetti.explosiveness = 0.9
	confetti.emitting = false
	var pm := ParticleProcessMaterial.new()
	pm.direction = Vector3(0, 1, 0)
	pm.spread = 70.0
	pm.initial_velocity_min = 5.0
	pm.initial_velocity_max = 10.0
	pm.gravity = Vector3(0, -9.0, 0)
	pm.scale_min = 0.6
	pm.scale_max = 1.3
	var g := Gradient.new()
	g.offsets = PackedFloat32Array([0.0, 0.25, 0.5, 0.75, 1.0])
	g.colors = PackedColorArray([Color(1, 0.3, 0.3), Color(1, 0.85, 0.2), Color(0.3, 0.9, 0.4), Color(0.3, 0.6, 1), Color(0.8, 0.4, 1)])
	var gt := GradientTexture1D.new()
	gt.gradient = g
	pm.color_initial_ramp = gt
	confetti.process_material = pm
	var q := QuadMesh.new()
	q.size = Vector2(0.2, 0.2)
	var qm := StandardMaterial3D.new()
	qm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	qm.vertex_color_use_as_albedo = true
	qm.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	q.material = qm
	confetti.draw_pass_1 = q
	add_child(confetti)
