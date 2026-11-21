extends RefCounted
## Google Play Games IDs, copied from Play Console (Play Games services >
## Achievements / Leaderboards, or "Get resources"). An empty string means the
## item is not set up yet; the game simply skips it.
## See store/PLAY_GAMES_SETUP.md for the names, descriptions and points to create.

## Medal id -> [Bronze, Silver, Gold] achievement ids (same order as RewardsData.MEDALS).
const ACHIEVEMENTS := {
	"winner": ["", "", ""],
	"flawless": ["", "", ""],
	"streak": ["", "", ""],
	"cube": ["", "", ""],
	"speed": ["", "", ""],
	"expert": ["", "", ""],
}

## Best time per classic difficulty (0 = Easy .. 3 = Expert), submitted in milliseconds.
const BEST_TIME := ["", "", "", "CgkI5se81I0GEAIQAg"]

## Total XP (higher is better).
const TOTAL_XP := "CgkI5se81I0GEAIQAQ"
