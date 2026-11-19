extends Node
## Rewards autoload. `data` is a rewards_data.gd instance; call save() after changes.

const RewardsData := preload("res://scripts/game/rewards_data.gd")
const PATH := "user://rewards.json"

var data

func _ready() -> void:
	data = RewardsData.load_from(PATH)

func save() -> void:
	data.save(PATH)
