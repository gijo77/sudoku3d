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
var sel_text_mat: StandardMaterial3D   # digit on the selected tile
var sel_wrong_mat: StandardMaterial3D  # selected tile holding a wrong digit

func _init() -> void:
	tile_mesh.size = Vector3(Layout.TILE, Layout.TILE_H, Layout.TILE)
	for d in range(1, 10):
		digit_meshes.append(_text_mesh(str(d), 120, 0.0065, DIGIT_DEPTH))
		note_meshes.append(_text_mesh(str(d), 120, 0.0032, 0.02))
	var pal: Dictionary = ThemeManager.palette
	# Neon look: lit states and player digits emit their colour (bloom picks it
	# up when glow is on). Light theme keeps emission low so it stays crisp.
	var e := 0.25 if ThemeManager.is_light() else 1.0
	tile_mats = [
		_mat(pal["tile"], 0.45, 0.0, 0.2),
		_mat(pal["peer"], 0.45, 0.25 * e),
		_mat(pal["same"], 0.45, 0.45 * e),
		_mat(pal["sel"], 0.35, 0.85 * e),
	]
	text_mats = [
		_mat(pal["given"], 0.4, 0.12 * e),
		_mat(pal["player"], 0.4, 0.9 * e),
		_mat(pal["wrong"], 0.4, 1.0 * e),
		_mat(pal["note"], 0.6),
	]
	# digits on the selected (accent-filled) tile need dark ink to stay readable
	sel_text_mat = _mat(pal["ink"], 0.4)
	sel_wrong_mat = _mat(pal["wrong"], 0.35, 0.85 * e)

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

func _mat(color: Color, roughness: float, emission: float = 0.0, metallic: float = 0.0) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = color
	m.roughness = roughness
	m.metallic = metallic
	if emission > 0.0:
		m.emission_enabled = true
		m.emission = color
		m.emission_energy_multiplier = emission
	return m

## Thin glowing bar material (box dividers and the board rim).
func line_mat() -> StandardMaterial3D:
	var a: Color = ThemeManager.palette["accent"]
	return _mat(a, 0.3, 0.3 if ThemeManager.is_light() else 1.6)
