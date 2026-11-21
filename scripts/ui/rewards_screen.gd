extends Control
## Rewards: rank ring and XP, the 7-day daily streak, medals and rank-gated
## theme unlocks.

const UI := preload("res://scripts/ui/ui_kit.gd")
const Glyph := preload("res://scripts/ui/glyph_icon.gd")
const Ring := preload("res://scripts/ui/ring.gd")
const RewardsData := preload("res://scripts/game/rewards_data.gd")

const MEDAL_GLYPHS := {"winner": "trophy", "flawless": "shield", "streak": "flame", "cube": "cube", "speed": "bolt", "expert": "star"}
## Neon swatch shown for each theme (face colour of its tile).
const THEME_SWATCH := {"light": Color("E9EEFA"), "dark": Color("3EE6FF"), "ocean": Color("21C7D9"), "forest": Color("4BE3A0"), "sunset": Color("FF8A4C")}

func _ready() -> void:
	var v := UI.make_screen(self, "Rewards", "Progress")
	v.add_theme_constant_override("separation", 30)
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	v.add_child(scroll)
	var pad := MarginContainer.new()
	pad.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	pad.add_theme_constant_override("margin_right", 26)
	scroll.add_child(pad)
	var body := UI.vbox(40)
	body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	pad.add_child(body)
	if PlayGames.available:
		body.add_child(_play_games_card())
	body.add_child(_rank_card())
	body.add_child(_streak_section())
	body.add_child(_medals_section())
	body.add_child(_unlocks_section())
	v.add_child(UI.nav_dock("Rewards"))
	PlayGames.status_changed.connect(_on_play_games_status)   # bound method: auto-disconnects when this screen is freed

## Google Play Games: sign-in state, plus Achievements / Leaderboards when signed in.
func _play_games_card() -> Control:
	var p: Dictionary = ThemeManager.palette
	var card := UI.card(36)
	var v := UI.vbox(24)
	card.add_child(v)
	var head := UI.hbox(28)
	var ic: Control = Glyph.make("trophy", 56, p["accent"])
	ic.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	head.add_child(ic)
	var col := UI.vbox(4)
	col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	col.add_child(UI.title_label("Google Play Games", 42))
	col.add_child(UI.mono("Signed in · progress backed up" if PlayGames.signed_in else "Not signed in", 23,
		p["accent"] if PlayGames.signed_in else Color(0, 0, 0, 0)))
	head.add_child(col)
	v.add_child(head)
	var row := UI.hbox(22)
	if PlayGames.signed_in:
		var a := UI.button("Achievements", PlayGames.show_achievements, 121)
		var l := UI.button("Leaderboards", PlayGames.show_leaderboards, 121)
		for b in [a, l]:
			b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			b.add_theme_font_size_override("font_size", 36)
			row.add_child(b)
	else:
		var s := UI.primary("Sign in", PlayGames.sign_in, 121)
		s.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(s)
	v.add_child(row)
	return card

func _section_title(text: String, right: String = "", right_col: Color = Color(0, 0, 0, 0)) -> Control:
	var h := UI.hbox(10)
	var l := UI.title_label(text, 44)
	l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	h.add_child(l)
	if right != "":
		var r := UI.mono(right, 25, right_col)
		r.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		h.add_child(r)
	return h

func _rank_card() -> Control:
	var p: Dictionary = ThemeManager.palette
	var pr: Dictionary = Rewards.data.progress()
	var card := UI.card(40, Color(p["accent"], 0.4))
	var row := UI.hbox(44)
	card.add_child(row)
	row.add_child(Ring.make(250, float(pr["into"]) / float(pr["need"]), str(pr["rank"]), "RANK"))
	var col := UI.vbox(12)
	col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	col.alignment = BoxContainer.ALIGNMENT_CENTER
	col.add_child(UI.title_label(RewardsData.title_for_rank(pr["rank"]), 55))
	col.add_child(UI.dim("%d / %d XP to Rank %d" % [pr["into"], pr["need"], int(pr["rank"]) + 1], 33))
	col.add_child(UI.mono(_next_unlock(int(pr["rank"])), 24, p["accent"]))
	row.add_child(col)
	return card

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
	return "Rank %d unlocks %s" % [best_rank, ThemeManager.PALETTES[best_key]["label"]]

