extends "res://tests/test_case.gd"

const CloudSave := preload("res://scripts/game/cloud_save.gd")
const StatsData := preload("res://scripts/game/stats_data.gd")
const RewardsData := preload("res://scripts/game/rewards_data.gd")

func _sample():
	var s = StatsData.new()
	s.record(1, true, 400.0)
	s.record(1, false, 50.0)
	s.record_daily("2026-11-20", 300.0)
	var r = RewardsData.new()
	r.apply_result(1, true, 0, 400.0, false, false, 0)
	return [s, r]

func test_round_trip() -> void:
	var a = _sample()
	var p := CloudSave.parse(CloudSave.make_payload(a[0], a[1]))
	assert_true(not p.is_empty(), "payload parses")
	var s = StatsData.new()
	var r = RewardsData.new()
	assert_true(CloudSave.merge_into(s, r, p), "merge into empty changes data")
	assert_eq(s.played(1), 2, "played restored")
	assert_eq(s.wins(1), 1, "wins restored")
	assert_eq(s.best_time(1), 400.0, "best restored")
	assert_true(s.daily_done("2026-11-20"), "daily restored")
	assert_eq(r.xp, a[1].xp, "xp restored")
	assert_eq(r.medal_tier("winner"), 1, "medal restored")

func test_merge_keeps_better_local_values() -> void:
	var cloud = _sample()
	var p := CloudSave.parse(CloudSave.make_payload(cloud[0], cloud[1]))
	var s = StatsData.new()
	for i in 5:
		s.record(1, true, 200.0)
	var r = RewardsData.new()
	r.xp = 5000
	r.counters["wins"] = 12
	r.medals["winner"] = 2
	CloudSave.merge_into(s, r, p)
	assert_eq(s.played(1), 5, "local played kept (larger)")
	assert_eq(s.best_time(1), 200.0, "faster local best kept")
	assert_eq(r.xp, 5000, "higher local xp kept")
	assert_eq(int(r.counters["wins"]), 12, "higher local counter kept")
	assert_eq(r.medal_tier("winner"), 2, "higher local tier kept")
	assert_true(s.daily_done("2026-11-20"), "cloud daily added")

func test_same_data_reports_no_change() -> void:
	var a = _sample()
	var p := CloudSave.parse(CloudSave.make_payload(a[0], a[1]))
	assert_true(not CloudSave.merge_into(a[0], a[1], p), "merging identical data changes nothing")

func test_bad_payloads_are_ignored() -> void:
	assert_true(CloudSave.parse(PackedByteArray()).is_empty(), "empty")
	assert_true(CloudSave.parse("not json".to_utf8_buffer()).is_empty(), "garbage")
	assert_true(CloudSave.parse('{"v": 99, "stats": {}, "rewards": {}}'.to_utf8_buffer()).is_empty(), "future version")
	assert_true(CloudSave.parse('{"v": 1, "stats": []}'.to_utf8_buffer()).is_empty(), "wrong shape")
	var s = StatsData.new()
	var r = RewardsData.new()
	assert_true(not CloudSave.merge_into(s, r, {}), "empty payload is a no-op")
