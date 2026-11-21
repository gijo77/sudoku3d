extends Control
## Statistics: Classic / Cube switch, KPI tiles, win rate and best time per
## level, and the last 28 days of daily puzzles.

const UI := preload("res://scripts/ui/ui_kit.gd")
const Generator := preload("res://scripts/logic/generator.gd")
const LEVEL_COLORS := [Color("4BE3A0"), Color("3EE6FF"), Color("9B8CFF"), Color("FF6FA8")]

var cube := false
var _body: VBoxContainer

func _ready() -> void:
	var seg := UI.segmented(["Classic", "Cube"], 0, _on_kind, 96)
	seg.custom_minimum_size.x = 420
	var v := UI.make_screen(self)
	v.add_child(UI.header("Statistics", "Performance log", Callable(), seg))
	_body = UI.vbox(36)
	v.add_child(_body)
	v.add_child(UI.spacer())
	v.add_child(UI.nav_dock("Stats"))
	_fill()

func _on_kind(i: int) -> void:
	cube = i == 1
	_fill()

func _fill() -> void:
	for c in _body.get_children():
		c.queue_free()
	var s = Stats.data
	var p: Dictionary = ThemeManager.palette
	var off := 10 if cube else 0
	var played := 0
	var won := 0
	for d in Generator.NAMES:
		played += s.played(d + off)
		won += s.wins(d + off)
	var kpis := UI.hbox(28)
	kpis.add_child(UI.stat_tile(str(played), "Played"))
	kpis.add_child(UI.stat_tile("%d%%" % int(round(100.0 * won / played)) if played > 0 else "-", "Win rate", p["accent"]))
	kpis.add_child(UI.stat_tile(str(s.daily_streak(UI.today_key())), "Day streak", p["reward"]))
	_body.add_child(kpis)

	var table := UI.card(40)
	var tv := UI.vbox(0)
	table.add_child(tv)
	tv.add_child(_row(UI.mono("Level", 24), UI.mono("Win rate", 24), UI.mono("Best", 24, Color(0, 0, 0, 0), HORIZONTAL_ALIGNMENT_RIGHT), 70))
	for d in Generator.NAMES:
		var n: int = s.played(d + off)
		var rate: float = s.win_rate(d + off)
		var best: float = s.best_time(d + off)
		var name_col := UI.vbox(2)
		name_col.add_child(UI.title_label(Generator.NAMES[d], 42))
		name_col.add_child(UI.dim("%d played" % n, 30))
		var bar_row := UI.hbox(22)
		var b: Control = UI.bar(rate if n > 0 else 0.0, LEVEL_COLORS[d], 16)
		b.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		bar_row.add_child(b)
		var pct := UI.title_label("%d%%" % int(round(rate * 100.0)) if n > 0 else "-", 36, HORIZONTAL_ALIGNMENT_RIGHT)
		pct.custom_minimum_size.x = 110
		bar_row.add_child(pct)
		var bt := UI.title_label(UI.fmt_time(best) if best >= 0.0 else "-", 42, HORIZONTAL_ALIGNMENT_RIGHT)
		tv.add_child(_divider())
		tv.add_child(_row(name_col, bar_row, bt, 140))
	_body.add_child(table)
	_body.add_child(_daily_card())

func _row(a: Control, b: Control, c: Control, h: int) -> Control:
	var r := UI.hbox(28)
	r.custom_minimum_size.y = h
	a.custom_minimum_size.x = 215
	a.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	b.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	c.custom_minimum_size.x = 170
	c.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	r.add_child(a)
	r.add_child(b)
	r.add_child(c)
	return r

func _divider() -> Control:
	var c := ColorRect.new()
	c.color = Color(ThemeManager.palette["line"], 0.12)
	c.custom_minimum_size = Vector2(0, 2)
	c.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return c

func _daily_card() -> Control:
	var s = Stats.data
	var p: Dictionary = ThemeManager.palette
	var card := UI.card(40)
	var v := UI.vbox(28)
	card.add_child(v)
	var today := int(Time.get_unix_time_from_datetime_string(UI.today_key()))
	var solved := 0
	var days: Array = []
	for i in range(27, -1, -1):
		var key := Time.get_date_string_from_unix_time(today - i * 86400)
		var done: bool = s.daily_done(key)
		days.append(done)
		if done:
			solved += 1
	var head := UI.hbox(10)
	var t := UI.title_label("Daily puzzles", 44)
	t.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	head.add_child(t)
	head.add_child(UI.mono("Last 28 days · %d solved" % solved, 24))
	v.add_child(head)
	var streak: int = s.daily_streak(UI.today_key())
	var cells := Control.new()
	cells.custom_minimum_size = Vector2(0, 122)
	cells.draw.connect(func() -> void:
		var gap := 11.0
		var w := (cells.size.x - gap * 13.0) / 14.0
		for i in 28:
			var x := (i % 14) * (w + gap)
			var y := (i / 14) * (w + gap)
			var recent := i >= 28 - streak
			var c: Color = Color(p["line"], 0.14)
			if days[i]:
				c = p["reward"] if recent else Color(p["accent"], 0.75)
			var sb := StyleBoxFlat.new()
			sb.bg_color = c
			sb.set_corner_radius_all(10)
			if days[i] and recent:
				sb.shadow_color = Color(p["reward"], 0.5)
				sb.shadow_size = 10
			cells.draw_style_box(sb, Rect2(x, y, w, w)))
	v.add_child(cells)
	return card

func on_back() -> void:
	Nav.go("res://scenes/main_menu.tscn")