func _streak_section() -> Control:
	var p: Dictionary = ThemeManager.palette
	var v := UI.vbox(20)
	var streak: int = Stats.data.daily_streak(UI.today_key())
	v.add_child(_section_title("Daily streak", "%d %s" % [streak, "day" if streak == 1 else "days"], p["reward"]))
	var row := UI.hbox(16)
	v.add_child(row)
	var today_unix := int(Time.get_unix_time_from_datetime_string(UI.today_key()))
	var weekdays := ["Su", "Mo", "Tu", "We", "Th", "Fr", "Sa"]
	for i in range(6, -1, -1):
		var unix := today_unix - i * 86400
		var key := Time.get_date_string_from_unix_time(unix)
		var wd: int = Time.get_datetime_dict_from_unix_time(unix)["weekday"]
		var done: bool = Stats.data.daily_done(key)
		var cell := PanelContainer.new()
		cell.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var sb := ThemeManager.glass(33, 20, Color(p["accent"], 0.9) if i == 0 else Color(0, 0, 0, 0), Color(p["accent"], 0.3) if i == 0 else Color(0, 0, 0, 0))
		cell.add_theme_stylebox_override("panel", sb)
		var col := UI.vbox(10)
		col.alignment = BoxContainer.ALIGNMENT_CENTER
		cell.add_child(col)
		col.add_child(UI.mono(weekdays[wd], 24, Color(0, 0, 0, 0), HORIZONTAL_ALIGNMENT_CENTER))
		var fl: Control = Glyph.make("flame", 56, p["reward"] if done else Color(p["line"], 0.35))
		fl.filled = done
		fl.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		col.add_child(fl)
		row.add_child(cell)
	var tip := UI.dim("Finish today's puzzle for +50 XP. Reach 3, 7 and 30 days for Warm Streak medals.", 32)
	v.add_child(tip)
	return v

func _medals_section() -> Control:
	var d = Rewards.data
	var v := UI.vbox(20)
	v.add_child(_section_title("Medals", "%d of %d earned" % [d.medals_earned(), RewardsData.MEDALS.size()]))
	var grid := GridContainer.new()
	grid.columns = 3
	grid.add_theme_constant_override("h_separation", 22)
	grid.add_theme_constant_override("v_separation", 22)
	v.add_child(grid)
	for m in RewardsData.MEDALS:
		var tier: int = d.medal_tier(m["id"])
		var card := UI.card(24)
		card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var cell := UI.vbox(10)
		card.add_child(cell)
		var icon: Control = Glyph.make_medal(MEDAL_GLYPHS[m["id"]], tier, 160)
		icon.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		cell.add_child(icon)
		cell.add_child(UI.label(m["name"], 33, HORIZONTAL_ALIGNMENT_CENTER))
		cell.add_child(UI.mono(_medal_sub(m, tier), 22, Color(0, 0, 0, 0), HORIZONTAL_ALIGNMENT_CENTER))
		grid.add_child(card)
	return v

func _medal_sub(m: Dictionary, tier: int) -> String:
	var count: int = int(Rewards.data.counters[m["counter"]])
	if tier >= 3:
		return "Gold · %d" % count
	return "%s %d/%d" % [RewardsData.TIER_NAMES[tier + 1], count, int(m["tiers"][tier])]

func _unlocks_section() -> Control:
	var p: Dictionary = ThemeManager.palette
	var v := UI.vbox(20)
	v.add_child(_section_title("Theme unlocks"))
	var row := UI.hbox(18)
	v.add_child(row)
	for key in ThemeManager.PALETTES:
		var open: bool = Rewards.data.theme_unlocked(key)
		var cur: bool = key == Settings.theme_name
		var cell := UI.vbox(10)
		cell.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var tile := PanelContainer.new()
		tile.custom_minimum_size = Vector2(0, 160)
		var sb: StyleBoxFlat
		if open:
			sb = ThemeManager.fill(THEME_SWATCH[key], 33, 0, cur)
			if cur:
				sb.set_border_width_all(5)
				sb.border_color = Color.WHITE
		else:
			sb = ThemeManager.glass(33, 0, Color(p["line"], 0.35))
		tile.add_theme_stylebox_override("panel", sb)
		var inner: Control
		if open:
			inner = UI.title_label("5", 60, HORIZONTAL_ALIGNMENT_CENTER, ThemeManager.PALETTES[key]["ink"] if key != "light" else Color("2457D6"))
		else:
			inner = Glyph.make("lock", 52, p["dim"])
			inner.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		inner.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		tile.add_child(inner)
		cell.add_child(tile)
		cell.add_child(UI.label(ThemeManager.PALETTES[key]["label"], 31, HORIZONTAL_ALIGNMENT_CENTER))
		cell.add_child(UI.mono("In use" if cur else ("Open" if open else "Rank %d" % RewardsData.theme_rank(key)), 22, Color(0, 0, 0, 0), HORIZONTAL_ALIGNMENT_CENTER))
		row.add_child(cell)
	return v

func _on_play_games_status() -> void:
	if is_inside_tree():
		Nav.go("res://scenes/rewards.tscn")

func on_back() -> void:
	Nav.go("res://scenes/main_menu.tscn")
