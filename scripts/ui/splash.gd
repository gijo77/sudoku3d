extends Control
## Splash screen: title fades in/out, then goes to the main menu. Tap to skip.

func _ready() -> void:
	var v := preload("res://scripts/ui/ui_kit.gd").make_screen(self)
	v.alignment = BoxContainer.ALIGNMENT_CENTER
	var title := preload("res://scripts/ui/ui_kit.gd").heading("Sudoku 3D", 130)
	title.modulate.a = 0.0
	v.add_child(title)
	var t := create_tween()
	t.tween_property(title, "modulate:a", 1.0, 0.6)
	t.tween_interval(0.7)
	t.tween_callback(_done)

func _done() -> void:
	Nav.go("res://scenes/main_menu.tscn")

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		_done()

func on_back() -> void:
	pass
