extends Control
## Splash: glowing wireframe cube, title and a short loading bar, then the main
## menu. Tap to skip.

const UI := preload("res://scripts/ui/ui_kit.gd")
const IsoArt := preload("res://scripts/ui/iso_art.gd")

var _fill := 0.0
var _bar

func _ready() -> void:
	var v := UI.make_screen(self)
	var bg: Control = get_child(0)
	var p: Dictionary = ThemeManager.palette
	bg.add_glow(Vector2(0.5, 0.42), 700.0, Color(p["accent"], 0.18))
	v.alignment = BoxContainer.ALIGNMENT_CENTER
	v.add_theme_constant_override("separation", 40)
	v.add_child(UI.spacer())
	var cube: Control = IsoArt.make("cube", 0, 560)
	v.add_child(cube)
	var name_row := UI.hbox(0)
	name_row.alignment = BoxContainer.ALIGNMENT_CENTER
	name_row.add_child(UI.title_label("SUDOKU", 120, HORIZONTAL_ALIGNMENT_CENTER))
	name_row.add_child(UI.title_label(" 3D", 120, HORIZONTAL_ALIGNMENT_CENTER, p["accent"]))
	v.add_child(name_row)
	v.add_child(UI.mono("Logic in every dimension", 30, Color(0, 0, 0, 0), HORIZONTAL_ALIGNMENT_CENTER))
	v.add_child(UI.spacer())
	var m := MarginContainer.new()
	m.add_theme_constant_override("margin_left", 140)
	m.add_theme_constant_override("margin_right", 140)
	var col := UI.vbox(22)
	col.add_child(UI.mono("Building grid", 26, p["accent"]))
	_bar = UI.bar(0.0, p["accent"], 12)
	col.add_child(_bar)
	m.add_child(col)
	v.add_child(m)
	v.add_child(UI.mono("Tap to skip · Offline", 26, Color(0, 0, 0, 0), HORIZONTAL_ALIGNMENT_CENTER))
	var t := create_tween()
	t.tween_method(_set_fill, 0.0, 1.0, 1.2)
	t.tween_interval(0.15)
	t.tween_callback(_done)
	cube.modulate.a = 0.0
	create_tween().tween_property(cube, "modulate:a", 1.0, 0.5)

func _set_fill(f: float) -> void:
	_fill = f
	_bar.frac = f

func _done() -> void:
	Nav.go("res://scenes/main_menu.tscn")

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		_done()

func on_back() -> void:
	pass
