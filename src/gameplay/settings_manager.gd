extends RefCounted
class_name SettingsManager

## Settings persistence via Godot ConfigFile (user://settings.cfg).
## Static methods — callable from any scene.

const PATH := "user://settings.cfg"
const SECTION := "settings"
const KEYBIND_SECTION := "keybinds"

const DEFAULT_MASTER_VOLUME := 80
const DEFAULT_SFX_VOLUME := 100
const DEFAULT_FULLSCREEN := false
const DEFAULT_LANG := 0  # Locale.Lang.ZH

## Actions exposed for rebinding. Mouse buttons are encoded as "mb_<index>"
## and keyboard scancodes as "kb_<code>" in the config file.
const REBINDABLE_ACTIONS := ["move_up", "move_down", "move_left", "move_right", "melee_attack", "ranged_attack", "dodge", "pause"]


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


# --- Tutorial (first-run) ---

static func has_seen_tutorial() -> bool:
	return _load().get_value(SECTION, "tutorial_seen", false)


static func mark_tutorial_seen() -> void:
	var cfg := _load()
	cfg.set_value(SECTION, "tutorial_seen", true)
	cfg.save(PATH)


# --- Keybindings ---

## Apply saved keybindings to the InputMap at startup.
## Each saved action replaces its events entirely.
static func apply_keybindings() -> void:
	var cfg := _load()
	for action in REBINDABLE_ACTIONS:
		if not cfg.has_section_key(KEYBIND_SECTION, action):
			continue
		var encoded: String = cfg.get_value(KEYBIND_SECTION, action)
		var event := _decode_event(encoded)
		if event == null:
			continue
		# Clear existing events for this action, then set the custom one.
		# Keep it simple: one event per action (keyboard OR mouse button).
		InputMap.action_erase_events(action)
		InputMap.action_add_event(action, event)


## Save a custom binding for an action. `event` is the input event to bind.
static func set_keybinding(action: String, event: InputEvent) -> void:
	var encoded := _encode_event(event)
	var cfg := _load()
	cfg.set_value(KEYBIND_SECTION, action, encoded)
	cfg.save(PATH)
	# Apply immediately.
	InputMap.action_erase_events(action)
	InputMap.action_add_event(action, event)


## Get the currently-bound primary event for an action (from InputMap).
static func get_bound_event(action: String) -> InputEvent:
	var events := InputMap.action_get_events(action)
	if events.is_empty():
		return null
	return events[0]


## Human-readable label for an input event.
static func event_label(event: InputEvent) -> String:
	if event is InputEventKey:
		var k := event as InputEventKey
		return OS.get_keycode_string(k.keycode)
	if event is InputEventMouseButton:
		var mb := event as InputEventMouseButton
		match mb.button_index:
			MOUSE_BUTTON_LEFT: return "LMB"
			MOUSE_BUTTON_RIGHT: return "RMB"
			MOUSE_BUTTON_MIDDLE: return "MMB"
			MOUSE_BUTTON_WHEEL_UP: return "Wheel Up"
			MOUSE_BUTTON_WHEEL_DOWN: return "Wheel Down"
			_: return "Mouse %d" % mb.button_index
	return "..."


## Reset a single action to its project.godot default by reloading the map.
static func reset_keybinding(action: String) -> void:
	var cfg := _load()
	cfg.set_value(KEYBIND_SECTION, action, null)
	cfg.save(PATH)
	# Reload InputMap defaults from project.godot by re-parsing.
	# Godot doesn't expose a per-action reset, so we use ProjectSettings + InputMap.load_from_project_settings().
	InputMap.load_from_project_settings()
	apply_keybindings()


static func _encode_event(event: InputEvent) -> String:
	if event is InputEventKey:
		var k := event as InputEventKey
		return "kb_%d" % k.keycode
	if event is InputEventMouseButton:
		var mb := event as InputEventMouseButton
		return "mb_%d" % mb.button_index
	return ""


static func _decode_event(encoded: String) -> InputEvent:
	if encoded.begins_with("kb_"):
		var code := encoded.substr(3).to_int()
		var ev := InputEventKey.new()
		ev.keycode = code
		return ev
	if encoded.begins_with("mb_"):
		var idx := encoded.substr(3).to_int()
		var ev := InputEventMouseButton.new()
		ev.button_index = idx
		return ev
	return null


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
