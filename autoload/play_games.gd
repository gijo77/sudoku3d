extends Node
## Google Play Games Services bridge. Autoload "PlayGames".
##
## Wraps the GodotPlayGameServices plugin (addons/GodotPlayGameServices, MIT).
## Everything is optional: on desktop, or when the plugin or the player's
## sign-in is missing, every call is a silent no-op and the game stays fully
## playable offline.
##
## After sign-in and after every finished game (sync):
## - unlocks the Play achievement for every medal tier earned locally,
## - submits best times per difficulty and total XP to the leaderboards,
## - saves stats + rewards to Saved Games. On sign-in the cloud copy is loaded
##   first and merged into local data (cloud_save.gd keeps the better values).

signal status_changed

const CloudSave := preload("res://scripts/game/cloud_save.gd")
const Ids := preload("res://scripts/game/play_games_ids.gd")
const RewardsData := preload("res://scripts/game/rewards_data.gd")

var available := false       # plugin present (Android build with the plugin)
var signed_in := false
var _sign_in
var _achievements
var _leaderboards
var _snapshots
var _loaded_cloud := false   # only save to the cloud after we merged what is there

func _ready() -> void:
	if not OS.has_feature("android"):
		return
	var core := get_node_or_null("/root/GodotPlayGameServices")
	if core == null or core.initialize() != 0:
		return
	available = true
	_sign_in = _client("res://addons/GodotPlayGameServices/scripts/sign_in/sign_in_client.gd")
	_achievements = _client("res://addons/GodotPlayGameServices/scripts/achievements/achievements_client.gd")
	_leaderboards = _client("res://addons/GodotPlayGameServices/scripts/leaderboards/leaderboards_client.gd")
	_snapshots = _client("res://addons/GodotPlayGameServices/scripts/snapshots/snapshots_client.gd")
	_sign_in.user_authenticated.connect(_on_authenticated)
	_snapshots.game_loaded.connect(_on_game_loaded)
	_snapshots.conflict_emitted.connect(func(_c) -> void:
		# Another device saved in between: reload, merge again, then save.
		_loaded_cloud = false
		_snapshots.load_game(CloudSave.SNAPSHOT_NAME, true))
	_sign_in.is_authenticated()

func _client(path: String) -> Node:
	var n: Node = load(path).new()
	add_child(n)
	return n

## Manual sign-in (Settings button).
func sign_in() -> void:
	if available:
		_sign_in.sign_in()

func show_achievements() -> void:
	if signed_in:
		_achievements.show_achievements()

func show_leaderboards() -> void:
	if signed_in:
		_leaderboards.show_all_leaderboards()

func _on_authenticated(ok: bool) -> void:
	signed_in = ok
	status_changed.emit()
	if ok:
		_snapshots.load_game(CloudSave.SNAPSHOT_NAME, true)
		_push_achievements()
		_push_scores()

func _on_game_loaded(snapshot) -> void:
	if snapshot != null and CloudSave.merge_into(Stats.data, Rewards.data, CloudSave.parse(snapshot.content)):
		Stats.save()
		Rewards.save()
		status_changed.emit()
	_loaded_cloud = true
	_push_achievements()
	_push_scores()
	_save_cloud()

## Call after every finished game.
func sync() -> void:
	if not signed_in:
		return
	_push_achievements()
	_push_scores()
	_save_cloud()

func _push_achievements() -> void:
	for m in RewardsData.MEDALS:
		var ids: Array = Ids.ACHIEVEMENTS.get(m["id"], [])
		var tier: int = Rewards.data.medal_tier(m["id"])
		for t in mini(tier, ids.size()):
			if ids[t] != "":
				_achievements.unlock_achievement(ids[t])

func _push_scores() -> void:
	for d in Ids.BEST_TIME.size():
		var best: float = Stats.data.best_time(d)
		if Ids.BEST_TIME[d] != "" and best >= 0.0:
			_leaderboards.submit_score(Ids.BEST_TIME[d], int(round(best * 1000.0)))
	if Ids.TOTAL_XP != "" and Rewards.data.xp > 0:
		_leaderboards.submit_score(Ids.TOTAL_XP, Rewards.data.xp)

func _save_cloud() -> void:
	if not _loaded_cloud:
		return
	var desc := "Rank %d · %d XP" % [Rewards.data.rank(), Rewards.data.xp]
	_snapshots.save_game(CloudSave.SNAPSHOT_NAME, desc, CloudSave.make_payload(Stats.data, Rewards.data))
