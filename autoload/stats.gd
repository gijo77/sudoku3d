extends Node
## Statistics autoload. `data` is a stats_data.gd instance; call save() after changes.

const StatsData := preload("res://scripts/game/stats_data.gd")
const PATH := "user://stats.json"

var data

func _ready() -> void:
	data = StatsData.load_from(PATH)

func save() -> void:
	data.save(PATH)
