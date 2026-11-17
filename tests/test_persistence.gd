extends "res://tests/test_case.gd"

const StatsData := preload("res://scripts/game/stats_data.gd")
const SaveData := preload("res://scripts/game/save_data.gd")
const Model := preload("res://scripts/game/game_model.gd")
const Generator := preload("res://scripts/logic/generator.gd")

const STATS_PATH := "user://test_stats.json"
const SAVE_PATH := "user://test_save.json"

func test_stats_counts_and_rate() -> void:
	var s = StatsData.new()
	s.record(0, true, 300.0)
	s.record(0, false, 100.0)
	s.record(1, true, 500.0)
	assert_eq(s.played(), 3, "total played")
	assert_eq(s.wins(), 2, "total wins")
	assert_eq(s.played(0), 2, "easy played")
	assert_true(absf(s.win_rate(0) - 0.5) < 0.001, "easy win rate")
	assert_eq(s.win_rate(3), 0.0, "no games -> 0")

func test_best_time() -> void:
	var s = StatsData.new()
	assert_eq(s.best_time(2), -1.0, "none yet")
	assert_true(s.record(2, true, 400.0), "first win is best")
	assert_true(not s.record(2, true, 450.0), "slower is not best")
	assert_true(s.record(2, true, 350.0), "faster is best")
	assert_eq(s.best_time(2), 350.0, "best stored")
	s.record(2, false, 10.0)
	assert_eq(s.best_time(2), 350.0, "losses never set best")

func test_stats_persistence_roundtrip() -> void:
	var s = StatsData.new()
	s.record(1, true, 123.0)
	s.record_daily("2026-11-17", 99.0)
	assert_true(s.save(STATS_PATH), "saved")
	var l = StatsData.load_from(STATS_PATH)
	assert_eq(l.played(1), 1, "played restored")
	assert_eq(l.best_time(1), 123.0, "best restored")
	assert_true(l.daily_done("2026-11-17"), "daily restored")
	DirAccess.remove_absolute(ProjectSettings.globalize_path(STATS_PATH))

func test_stats_corrupt_file_is_empty() -> void:
	var f := FileAccess.open(STATS_PATH, FileAccess.WRITE)
	f.store_string("{not json")
	f.close()
	assert_eq(StatsData.load_from(STATS_PATH).played(), 0, "corrupt -> empty")
	DirAccess.remove_absolute(ProjectSettings.globalize_path(STATS_PATH))
	assert_eq(StatsData.load_from(STATS_PATH).played(), 0, "missing -> empty")

func test_daily_streak() -> void:
	var s = StatsData.new()
	for d in ["2026-11-15", "2026-11-16", "2026-11-17"]:
		s.record_daily(d, 60.0)
	assert_eq(s.daily_streak("2026-11-17"), 3, "three in a row")
	assert_eq(s.daily_streak("2026-11-18"), 3, "today not done yet keeps streak")
	assert_eq(s.daily_streak("2026-11-19"), 0, "missed a day resets")
	assert_true(not s.record_daily("2026-11-17", 50.0), "second completion ignored")
	assert_eq(s.daily["2026-11-17"], 60.0, "first time kept")

func test_save_game_roundtrip() -> void:
	var m = Model.new()
	m.start(Generator.generate(Generator.Difficulty.EASY, 5))
	m.place(m.grid.find(0), m.solution[m.grid.find(0)])
	m.tick(33.0)
	assert_true(SaveData.save_game(SAVE_PATH, {"mode": "daily", "daily_key": "2026-11-17", "model": m.to_dict()}), "saved")
	assert_true(SaveData.exists(SAVE_PATH), "exists")
	var d := SaveData.load_game(SAVE_PATH)
	assert_eq(d["mode"], "daily", "mode")
	var m2 = Model.new()
	m2.from_dict(d["model"])
	assert_eq(m2.grid, m.grid, "grid restored")
	assert_eq(m2.elapsed, 33.0, "time restored")
	SaveData.clear(SAVE_PATH)
	assert_true(not SaveData.exists(SAVE_PATH), "cleared")

func test_save_game_rejects_bad_data() -> void:
	var f := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	f.store_string('{"mode":"new","model":{"grid":[1,2,3]}}')
	f.close()
	assert_eq(SaveData.load_game(SAVE_PATH).size(), 0, "wrong shape rejected")
	f = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	f.store_string("garbage")
	f.close()
	assert_eq(SaveData.load_game(SAVE_PATH).size(), 0, "garbage rejected")
	SaveData.clear(SAVE_PATH)

func test_summary_over_keys() -> void:
	var s = StatsData.new()
	s.record(10, true, 90.0)
	s.record(11, false, 20.0)
	s.record(12, true, 60.0)
	var r: Dictionary = s.summary([10, 11, 12, 13])
	assert_eq(r["played"], 3, "played")
	assert_eq(r["won"], 2, "won")
	assert_eq(r["best"], 60.0, "best across keys")
	assert_eq(s.summary([13])["best"], -1.0, "none")
