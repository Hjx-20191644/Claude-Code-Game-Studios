extends Control
class_name SettingsUI

## Settings panel: master/SFX volume sliders, fullscreen toggle, language,
## keybinding remapping, back button. Embedded in main menu scene.

var _on_back_callback: Callable
var _master_slider: HSlider
var _sfx_slider: HSlider
var _master_label: Label
var _sfx_label: Label
var _fullscreen_btn: Button
var _lang_btn: Button
var _keybind_buttons: Dictionary = {}  # action -> Button
var _listening_action: String = ""  # action currently awaiting a key press


func _ready() -> void:
	mouse_filter = MOUSE_FILTER_STOP
	_build_ui()
	hide()


func show_panel() -> void:
	_load_settings()
	_refresh_keybind_labels()
	show()


func _unhandled_input(event: InputEvent) -> void:
	if _listening_action.is_empty():
		return
	# Accept the next key or mouse-button press as the new binding.
	# Ignore modifier-only releases and mouse motion.
	if event is InputEventKey and event.pressed and not event.echo:
		# Ignore pure modifier presses to avoid binding to them alone.
		match event.keycode:
			KEY_CTRL, KEY_SHIFT, KEY_ALT, KEY_META: return
		_commit_binding(_listening_action, event)
	elif event is InputEventMouseButton and event.pressed:
		_commit_binding(_listening_action, event)


func _commit_binding(action: String, event: InputEvent) -> void:
	_listening_action = ""
	SettingsManager.set_keybinding(action, event)
	_refresh_keybind_labels()
	# Consume so it doesn't trigger gameplay.
	get_viewport().set_input_as_handled()


func _build_ui() -> void:
	anchor_left = 0.0
	anchor_right = 1.0
	anchor_top = 0.0
	anchor_bottom = 1.0

	var bg := ColorRect.new()
	bg.color = Color(0.08, 0.08, 0.12)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)

	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(center)

	var panel := VBoxContainer.new()
	panel.add_theme_constant_override("separation", 20)

	var title := Label.new()
	title.text = "Settings"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 36)
	title.add_theme_color_override("font_color", Color(0.7, 0.7, 1.0))
	panel.add_child(title)

	var spacer := Control.new()
	spacer.custom_minimum_size = Vector2(0, 16)
	panel.add_child(spacer)

	# Master volume
	_master_label = Label.new()
	_master_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_master_label.add_theme_font_size_override("font_size", 18)
	panel.add_child(_master_label)

	_master_slider = HSlider.new()
	_master_slider.min_value = 0
	_master_slider.max_value = 100
	_master_slider.step = 1
	_master_slider.custom_minimum_size = Vector2(300, 0)
	_master_slider.value_changed.connect(_on_master_changed)
	panel.add_child(_master_slider)

	# SFX volume
	_sfx_label = Label.new()
	_sfx_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_sfx_label.add_theme_font_size_override("font_size", 18)
	panel.add_child(_sfx_label)

	_sfx_slider = HSlider.new()
	_sfx_slider.min_value = 0
	_sfx_slider.max_value = 100
	_sfx_slider.step = 1
	_sfx_slider.custom_minimum_size = Vector2(300, 0)
	_sfx_slider.value_changed.connect(_on_sfx_changed)
	panel.add_child(_sfx_slider)

	var spacer2 := Control.new()
	spacer2.custom_minimum_size = Vector2(0, 8)
	panel.add_child(spacer2)

	# Fullscreen toggle
	_fullscreen_btn = Button.new()
	_fullscreen_btn.add_theme_font_size_override("font_size", 18)
	_fullscreen_btn.custom_minimum_size = Vector2(240, 44)
	_fullscreen_btn.pressed.connect(_on_fullscreen_toggled)
	panel.add_child(_fullscreen_btn)

	# Language toggle
	_lang_btn = Button.new()
	_lang_btn.text = "Language: English"
	_lang_btn.add_theme_font_size_override("font_size", 18)
	_lang_btn.custom_minimum_size = Vector2(240, 44)
	_lang_btn.pressed.connect(_on_lang_toggled)
	panel.add_child(_lang_btn)

	var spacer_kb := Control.new()
	spacer_kb.custom_minimum_size = Vector2(0, 12)
	panel.add_child(spacer_kb)

	# Keybindings section
	var kb_title := Label.new()
	kb_title.text = Locale.t("keybinds")
	kb_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	kb_title.add_theme_font_size_override("font_size", 22)
	kb_title.add_theme_color_override("font_color", Color(0.7, 0.7, 1.0))
	panel.add_child(kb_title)

	var kb_grid := GridContainer.new()
	kb_grid.columns = 3
	kb_grid.add_theme_constant_override("h_separation", 16)
	kb_grid.add_theme_constant_override("v_separation", 6)
	kb_grid.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	for action in SettingsManager.REBINDABLE_ACTIONS:
		var label := Label.new()
		label.text = Locale.t("kb_" + action)
		label.add_theme_font_size_override("font_size", 14)
		label.custom_minimum_size = Vector2(120, 0)
		kb_grid.add_child(label)

		var bind_btn := Button.new()
		bind_btn.add_theme_font_size_override("font_size", 14)
		bind_btn.custom_minimum_size = Vector2(120, 32)
		bind_btn.pressed.connect(_on_rebind_pressed.bind(action))
		kb_grid.add_child(bind_btn)
		_keybind_buttons[action] = bind_btn

		var reset_btn := Button.new()
		reset_btn.text = Locale.t("kb_reset")
		reset_btn.add_theme_font_size_override("font_size", 12)
		reset_btn.custom_minimum_size = Vector2(70, 32)
		reset_btn.pressed.connect(_on_reset_pressed.bind(action))
		kb_grid.add_child(reset_btn)
	panel.add_child(kb_grid)

	var spacer3 := Control.new()
	spacer3.custom_minimum_size = Vector2(0, 12)
	panel.add_child(spacer3)

	var back_btn := Button.new()
	back_btn.text = Locale.t("back")
	back_btn.add_theme_font_size_override("font_size", 20)
	back_btn.custom_minimum_size = Vector2(180, 44)
	back_btn.pressed.connect(_on_back)
	panel.add_child(back_btn)

	center.add_child(panel)


