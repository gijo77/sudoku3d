extends RefCounted
## Daily puzzle: seeded from the calendar date so every device gets the same
## puzzle on the same day, fully offline.

const Generator := preload("res://scripts/logic/generator.gd")

## e.g. 2026-11-17 -> 20261117
static func seed_for(year: int, month: int, day: int) -> int:
	return year * 10000 + month * 100 + day

## Difficulty ramps through the week: Mon/Tue Easy, Wed/Thu Medium, Fri/Sat Hard, Sun Expert.
static func difficulty_for_weekday(weekday: int) -> int:
	match weekday:
		1, 2: return Generator.Difficulty.EASY
		3, 4: return Generator.Difficulty.MEDIUM
		5, 6: return Generator.Difficulty.HARD
		_: return Generator.Difficulty.EXPERT

static func puzzle_for_date(year: int, month: int, day: int) -> Dictionary:
	var unix := Time.get_unix_time_from_datetime_dict({"year": year, "month": month, "day": day, "hour": 12, "minute": 0, "second": 0})
	var weekday: int = Time.get_datetime_dict_from_unix_time(unix)["weekday"]
	return Generator.generate(difficulty_for_weekday(weekday), seed_for(year, month, day))

static func puzzle_for_today() -> Dictionary:
	var d := Time.get_date_dict_from_system()
	return puzzle_for_date(d["year"], d["month"], d["day"])
