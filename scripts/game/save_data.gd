extends RefCounted
## Autosave file helpers for the game in progress (pure, unit-tested).
## Save format: {"mode": "new"|"daily", "daily_key": "...", "model": <GameModel.to_dict()>}

static func save_game(path: String, data: Dictionary) -> bool:
	var f := FileAccess.open(path, FileAccess.WRITE)
	if f == null:
		return false
	f.store_string(JSON.stringify(data))
	return true

## Returns {} when there is no valid save (missing, corrupt or wrong shape).
static func load_game(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		return {}
	var json := JSON.new()
	if json.parse(FileAccess.get_file_as_string(path)) != OK:
		return {}
	var parsed = json.data
	if not (parsed is Dictionary) or not parsed.has("model") or not (parsed["model"] is Dictionary):
		return {}
	var m: Dictionary = parsed["model"]
	for key in ["givens", "solution", "grid", "notes"]:
		if not (m.get(key) is Array) or m[key].size() != 81:
			return {}
	for key in ["mistakes", "hints_used", "elapsed", "difficulty", "seed"]:
		if not m.has(key):
			return {}
	return parsed

static func clear(path: String) -> void:
	if FileAccess.file_exists(path):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(path))

static func exists(path: String) -> bool:
	return not load_game(path).is_empty()
