extends Node3D
## One 3D Sudoku tile: a box with an embossed (extruded) digit on top and
## lazily-created pencil notes. Includes pop / shake / wave animations.

const Layout := preload("res://scripts/board3d/board_layout.gd")
const Assets := preload("res://scripts/board3d/board_assets.gd")

var idx := 0
var _assets
var _box: MeshInstance3D
var _num: MeshInstance3D
var _note_nodes: Array = []
var _base := Vector3.ZERO
var _tween_y: Tween
var _tween_x: Tween
var _lift := 0.0   # selected tile is raised; digit/notes follow it
var _bg := -1
var _value := -1
var _kind := -1
var _notes := -1

func setup(cell: int, assets, pos: Vector3) -> void:
	idx = cell
	_assets = assets
	_base = pos
	position = _base
	_box = MeshInstance3D.new()
	_box.mesh = assets.tile_mesh
	_box.material_override = assets.tile_mats[Assets.Bg.NORMAL]
	add_child(_box)
	_num = MeshInstance3D.new()
	_num.rotation_degrees = Vector3(-90, 0, 0)   # lie flat, readable from +Z
	_num.position.y = Layout.TOP_Y + Assets.DIGIT_DEPTH / 2.0
	_num.visible = false
	add_child(_num)

## Updates visuals; does nothing for unchanged state (cheap to call every refresh).
func apply(bg: int, value: int, kind: int, notes: int) -> void:
	if bg != _bg:
		_bg = bg
		_box.material_override = _assets.tile_mats[bg]
		_lift = 0.05 if bg == Assets.Bg.SELECTED else 0.0
		_box.position.y = _lift
		_num.position.y = Layout.TOP_Y + Assets.DIGIT_DEPTH / 2.0 + _lift
		for n in _note_nodes:
			n.position.y = Layout.TOP_Y + 0.01 + _lift
	if value != _value or kind != _kind:
		_value = value
		_kind = kind
		_num.visible = value != 0
		if value != 0:
			_num.mesh = _assets.digit_meshes[value]
			_num.material_override = _assets.text_mats[kind]
	if notes != _notes:
		_notes = notes
		_update_notes()

func _update_notes() -> void:
	if _notes == 0 and _note_nodes.is_empty():
		return
	if _note_nodes.is_empty():
		for d in range(1, 10):
			var n := MeshInstance3D.new()
			n.mesh = _assets.note_meshes[d]
			n.material_override = _assets.text_mats[Assets.Kind.NOTE]
			n.rotation_degrees = Vector3(-90, 0, 0)
			n.position = Vector3(((d - 1) % 3 - 1) * 0.29, Layout.TOP_Y + 0.01 + _lift, ((d - 1) / 3 - 1) * 0.29)
			add_child(n)
			_note_nodes.append(n)
	for d in 9:
		_note_nodes[d].visible = (_notes & (1 << d)) != 0 and _value == 0

# --- animations ------------------------------------------------------------

## Digit pops in with an overshoot while the tile hops up.
func pop() -> void:
	_num.scale = Vector3.ZERO
	var t := create_tween()
	t.tween_property(_num, "scale", Vector3.ONE, 0.28).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_hop(0.18, 0.0)

## Quick left-right shake for a wrong digit.
func shake() -> void:
	if _tween_x:
		_tween_x.kill()
	position.x = _base.x
	_tween_x = create_tween()
	for s in [0.14, -0.12, 0.08, -0.05, 0.0]:
		_tween_x.tween_property(self, "position:x", _base.x + s, 0.05)

## Tile rises and settles after `delay` seconds (used for completion waves).
func wave(delay: float) -> void:
	_hop(0.35, delay)

func _hop(height: float, delay: float) -> void:
	if _tween_y:
		_tween_y.kill()
	position.y = _base.y
	_tween_y = create_tween()
	if delay > 0.0:
		_tween_y.tween_interval(delay)
	_tween_y.tween_property(self, "position:y", _base.y + height, 0.12).set_ease(Tween.EASE_OUT)
	_tween_y.tween_property(self, "position:y", _base.y, 0.22).set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)
