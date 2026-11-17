extends Node3D
## Orbit camera rig. Drag = rotate slightly, pinch / wheel = zoom,
## double tap = reset. Emits `tapped` for taps that were not drags.
## Mouse events (including those emulated from a single touch) drive rotate/tap;
## raw touch events track multi-touch pinch.

signal tapped(pos: Vector2)

const DEFAULT_YAW := 0.0
const DEFAULT_PITCH := 62.0   # degrees above the horizon
const DEFAULT_DIST := 17.0
const YAW_LIMIT := 30.0
const PITCH_MIN := 45.0
const PITCH_MAX := 85.0
const DIST_MIN := 12.0
const DIST_MAX := 30.0
const TAP_SLOP := 20.0
const DOUBLE_TAP_TIME := 0.3

var camera: Camera3D
var yaw := DEFAULT_YAW
var pitch := DEFAULT_PITCH
var dist := DEFAULT_DIST

var _press_pos := Vector2.ZERO
var _pressed := false
var _moved := false
var _touches := {}
var _multi := false
var _pinch_start := 0.0
var _dist_start := 0.0
var _last_tap_time := -10.0
var _last_tap_pos := Vector2.ZERO
var _reset_tween: Tween

func _ready() -> void:
	camera = Camera3D.new()
	camera.fov = 40.0
	camera.keep_aspect = Camera3D.KEEP_WIDTH   # board width always fits portrait screens
	camera.near = 0.5
	camera.far = 80.0
	add_child(camera)
	_apply()

func _apply() -> void:
	rotation = Vector3(-deg_to_rad(pitch), deg_to_rad(yaw), 0)
	camera.position = Vector3(0, 0, dist)

func reset_view(animated: bool = true) -> void:
	if _reset_tween:
		_reset_tween.kill()
	if not animated:
		yaw = DEFAULT_YAW
		pitch = DEFAULT_PITCH
		dist = DEFAULT_DIST
		_apply()
		return
	var from := Vector3(yaw, pitch, dist)
	_reset_tween = create_tween()
	_reset_tween.tween_method(func(t: float) -> void:
		var v := from.lerp(Vector3(DEFAULT_YAW, DEFAULT_PITCH, DEFAULT_DIST), t)
		yaw = v.x
		pitch = v.y
		dist = v.z
		_apply(), 0.0, 1.0, 0.3).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)

func _zoom(factor: float) -> void:
	dist = clampf(dist / factor, DIST_MIN, DIST_MAX)
	_apply()

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		if event.pressed:
			_touches[event.index] = event.position
			if _touches.size() >= 2:
				_multi = true
				_pinch_start = _pinch_distance()
				_dist_start = dist
		else:
			_touches.erase(event.index)
			if _touches.is_empty():
				_multi = false
	elif event is InputEventScreenDrag:
		_touches[event.index] = event.position
		if _touches.size() >= 2 and _pinch_start > 1.0:
			dist = clampf(_dist_start * _pinch_start / maxf(_pinch_distance(), 1.0), DIST_MIN, DIST_MAX)
			_apply()
	elif event is InputEventMagnifyGesture:
		_zoom(event.factor)
	elif event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP and event.pressed:
			_zoom(1.1)
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN and event.pressed:
			_zoom(1.0 / 1.1)
		elif event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				_pressed = true
				_moved = false
				_press_pos = event.position
			else:
				if _pressed and not _moved and not _multi:
					_handle_tap(event.position)
				_pressed = false
	elif event is InputEventMouseMotion and _pressed and not _multi:
		if not _moved and event.position.distance_to(_press_pos) > TAP_SLOP:
			_moved = true
		if _moved:
			yaw = clampf(yaw - event.relative.x * 0.15, -YAW_LIMIT, YAW_LIMIT)
			pitch = clampf(pitch + event.relative.y * 0.12, PITCH_MIN, PITCH_MAX)
			_apply()

func _pinch_distance() -> float:
	var pts := _touches.values()
	return (pts[0] as Vector2).distance_to(pts[1]) if pts.size() >= 2 else 0.0

func _handle_tap(pos: Vector2) -> void:
	var now := Time.get_ticks_msec() / 1000.0
	if now - _last_tap_time < DOUBLE_TAP_TIME and pos.distance_to(_last_tap_pos) < TAP_SLOP * 3.0:
		_last_tap_time = -10.0
		reset_view()
		return
	_last_tap_time = now
	_last_tap_pos = pos
	tapped.emit(pos)
