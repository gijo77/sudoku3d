extends RefCounted
## Shared meshes and materials for the 3D board (created once, reused by all 81
## tiles to keep memory and draw state small on mobile GPUs).

const Layout := preload("res://scripts/board3d/board_layout.gd")

enum Bg { NORMAL, PEER, SAME, SELECTED }
enum Kind { GIVEN, PLAYER, WRONG, NOTE }

const DIGIT_DEPTH := 0.06

var tile_mesh := BoxMesh.new()
var digit_meshes: Array = [null]   # index 1..9, extruded (embossed) digits
var note_meshes: Array = [null]    # index 1..9, small pencil-note digits
var tile_mats: Array = []          # by Bg
var text_mats: Array = []          # by Kind

func _init() -> void:
	tile_mesh.size = Vector3(Layout.TILE, Layout.TILE_H, Layout.TILE)
	for d in range(1, 10):
		digit_meshes.append(_text_mesh(str(d), 120, 0.0065, DIGIT_DEPTH))
		note_meshes.append(_text_mesh(str(d), 120, 0.0032, 0.02))
	var pal: Dictionary = ThemeManager.palette
	tile_mats = [
		_mat(pal["tile"], 0.55),
		_mat(pal["peer"], 0.55),
		_mat(pal["same"], 0.55),
		_mat(pal["sel"], 0.45),
	]
	text_mats = [
		_mat(pal["given"], 0.4),
		_mat(pal["player"], 0.4),
		_mat(pal["wrong"], 0.4),
		_mat(pal["note"], 0.6),
	]

func _text_mesh(text: String, font_size: int, pixel_size: float, depth: float) -> TextMesh:
	var t := TextMesh.new()
	t.text = text
	t.font = ThemeDB.fallback_font
	t.font_size = font_size
	t.pixel_size = pixel_size
	t.depth = depth
	t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	t.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	return t

func _mat(color: Color, roughness: float) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = color
	m.roughness = roughness
	return m
