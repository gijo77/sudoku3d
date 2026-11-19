extends Control
## Rewards: rank and XP, the 7-day daily streak, medals and rank-gated theme unlocks.

const UI := preload("res://scripts/ui/ui_kit.gd")
const Glyph := preload("res://scripts/ui/glyph_icon.gd")
const RewardsData := preload("res://scripts/game/rewards_data.gd")

const MEDAL_GLYPHS := {"winner": "trophy", "flawless": "shield", "streak": "flame", "cube": "cube", "speed": "bolt", "expert": "star"}

func _ready() -> void:
	var v := UI.make_screen(self)
	v.add_theme_constant_override("separation", 26)
	v.add_child(UI.heading("Rewards", 84))
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	v.add_child(scroll)
	var body := VBoxContainer.new()
	body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	body.add_theme_constant_override("separation", 30)
	scroll.add_child(body)
	body.add_child(_rank_card())
	body.add_child(_streak_section())
	body.add_child(_medals_section())
	body.add_child(_unlocks_section())
	v.add_child(UI.button("Back", on_back))

func _section_title(text: String, right: String = "") -> Control:
	var h := HBoxContainer.new()
	var l := UI.label(text, 52)
	l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	h.add_child(l)
	if right != "":
		var r := UI.label(right, 34, HORIZONTAL_ALIGNMENT_RIGHT)
		r.add_theme_color_override("font_color", ThemeManager.palette["dim"])
		r.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		h.add_child(r)
	return h

# --- Rank --------------------------------------------------------------------

func _rank_card() -> Control:
	var d = Rewards.data
	var pr: Dictionary = d.progress()
	var panel := PanelContainer.new()
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 36)
	panel.add_child(row)
	var ring := Control.new()
	ring.custom_minimum_size = Vector2(240, 240)
	var frac := float(pr["into"]) / float(pr["need"])
	var accent: Color = ThemeManager.palette["accent"]
	var track: Color = ThemeManager.palette["bg"].darkened(0.08)
	var txt: Color = ThemeManager.palette["text"]
	var dim: Color = ThemeManager.palette["dim"]
	var rank_n: int = pr["rank"]
	ring.draw.connect(func() -> void:
		var c: Vector2 = ring.size / 2.0
		ring.draw_arc(c, 100.0, 0.0, TAU, 64, track, 26.0, true)
		if frac > 0.0:
			ring.draw_arc(c, 100.0, -PI / 2.0, -PI / 2.0 + TAU * frac, 64, accent, 26.0, true)
		var f := ring.get_theme_default_font()
		var big := str(rank_n)
		var w := f.get_string_size(big, HORIZONTAL_ALIGNMENT_LEFT, -1, 84).x
		ring.draw_string(f, Vector2(c.x - w / 2.0, c.y + 22.0), big, HORIZONTAL_ALIGNMENT_LEFT, -1, 84, txt)
		var small := "RANK"
		var w2 := f.get_string_size(small, HORIZONTAL_ALIGNMENT_LEFT, -1, 30).x
		ring.draw_string(f, Vector2(c.x - w2 / 2.0, c.y + 62.0), small, HORIZONTAL_ALIGNMENT_LEFT, -1, 30, dim))
	row.add_child(ring)
	var col := VBoxContainer.new()
	col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	col.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	col.add_theme_constant_override("separation", 8)
	col.add_child(UI.label(RewardsData.title_for_rank(pr["rank"]), 56))
	var xp_l := UI.label("%d / %d XP to Rank %d" % [pr["into"], pr["need"], int(pr["rank"]) + 1], 36)
	xp_l.add_theme_color_override("font_color", dim)
	col.add_child(xp_l)
	var next := _next_unlock(int(pr["rank"]))
	if next != "":
		var n := UI.label(next, 34)
		n.add_theme_color_override("font_color", accent)
		n.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		col.add_child(n)
	row.add_child(col)
	return panel

func _next_unlock(rank: int) -> String:
	var best_rank := 9999
	var best_key := ""
	for k in RewardsData.THEME_RANKS:
		var need: int = RewardsData.THEME_RANKS[k]
		if need > rank and need < best_rank:
			best_rank = need
			best_key = k
	if best_key == "":
		return "All themes unlocked"
	return "Rank %d unlocks the %s theme" % [best_rank, ThemeManager.PALETTES[best_key]["label"]]

# --- Streak ------------------------------------------------------------------

