extends Node
## Autosave of the game in progress. Autoload "SaveGame".

const Data := preload("res://scripts/game/save_data.gd")
const PATH := "user://savegame.json"

func save_game(d: Dictionary) -> void:
	Data.save_game(PATH, d)

func load_game() -> Dictionary:
	return Data.load_game(PATH)

func exists() -> bool:
	return Data.exists(PATH)

func clear() -> void:
	Data.clear(PATH)
