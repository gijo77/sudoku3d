extends "res://tests/test_case.gd"

const RewardsData := preload("res://scripts/game/rewards_data.gd")
const PATH := "user://test_rewards.json"

func test_rank_curve() -> void:
	assert_eq(RewardsData.rank_for_xp(0), 1, "starts at rank 1")
	assert_eq(RewardsData.xp_at_rank(2), 150, "rank 2 threshold")
	assert_eq(RewardsData.rank_for_xp(149), 1, "just below rank 2")
	assert_eq(RewardsData.rank_for_xp(150), 2, "rank 2")
	for r in range(1, 20):
		assert_eq(RewardsData.xp_at_rank(r + 1) - RewardsData.xp_at_rank(r), RewardsData.cost(r), "cost matches thresholds at %d" % r)

func test_win_xp_breakdown() -> void:
	var r = RewardsData.new()
	var res: Dictionary = r.apply_result(2, true, 0, 900.0, false, false, 0)
	assert_eq(res["xp"], 60 + 30 + 30, "hard flawless win")
	assert_eq(r.xp, 120, "xp stored")
	var res2: Dictionary = r.apply_result(0, true, 2, 900.0, false, true, 1)
	assert_eq(res2["xp"], 60 + 50, "easy win with mistakes plus daily")

func test_loss_gives_small_xp_and_no_wins() -> void:
	var r = RewardsData.new()
	var res: Dictionary = r.apply_result(1, false, 3, 100.0, false, false, 0)
	assert_eq(res["xp"], 10, "participation xp")
	assert_eq(int(r.counters["wins"]), 0, "no win counted")
	assert_eq(r.medals_earned(), 0, "no medals")

func test_first_win_and_flawless_medals() -> void:
	var r = RewardsData.new()
	var res: Dictionary = r.apply_result(0, true, 0, 100.0, false, false, 0)
	var ids: Array = []
	for m in res["new_medals"]:
		ids.append(m["id"])
	assert_true("winner" in ids, "winner bronze")
	assert_true("flawless" in ids, "flawless bronze")
	assert_true("speed" in ids, "fast easy win")
	assert_eq(r.medal_tier("winner"), 1, "tier stored")
	var res2: Dictionary = r.apply_result(0, true, 0, 100.0, false, false, 0)
	assert_eq(res2["new_medals"].size(), 0, "no repeat medals for same tier")

func test_medal_tiers_progress() -> void:
	assert_eq(RewardsData.tier_for(0, [1, 10, 50]), 0, "none")
	assert_eq(RewardsData.tier_for(10, [1, 10, 50]), 2, "silver")
	assert_eq(RewardsData.tier_for(99, [1, 10, 50]), 3, "gold")

func test_cube_and_expert_counters() -> void:
	var r = RewardsData.new()
	r.apply_result(3, true, 1, 2000.0, true, false, 0)
	assert_eq(int(r.counters["cube_wins"]), 1, "cube win")
	assert_eq(int(r.counters["expert_wins"]), 0, "cube does not count as classic expert")
	r.apply_result(3, true, 1, 2000.0, false, false, 0)
	assert_eq(int(r.counters["expert_wins"]), 1, "classic expert win")

func test_streak_medal() -> void:
	var r = RewardsData.new()
	var res: Dictionary = r.apply_result(0, true, 1, 999.0, false, true, 3)
	assert_eq(r.medal_tier("streak"), 1, "3-day streak bronze")
	assert_true(res["new_medals"].size() >= 1, "reports it")

func test_theme_unlocks_by_rank() -> void:
	var r = RewardsData.new()
	assert_true(r.theme_unlocked("light"), "light open")
	assert_true(not r.theme_unlocked("ocean"), "ocean locked at rank 1")
	r.xp = RewardsData.xp_at_rank(3)
	assert_true(r.theme_unlocked("ocean"), "ocean at rank 3")
	assert_true(not r.theme_unlocked("forest"), "forest still locked")

func test_apply_reports_new_themes() -> void:
	var r = RewardsData.new()
	r.xp = RewardsData.xp_at_rank(3) - 10
	var res: Dictionary = r.apply_result(0, false, 3, 10.0, false, false, 0)
	assert_eq(res["rank_after"], 3, "ranked up")
	assert_true("ocean" in res["new_themes"], "ocean reported unlocked")

func test_persistence_round_trip_and_corrupt_file() -> void:
	var r = RewardsData.new()
	r.apply_result(1, true, 0, 100.0, false, false, 2)
	assert_true(r.save(PATH), "saved")
	var back = RewardsData.load_from(PATH)
	assert_eq(back.xp, r.xp, "xp round trip")
	assert_eq(back.medal_tier("winner"), 1, "medals round trip")
	var f := FileAccess.open(PATH, FileAccess.WRITE)
	f.store_string("{not json")
	f = null
	var bad = RewardsData.load_from(PATH)
	assert_eq(bad.xp, 0, "corrupt file gives empty rewards")
	DirAccess.remove_absolute(ProjectSettings.globalize_path(PATH))