func _load_settings() -> void:
	_master_slider.set_value_no_signal(SettingsManager.get_master_volume())
	_sfx_slider.set_value_no_signal(SettingsManager.get_sfx_volume())
	_refresh_labels()


func _on_master_changed(value: float) -> void:
	SettingsManager.set_master_volume(int(value))
	_refresh_labels()


func _on_sfx_changed(value: float) -> void:
	SettingsManager.set_sfx_volume(int(value))
	_refresh_labels()


func _on_fullscreen_toggled() -> void:
	var is_fs := not SettingsManager.is_fullscreen()
	SettingsManager.set_fullscreen(is_fs)
	SettingsManager.apply_window_mode()
	_refresh()


func _on_lang_toggled() -> void:
	var next_lang := Locale.Lang.EN if SettingsManager.get_lang() == Locale.Lang.ZH else Locale.Lang.ZH
	SettingsManager.set_lang(next_lang)
	_refresh()


func _on_rebind_pressed(action: String) -> void:
	# If already listening for another action, cancel it first.
	if not _listening_action.is_empty() and _keybind_buttons.has(_listening_action):
		var prev_btn: Button = _keybind_buttons[_listening_action]
		prev_btn.text = _binding_label(_listening_action)
	_listening_action = action
	if _keybind_buttons.has(action):
		(_keybind_buttons[action] as Button).text = Locale.t("kb_listening")


func _on_reset_pressed(action: String) -> void:
	SettingsManager.reset_keybinding(action)
	# After reset, InputMap was reloaded; refresh all labels.
	_refresh_keybind_labels()


func _binding_label(action: String) -> String:
	var ev := SettingsManager.get_bound_event(action)
	if ev:
		return SettingsManager.event_label(ev)
	return "..."


func _refresh_keybind_labels() -> void:
	for action in _keybind_buttons.keys():
		if action == _listening_action:
			continue
		var btn: Button = _keybind_buttons[action]
		btn.text = _binding_label(action)


func _on_back() -> void:
	hide()
	if _on_back_callback.is_valid():
		_on_back_callback.call()


func _refresh() -> void:
	var mv := int(_master_slider.value)
	var sv := int(_sfx_slider.value)
	_master_label.text = "%s: %d%%" % [Locale.t("master_volume"), mv]
	_sfx_label.text = "%s: %d%%" % [Locale.t("sfx_volume"), sv]
	_fullscreen_btn.text = SettingsManager.get_mode_label()
	_lang_btn.text = "%s: %s" % [Locale.t("language"), SettingsManager.get_lang_label()]


func _refresh_labels() -> void:
	_refresh()
