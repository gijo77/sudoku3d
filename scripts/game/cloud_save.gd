extends RefCounted
## Cloud save payload for Google Play Games Saved Games (pure logic, unit-tested).
##
## The payload holds stats + rewards. Loading never throws progress away: the
## cloud copy is MERGED into the local data, taking the better value of each
## field (more XP, higher counters and medal tiers, more games, faster best
## times, every solved daily). Two phones that both played offline therefore
## keep the larger of each number rather than the sum.

const VERSION := 1
const SNAPSHOT_NAME := "sudoku3d_progress"

static func make_payload(stats, rewards) -> PackedByteArray:
	var d := {"v": VERSION, "stats": stats.to_dict(), "rewards": rewards.to_dict(),
		"saved_at": int(Time.get_unix_time_from_system())}
	return JSON.stringify(d).to_utf8_buffer()

## Parses a payload; returns {} when it is empty, corrupt or from a newer version.
static func parse(bytes: PackedByteArray) -> Dictionary:
	if bytes.is_empty():
		return {}
	var json := JSON.new()
	if json.parse(bytes.get_string_from_utf8()) != OK or not (json.data is Dictionary):
		return {}
	var d: Dictionary = json.data
	if int(d.get("v", 0)) < 1 or int(d.get("v", 0)) > VERSION:
		return {}
	if not (d.get("stats") is Dictionary and d.get("rewards") is Dictionary):
		return {}
	return d

## Merges a parsed payload into local stats and rewards. Returns true if anything changed.
static func merge_into(stats, rewards, payload: Dictionary) -> bool:
	if payload.is_empty():
		return false
	var changed := _merge_stats(stats, payload["stats"])
	changed = _merge_rewards(rewards, payload["rewards"]) or changed
	return changed

static func _merge_stats(stats, d: Dictionary) -> bool:
	var changed := false
	var games: Variant = d.get("games", {})
	if games is Dictionary:
		for k in games:
			var g: Variant = games[k]
			if not (g is Dictionary):
				continue
			var key := str(k)
			if not stats.games.has(key):
				stats.games[key] = {"played": 0, "won": 0, "best": -1.0}
			var e: Dictionary = stats.games[key]
			for f in ["played", "won"]:
				var v := int(g.get(f, 0))
				if v > int(e[f]):
					e[f] = v
					changed = true
			var b := float(g.get("best", -1.0))
			if b >= 0.0 and (float(e["best"]) < 0.0 or b < float(e["best"])):
				e["best"] = b
				changed = true
	var daily: Variant = d.get("daily", {})
	if daily is Dictionary:
		for day in daily:
			var t := float(daily[day])
			var key := str(day)
			if not stats.daily.has(key) or t < float(stats.daily[key]):
				stats.daily[key] = t
				changed = true
	return changed

static func _merge_rewards(rewards, d: Dictionary) -> bool:
	var changed := false
	var xp := int(d.get("xp", 0))
	if xp > rewards.xp:
		rewards.xp = xp
		changed = true
	var c: Variant = d.get("counters", {})
	if c is Dictionary:
		for k in rewards.counters:
			var v := int(c.get(k, 0))
			if v > int(rewards.counters[k]):
				rewards.counters[k] = v
				changed = true
	var m: Variant = d.get("medals", {})
	if m is Dictionary:
		for k in m:
			var t := int(m[k])
			if t > int(rewards.medals.get(str(k), 0)):
				rewards.medals[str(k)] = t
				changed = true
	return changed
