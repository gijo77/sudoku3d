extends Node
## User settings persisted in user://settings.cfg (ConfigFile). Autoload "Settings".
## Change values with set_value() so they are saved and `changed` is emitted.

signal changed

const PATH := "user://settings.cfg"

var sound := true
var music := true
var vibration := true
var theme_name := "light"          # see ThemeManager.PALETTES
var highlight_peers := true        # row / column / box
var highlight_same := true         # same digit

const KEYS := ["sound", "music", "vibration", "theme_name", "highlight_peers", "highlight_same"]

func _ready() -> void:
	var cfg := ConfigFile.new()
	if cfg.load(PATH) == OK:
		for k in KEYS:
			set(k, cfg.get_value("settings", k, get(k)))

func set_value(key: String, value) -> void:
	set(key, value)
	var cfg := ConfigFile.new()
	for k in KEYS:
		cfg.set_value("settings", k, get(k))
	cfg.save(PATH)
	changed.emit()
