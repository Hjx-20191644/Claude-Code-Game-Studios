extends Control
class_name SettingsUI

## Settings panel: master/SFX volume sliders, fullscreen toggle, back button.
## Embedded in main menu scene.

var _on_back_callback: Callable
var _master_slider: HSlider
var _sfx_slider: HSlider
var _master_label: Label
var _sfx_label: Label
var _fullscreen_btn: Button


func _ready() -> void:
	mouse_filter = MOUSE_FILTER_STOP
	_build_ui()
	hide()


func show_panel() -> void:
	_load_settings()
	show()


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

	var spacer3 := Control.new()
	spacer3.custom_minimum_size = Vector2(0, 12)
	panel.add_child(spacer3)

	var back_btn := Button.new()
	back_btn.text = "Back"
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
	_refresh_fullscreen_btn()


func _on_back() -> void:
	hide()
	if _on_back_callback.is_valid():
		_on_back_callback.call()


func _refresh_labels() -> void:
	var mv := int(_master_slider.value)
	var sv := int(_sfx_slider.value)
	_master_label.text = "Master Volume: %d%%" % mv
	_sfx_label.text = "SFX Volume: %d%%" % sv
	_refresh_fullscreen_btn()


func _refresh_fullscreen_btn() -> void:
	_fullscreen_btn.text = "Window Mode: Fullscreen" if SettingsManager.is_fullscreen() else "Window Mode: Windowed"
