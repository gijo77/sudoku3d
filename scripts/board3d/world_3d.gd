extends Node3D
## The 3D world rendered inside a SubViewport: environment, light with soft
## shadows, orbit camera and board. Emits `cell_tapped` after picking.

signal cell_tapped(idx: int)

const Board := preload("res://scripts/board3d/board_view_3d.gd")
const Orbit := preload("res://scripts/board3d/orbit_camera.gd")


var board
var rig

func _ready() -> void:
	var BG_COLOR: Color = ThemeManager.palette["bg"]
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = BG_COLOR
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(1, 1, 1)
	env.ambient_light_energy = 0.45
	var we := WorldEnvironment.new()
	we.environment = env
	add_child(we)

	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-58, -30, 0)
	sun.light_energy = 0.7
	sun.shadow_enabled = true
	sun.shadow_blur = 1.6
	sun.directional_shadow_mode = DirectionalLight3D.SHADOW_ORTHOGONAL
	sun.directional_shadow_max_distance = 40.0
	add_child(sun)

	# Floor that catches the board's soft shadow, same colour as the background.
	var floor_mesh := MeshInstance3D.new()
	var plane := PlaneMesh.new()
	plane.size = Vector2(80, 80)
	floor_mesh.mesh = plane
	floor_mesh.position.y = -0.55
	var fm := StandardMaterial3D.new()
	fm.albedo_color = BG_COLOR * 0.95
	fm.roughness = 1.0
	floor_mesh.material_override = fm
	add_child(floor_mesh)

	board = Board.new()
	add_child(board)
	rig = Orbit.new()
	add_child(rig)
	rig.tapped.connect(_on_tapped)

func _on_tapped(pos: Vector2) -> void:
	var idx: int = board.pick(rig.camera, pos)
	if idx >= 0:
		cell_tapped.emit(idx)

# --- View API shared with the 2D board (forwarded to the board) -------------

func set_state(model, selected: int) -> void:
	board.set_state(model, selected)

func play_result(result: int, idx: int) -> void:
	board.play_result(result, idx)

func play_wave(cells: Array, origin: int) -> void:
	board.play_wave(cells, origin)

func play_win() -> void:
	board.play_win()
