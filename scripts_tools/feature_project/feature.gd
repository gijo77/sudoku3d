extends Control
## Draws the feature graphic: background art (from ../../store/feature_art_raw.png) + title text.

func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	var img := Image.load_from_file(ProjectSettings.globalize_path("res://") + "../../store/feature_art_raw.png")
	var bg := TextureRect.new()
	bg.texture = ImageTexture.create_from_image(img)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	add_child(bg)
	_label("Sudoku 3D", 100, Vector2(56, 128), Color.WHITE)
	_label("Classic 9x9 and 3D Cube puzzles", 30, Vector2(60, 262), Color(1, 1, 1, 0.92))
	_label("Offline  •  No ads  •  Free", 28, Vector2(60, 318), Color(1, 1, 1, 0.75))

func _label(text: String, size: int, pos: Vector2, color: Color) -> void:
	var l := Label.new()
	l.text = text
	l.position = pos
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	add_child(l)
