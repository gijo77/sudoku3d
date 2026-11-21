extends SceneTree
## Renders one 512 x 512 PNG per achievement (medal tier) with the in-game medal
## art, and writes the Play Console import CSVs next to them.
## Run (needs a window, not --headless):
##   godot --path . --script res://scripts_tools/achievements/render_icons.gd -- <out_dir>

const Glyph := preload("res://scripts/ui/glyph_icon.gd")
const RewardsData := preload("res://scripts/game/rewards_data.gd")

const MEDAL_GLYPHS := {"winner": "trophy", "flawless": "shield", "streak": "flame", "cube": "cube", "speed": "bolt", "expert": "star"}
const POINTS := [10, 25, 50]
const TIER := ["Bronze", "Silver", "Gold"]

## Descriptions per medal and tier (no commas: Play's CSV import forbids them).
const DESC := {
	"winner": ["Win your first game", "Win 10 games", "Win 50 games"],
	"flawless": ["Win a game with no mistakes", "Win 10 games with no mistakes", "Win 30 games with no mistakes"],
	"streak": ["Solve the daily puzzle 3 days in a row", "Solve the daily puzzle 7 days in a row", "Solve the daily puzzle 30 days in a row"],
	"cube": ["Solve a Cube Sudoku", "Solve 5 Cube Sudokus", "Solve 20 Cube Sudokus"],
	"speed": ["Win a classic game under par time", "Win 5 classic games under par time", "Win 20 classic games under par time"],
	"expert": ["Win on Expert", "Win 5 games on Expert", "Win 15 games on Expert"],
}

func _init() -> void:
	var args := OS.get_cmdline_user_args()
	var out: String = args[0] if args.size() > 0 else "user://achievements"
	DirAccess.make_dir_recursive_absolute(out)
	var vp := SubViewport.new()
	vp.size = Vector2i(512, 512)
	vp.transparent_bg = false
	vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(vp)
	var bg := ColorRect.new()
	bg.color = Color("060A17")
	bg.size = Vector2(512, 512)
	vp.add_child(bg)
	var meta := PackedStringArray()
	var icons := PackedStringArray()
	var order := 1
	# Bronze for every medal first, then Silver, then Gold: the list reads easy -> hard.
	for t in 3:
		for m in RewardsData.MEDALS:
			var id: String = m["id"]
			var name := "%s %s" % [TIER[t], m["name"]]
			var file := "%s_%s.png" % [id, TIER[t].to_lower()]
			var medal: Control = Glyph.make_medal(MEDAL_GLYPHS[id], t + 1, 452)
			medal.position = Vector2(30, 30)
			medal.size = Vector2(452, 452)
			vp.add_child(medal)
			await process_frame
			await process_frame
			await RenderingServer.frame_post_draw
			vp.get_texture().get_image().save_png(out.path_join(file))
			medal.queue_free()
			meta.append("%s,%s,False,,Revealed,%d,%d" % [name, DESC[id][t], POINTS[t], order])
			icons.append("%s,%s" % [name, file])
			order += 1
	_write(out.path_join("AchievementsMetadata.csv"), meta)
	_write(out.path_join("AchievementsIconsMappings.csv"), icons)
	print("wrote %d achievements to %s" % [meta.size(), out])
	quit()

func _write(path: String, lines: PackedStringArray) -> void:
	var f := FileAccess.open(path, FileAccess.WRITE)
	f.store_string("\n".join(lines) + "\n")
	f.close()
