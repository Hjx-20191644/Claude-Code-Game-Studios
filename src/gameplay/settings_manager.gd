extends RefCounted
class_name SettingsManager

## Settings persistence via Godot ConfigFile (user://settings.cfg).
## Static methods — callable from any scene.

const PATH := "user://settings.cfg"
const SECTION := "settings"

const DEFAULT_MASTER_VOLUME := 80
const DEFAULT_SFX_VOLUME := 100
const DEFAULT_FULLSCREEN := false
const DEFAULT_LANG := 0  # Locale.Lang.ZH


static func get_lang() -> int:
	return _load().get_value(SECTION, "lang", DEFAULT_LANG)


static func set_lang(value: int) -> void:
	var cfg := _load()
	cfg.set_value(SECTION, "lang", value)
	cfg.save(PATH)
	Locale.set_lang(value)


static func get_lang_label() -> String:
	match get_lang():
		Locale.Lang.EN: return "English"
	return "中文"


static func init_lang() -> void:
	Locale.set_lang(get_lang())


static func get_master_volume() -> int:
	return _load().get_value(SECTION, "master_volume", DEFAULT_MASTER_VOLUME)


static func get_sfx_volume() -> int:
	return _load().get_value(SECTION, "sfx_volume", DEFAULT_SFX_VOLUME)


static func is_fullscreen() -> bool:
	return _load().get_value(SECTION, "fullscreen", DEFAULT_FULLSCREEN)


static func set_master_volume(value: int) -> void:
	var cfg := _load()
	cfg.set_value(SECTION, "master_volume", clampi(value, 0, 100))
	cfg.save(PATH)


static func set_sfx_volume(value: int) -> void:
	var cfg := _load()
	cfg.set_value(SECTION, "sfx_volume", clampi(value, 0, 100))
	cfg.save(PATH)


static func set_fullscreen(value: bool) -> void:
	var cfg := _load()
	cfg.set_value(SECTION, "fullscreen", value)
	cfg.save(PATH)


## Returns a human-readable label for the current window mode.
static func get_mode_label() -> String:
	if is_fullscreen():
		return "Window Mode: Maximized" if OS.has_feature("editor") else "Window Mode: Fullscreen"
	return "Window Mode: Windowed"


## Convert 0–100 slider value to decibels (-40 to +6).
static func slider_to_db(slider_value: int) -> float:
	var t := clampf(float(slider_value) / 100.0, 0.0, 1.0)
	return lerpf(-40.0, 6.0, t)


## Convert mixed volume (master * sfx) to final dB for AudioStreamPlayer.
## Both inputs are 0–100.
static func effective_sfx_db(master: int, sfx: int) -> float:
	return slider_to_db(master) + slider_to_db(sfx)


## Apply window mode from saved settings.
static func apply_window_mode() -> void:
	if is_fullscreen():
		if OS.has_feature("editor"):
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_MAXIMIZED)
		else:
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)


# --- Private ---

static var _cached_config: ConfigFile

static func _load() -> ConfigFile:
	if _cached_config:
		return _cached_config
	_cached_config = ConfigFile.new()
	var err := _cached_config.load(PATH)
	if err != OK:
		_cached_config = ConfigFile.new()  # Fresh with defaults
	return _cached_config
