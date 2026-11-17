extends RefCounted
## Statistics store (pure data, unit-tested): games played/won and best time per
## difficulty, plus completed daily puzzles. Persisted as JSON.

## "0".."3" (difficulty) -> {played, won, best}  (best = -1.0 when none)
var games := {}
## "YYYY-MM-DD" -> solve time in seconds
var daily := {}

func _entry(difficulty: int) -> Dictionary:
	var k := str(difficulty)
	if not games.has(k):
		games[k] = {"played": 0, "won": 0, "best": -1.0}
	return games[k]

## Records a finished game. Returns true if it set a new best time.
func record(difficulty: int, won: bool, time: float) -> bool:
	var e := _entry(difficulty)
	e["played"] = int(e["played"]) + 1
	var new_best := false
	if won:
		e["won"] = int(e["won"]) + 1
		if float(e["best"]) < 0.0 or time < float(e["best"]):
			e["best"] = time
			new_best = true
	return new_best

## difficulty -1 = all difficulties.
func played(difficulty: int = -1) -> int:
	return _sum("played", difficulty)

func wins(difficulty: int = -1) -> int:
	return _sum("won", difficulty)

func win_rate(difficulty: int = -1) -> float:
	var p := played(difficulty)
	return float(wins(difficulty)) / p if p > 0 else 0.0

## Best time in seconds, or -1.0 if never won.
func best_time(difficulty: int) -> float:
	return float(_entry(difficulty)["best"])

func _sum(key: String, difficulty: int) -> int:
	if difficulty >= 0:
		return int(_entry(difficulty)[key])
	var total := 0
	for k in games:
		total += int(games[k][key])
	return total

## Records a daily completion. Returns true the first time for that date.
func record_daily(date_key: String, time: float) -> bool:
	if daily.has(date_key):
		return false
	daily[date_key] = time
	return true

func daily_done(date_key: String) -> bool:
	return daily.has(date_key)

## Consecutive completed days ending today (or yesterday if today is not done yet).
func daily_streak(today_key: String) -> int:
	var unix := Time.get_unix_time_from_datetime_string(today_key)
	if not daily_done(today_key):
		unix -= 86400
	var n := 0
	while daily_done(Time.get_date_string_from_unix_time(int(unix))):
		n += 1
		unix -= 86400
	return n

func to_dict() -> Dictionary:
	return {"games": games, "daily": daily}

func from_dict(d: Dictionary) -> void:
	games = d.get("games", {})
	daily = d.get("daily", {})

func save(path: String) -> bool:
	var f := FileAccess.open(path, FileAccess.WRITE)
	if f == null:
		return false
	f.store_string(JSON.stringify(to_dict()))
	return true

## Loads from `path`; a missing or corrupt file yields empty stats.
static func load_from(path: String):
	var s = load("res://scripts/game/stats_data.gd").new()
	if FileAccess.file_exists(path):
		var json := JSON.new()
		if json.parse(FileAccess.get_file_as_string(path)) == OK and json.data is Dictionary:
			s.from_dict(json.data)
	return s
