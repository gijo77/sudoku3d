extends RefCounted
## Reward system data (pure, unit-tested): XP, ranks, medals with Bronze/Silver/Gold
## tiers and rank-gated theme unlocks. Everything is stored on the device only.

const MEDALS := [
	{"id": "winner", "name": "Winner", "desc": "Win games", "counter": "wins", "tiers": [1, 10, 50]},
	{"id": "flawless", "name": "Flawless", "desc": "Win with 0 mistakes", "counter": "flawless", "tiers": [1, 10, 30]},
	{"id": "streak", "name": "Warm Streak", "desc": "Daily puzzle streak", "counter": "best_streak", "tiers": [3, 7, 30]},
	{"id": "cube", "name": "Cube Explorer", "desc": "Solve Cube puzzles", "counter": "cube_wins", "tiers": [1, 5, 20]},
	{"id": "speed", "name": "Speedster", "desc": "Win under par time", "counter": "fast_wins", "tiers": [1, 5, 20]},
	{"id": "expert", "name": "Expert Mind", "desc": "Win on Expert", "counter": "expert_wins", "tiers": [1, 5, 15]},
]

## Minimum rank needed to use each theme.
const THEME_RANKS := {"light": 1, "dark": 1, "ocean": 3, "forest": 6, "sunset": 10}

const TITLES := ["Tile Newbie", "Tile Tinkerer", "Grid Gardener", "Box Boss", "Number Ninja", "Sudoku Sage"]
const DIFFICULTY_BONUS := [0, 15, 30, 45]
## Par solve times in seconds per difficulty (Easy..Expert) for the Speedster medal.
const PAR_TIMES := [240.0, 420.0, 720.0, 1200.0]
const TIER_NAMES := ["Locked", "Bronze", "Silver", "Gold"]

var xp := 0
var counters := {"wins": 0, "flawless": 0, "best_streak": 0, "cube_wins": 0, "fast_wins": 0, "expert_wins": 0}
## medal id -> tier 0..3
var medals := {}

# --- Ranks -----------------------------------------------------------------

## XP needed to go from `rank` to `rank + 1`.
static func cost(rank: int) -> int:
	return 100 + 50 * rank

## Total XP at which `rank` starts.
static func xp_at_rank(rank: int) -> int:
	return 100 * (rank - 1) + 25 * rank * (rank - 1)

static func rank_for_xp(total: int) -> int:
	var r := 1
	while total >= xp_at_rank(r + 1):
		r += 1
	return r

static func title_for_rank(rank: int) -> String:
	return TITLES[mini((rank - 1) / 2, TITLES.size() - 1)]

func rank() -> int:
	return rank_for_xp(xp)

## {rank, into, need}: XP earned inside the current rank and the XP the rank needs.
func progress() -> Dictionary:
	var r := rank()
	return {"rank": r, "into": xp - xp_at_rank(r), "need": cost(r)}

# --- Themes ----------------------------------------------------------------

static func theme_rank(theme_key: String) -> int:
	return int(THEME_RANKS.get(theme_key, 1))

func theme_unlocked(theme_key: String) -> bool:
	return rank() >= theme_rank(theme_key)

# --- Medals ----------------------------------------------------------------

func medal_tier(id: String) -> int:
	return int(medals.get(id, 0))

func medals_earned() -> int:
	var n := 0
	for m in MEDALS:
		if medal_tier(m["id"]) > 0:
			n += 1
	return n

static func tier_for(count: int, tiers: Array) -> int:
	var t := 0
	for i in tiers.size():
		if count >= int(tiers[i]):
			t = i + 1
	return t

# --- Applying a finished game -------------------------------------------------

## Records a finished game. Returns what changed so the UI can show it:
## {xp, parts: [[label, amount]...], rank_before, rank_after, new_medals: [{id, tier}], new_themes: [key]}
func apply_result(difficulty: int, won: bool, mistakes: int, time: float, cube: bool, daily_first: bool, streak: int) -> Dictionary:
	var parts: Array = []
	var rank_before := rank()
	var before := {}
	for m in MEDALS:
		before[m["id"]] = medal_tier(m["id"])
	if won:
		parts.append(["Solved", 60 + (10 if cube else 0)])
		var bonus: int = DIFFICULTY_BONUS[clampi(difficulty, 0, 3)]
		if bonus > 0:
			parts.append(["Difficulty bonus", bonus])
		if mistakes == 0:
			parts.append(["No mistakes", 30])
		if daily_first:
			parts.append(["Daily puzzle", 50])
		counters["wins"] = int(counters["wins"]) + 1
		if mistakes == 0:
			counters["flawless"] = int(counters["flawless"]) + 1
		if cube:
			counters["cube_wins"] = int(counters["cube_wins"]) + 1
		else:
			if time <= PAR_TIMES[clampi(difficulty, 0, 3)]:
				counters["fast_wins"] = int(counters["fast_wins"]) + 1
			if difficulty == 3:
				counters["expert_wins"] = int(counters["expert_wins"]) + 1
	else:
		parts.append(["Good try", 10])
	counters["best_streak"] = maxi(int(counters["best_streak"]), streak)
	var gained := 0
	for p in parts:
		gained += int(p[1])
	xp += gained
	var new_medals: Array = []
	for m in MEDALS:
		var t := tier_for(int(counters[m["counter"]]), m["tiers"])
		if t > int(before[m["id"]]):
			medals[m["id"]] = t
			new_medals.append({"id": m["id"], "tier": t})
	var rank_after := rank()
	var new_themes: Array = []
	for k in THEME_RANKS:
		var need: int = THEME_RANKS[k]
		if need > rank_before and need <= rank_after:
			new_themes.append(k)
	return {"xp": gained, "parts": parts, "rank_before": rank_before, "rank_after": rank_after, "new_medals": new_medals, "new_themes": new_themes}

# --- Persistence --------------------------------------------------------------

func to_dict() -> Dictionary:
	return {"xp": xp, "counters": counters, "medals": medals}

func from_dict(d: Dictionary) -> void:
	xp = int(d.get("xp", 0))
	var c: Variant = d.get("counters", {})
	if c is Dictionary:
		for k in counters:
			counters[k] = int(c.get(k, 0))
	var m: Variant = d.get("medals", {})
	medals = {}
	if m is Dictionary:
		for k in m:
			medals[str(k)] = int(m[k])

func save(path: String) -> bool:
	var f := FileAccess.open(path, FileAccess.WRITE)
	if f == null:
		return false
	f.store_string(JSON.stringify(to_dict()))
	return true

## Loads from `path`; a missing or corrupt file yields empty rewards.
static func load_from(path: String):
	var r = load("res://scripts/game/rewards_data.gd").new()
	if FileAccess.file_exists(path):
		var json := JSON.new()
		if json.parse(FileAccess.get_file_as_string(path)) == OK and json.data is Dictionary:
			r.from_dict(json.data)
	return r