func _streak_section() -> Control:
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 16)
	var streak: int = Stats.data.daily_streak(UI.today_key())
	v.add_child(_section_title("Daily streak", "%d day(s)" % streak))
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	v.add_child(row)
	var today_unix := int(Time.get_unix_time_from_datetime_string(UI.today_key()))
	var weekdays := ["Su", "Mo", "Tu", "We", "Th", "Fr", "Sa"]
	for i in range(6, -1, -1):
		var unix := today_unix - i * 86400
		var key := Time.get_date_string_from_unix_time(unix)
		var wd: int = Time.get_datetime_dict_from_unix_time(unix)["weekday"]
		var done: bool = Stats.data.daily_done(key)
		var is_today := i == 0
		var cell := PanelContainer.new()
		cell.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var sb := ThemeManager.make_box(ThemeManager.palette["panel"], 22, 10, false)
		if is_today:
			sb.border_width_left = 4
			sb.border_width_right = 4
			sb.border_width_top = 4
			sb.border_width_bottom = 4
			sb.border_color = ThemeManager.palette["accent"]
		cell.add_theme_stylebox_override("panel", sb)
		var col := VBoxContainer.new()
		col.add_theme_constant_override("separation", 6)
		col.alignment = BoxContainer.ALIGNMENT_CENTER
		cell.add_child(col)
		var dl := UI.label(weekdays[wd], 28, HORIZONTAL_ALIGNMENT_CENTER)
		dl.add_theme_color_override("font_color", ThemeManager.palette["dim"])
		col.add_child(dl)
		var dot: Control = Glyph.make("flame", 56, Color("FF8A4C") if done else ThemeManager.palette["dim"].lerp(ThemeManager.palette["panel"], 0.6))
		dot.filled = done
		dot.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		col.add_child(dot)
		row.add_child(cell)
	var tip := UI.label("Finish today's puzzle for +50 XP. Reach 3, 7 and 30 days for Warm Streak medals.", 32)
	tip.add_theme_color_override("font_color", ThemeManager.palette["dim"])
	tip.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	v.add_child(tip)
	return v

# --- Medals ------------------------------------------------------------------

func _medals_section() -> Control:
	var d = Rewards.data
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 16)
	v.add_child(_section_title("Medals", "%d of %d earned" % [d.medals_earned(), RewardsData.MEDALS.size()]))
	var grid := GridContainer.new()
	grid.columns = 3
	grid.add_theme_constant_override("h_separation", 12)
	grid.add_theme_constant_override("v_separation", 30)
	v.add_child(grid)
	for m in RewardsData.MEDALS:
		var tier: int = d.medal_tier(m["id"])
		var cell := VBoxContainer.new()
		cell.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		cell.add_theme_constant_override("separation", 6)
		var icon: Control = Glyph.make_medal(MEDAL_GLYPHS[m["id"]], tier, 190)
		icon.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		cell.add_child(icon)
		cell.add_child(UI.label(m["name"], 34, HORIZONTAL_ALIGNMENT_CENTER))
		var sub := UI.label(_medal_sub(m, tier), 28, HORIZONTAL_ALIGNMENT_CENTER)
		sub.add_theme_color_override("font_color", ThemeManager.palette["dim"])
		sub.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		cell.add_child(sub)
		grid.add_child(cell)
	return v

func _medal_sub(m: Dictionary, tier: int) -> String:
	var count: int = int(Rewards.data.counters[m["counter"]])
	if tier >= 3:
		return "Gold · %d" % count
	var goal: int = int(m["tiers"][tier])
	var next_name: String = RewardsData.TIER_NAMES[tier + 1]
	return "%s %d / %d" % [next_name, count, goal]

# --- Unlocks -----------------------------------------------------------------

func _unlocks_section() -> Control:
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 16)
	v.add_child(_section_title("Theme unlocks"))
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	v.add_child(row)
	for key in ThemeManager.PALETTES:
		var p: Dictionary = ThemeManager.PALETTES[key]
		var open: bool = Rewards.data.theme_unlocked(key)
		var cell := VBoxContainer.new()
		cell.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		cell.add_theme_constant_override("separation", 6)
		var tile := PanelContainer.new()
		tile.custom_minimum_size = Vector2(0, 150)
		var sb := ThemeManager.make_box(p["sel"] if open else p["tile"].darkened(0.25), 24, 8)
		tile.add_theme_stylebox_override("panel", sb)
		var inner: Control
		if open:
			inner = UI.label("5", 64, HORIZONTAL_ALIGNMENT_CENTER)
			inner.add_theme_color_override("font_color", p["plate"])
			inner.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		else:
			inner = Glyph.make("lock", 56, Color(1, 1, 1, 0.8))
			inner.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
			inner.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		tile.add_child(inner)
		cell.add_child(tile)
		cell.add_child(UI.label(p["label"], 28, HORIZONTAL_ALIGNMENT_CENTER))
		var req := UI.label("Open" if open else "Rank %d" % RewardsData.theme_rank(key), 26, HORIZONTAL_ALIGNMENT_CENTER)
		req.add_theme_color_override("font_color", ThemeManager.palette["dim"])
		cell.add_child(req)
		row.add_child(cell)
	return v

func on_back() -> void:
	Nav.go("res://scenes/main_menu.tscn")
