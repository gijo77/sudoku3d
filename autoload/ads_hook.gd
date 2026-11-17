extends Node
## ---------------------------------------------------------------------------
## OPTIONAL AdMob HOOK - DISABLED BY DEFAULT.
## The game ships with NO ads, NO analytics and NO INTERNET permission.
## To enable ads you would (1) install an AdMob plugin, (2) add the INTERNET
## permission in the Android export preset, (3) update store/privacy_policy.md and
## the Play Console Data safety form, and (4) set ENABLED = true and implement
## the TODOs below. Until then every function here is a no-op.
## ---------------------------------------------------------------------------

const ENABLED := false

func show_banner() -> void:
	if not ENABLED:
		return
	# TODO: call the AdMob plugin's banner API here.

## Called when a game finishes (good moment for an interstitial).
func on_game_finished() -> void:
	if not ENABLED:
		return
	# TODO: call the AdMob plugin's interstitial API here.
