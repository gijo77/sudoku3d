extends "res://tests/test_case.gd"

const Layout := preload("res://scripts/board3d/board_layout.gd")

func test_cell_center_roundtrip() -> void:
	for i in 81:
		var c := Layout.cell_center(i)
		assert_eq(Layout.cell_at(c.x, c.y), i, "cell %d" % i)

func test_board_is_symmetric() -> void:
	assert_true(absf(Layout.axis_pos(0) + Layout.axis_pos(8)) < 0.0001, "centered on origin")
	assert_true(absf(Layout.axis_pos(4)) < 0.0001, "middle cell at 0")

func test_outside_board_misses() -> void:
	assert_eq(Layout.cell_at(100.0, 0.0), -1, "far right")
	assert_eq(Layout.cell_at(0.0, -100.0), -1, "far up")
	assert_eq(Layout.cell_at(Layout.extent() / 2.0 + 0.5, 0.0), -1, "just outside")

func test_box_gaps_are_wider() -> void:
	var within := Layout.axis_pos(1) - Layout.axis_pos(0)
	var across := Layout.axis_pos(3) - Layout.axis_pos(2)
	assert_true(across > within, "gap between boxes is wider")
