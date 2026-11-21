extends RefCounted
## Google Play Games IDs, copied from Play Console (Play Games services >
## Achievements / Leaderboards, or "Get resources"). An empty string means the
## item is not set up yet; the game simply skips it.
## See store/PLAY_GAMES_SETUP.md for the names, descriptions and points to create.

## Medal id -> [Bronze, Silver, Gold] achievement ids (same order as RewardsData.MEDALS).
const ACHIEVEMENTS := {
	"winner": ["CgkI5se81I0GEAIQBg", "CgkI5se81I0GEAIQEQ", "CgkI5se81I0GEAIQDA"],
	"flawless": ["CgkI5se81I0GEAIQCQ", "CgkI5se81I0GEAIQDQ", "CgkI5se81I0GEAIQEw"],
	"streak": ["CgkI5se81I0GEAIQFA", "CgkI5se81I0GEAIQFQ", "CgkI5se81I0GEAIQCA"],
	"cube": ["CgkI5se81I0GEAIQDg", "CgkI5se81I0GEAIQBw", "CgkI5se81I0GEAIQCg"],
	"speed": ["CgkI5se81I0GEAIQFg", "CgkI5se81I0GEAIQDw", "CgkI5se81I0GEAIQEA"],
	"expert": ["CgkI5se81I0GEAIQEg", "CgkI5se81I0GEAIQFw", "CgkI5se81I0GEAIQCw"],
}

## Best time per classic difficulty (0 = Easy .. 3 = Expert), submitted in milliseconds.
const BEST_TIME := ["CgkI5se81I0GEAIQAw", "CgkI5se81I0GEAIQBQ", "CgkI5se81I0GEAIQBA", "CgkI5se81I0GEAIQAg"]

## Total XP (higher is better).
const TOTAL_XP := ""   # no Total XP leaderboard yet (…QAQ is an achievement, not a leaderboard)
