extends Node
## Scene router with a short fade, parameter passing and Android back-button /
## Escape handling. Autoload "Nav". The current scene may define `on_back()`.

var params := {}
var _fade: ColorRect
var _busy := false

func _ready() -> void:
	get_tree().set_auto_accept_quit(true)
	var layer := CanvasLayer.new()
	layer.layer = 100
	add_child(layer)
	_fade = ColorRect.new()
	_fade.color = Color(0, 0, 0, 0)
	_fade.set_anchors_preset(Control.PRESET_FULL_RECT)
	_fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(_fade)

func go(path: String, p: Dictionary = {}) -> void:
	if _busy:
		return
	_busy = true
	params = p
	_fade.mouse_filter = Control.MOUSE_FILTER_STOP
	var t := create_tween()
	t.tween_property(_fade, "color:a", 1.0, 0.12)
	await t.finished
	get_tree().change_scene_to_file(path)
	await get_tree().process_frame
	var t2 := create_tween()
	t2.tween_property(_fade, "color:a", 0.0, 0.15)
	await t2.finished
	_fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_busy = false

func start_game(p: Dictionary) -> void:
	go("res://scenes/game_3d.tscn", p)

func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_GO_BACK_REQUEST:
		_back()

func _unhandled_key_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
		_back()

func _back() -> void:
	var s := get_tree().current_scene
	if s and s.has_method("on_back"):
		s.on_back()
	else:
		get_tree().quit()
