extends Control
class_name MainMenu

## Main menu screen: game title, Start Game → weapon select, Leaderboard, Settings, Quit.

var _leaderboard_ui: LeaderboardUI
var _settings_ui: SettingsUI
var _weapon_select_ui: WeaponSelectUI
var _main_panel: VBoxContainer


func _ready() -> void:
	_leaderboard_ui = get_node_or_null("LeaderboardUI") as LeaderboardUI
	_settings_ui = get_node_or_null("SettingsUI") as SettingsUI
	_weapon_select_ui = get_node_or_null("WeaponSelectUI") as WeaponSelectUI
	SettingsManager.apply_window_mode()
	_build_ui()
	# Move overlay panels to top of draw order
	if _leaderboard_ui:
		move_child(_leaderboard_ui, get_child_count() - 1)
	if _settings_ui:
		move_child(_settings_ui, get_child_count() - 1)
	if _weapon_select_ui:
		move_child(_weapon_select_ui, get_child_count() - 1)


func _build_ui() -> void:
	anchor_left = 0.0
	anchor_right = 1.0
	anchor_top = 0.0
	anchor_bottom = 1.0

	# Background
	var bg := ColorRect.new()
	bg.color = Color(0.08, 0.08, 0.12)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)

	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(center)

	var panel := VBoxContainer.new()
	panel.add_theme_constant_override("separation", 24)

	# Title
	var title := Label.new()
	title.text = "Hunting Ground"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 48)
	title.add_theme_color_override("font_color", Color(0.3, 0.7, 1.0))
	panel.add_child(title)

	var subtitle := Label.new()
	subtitle.text = "Arena Survival Roguelite"
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle.add_theme_font_size_override("font_size", 18)
	subtitle.add_theme_color_override("font_color", Color(1.0, 1.0, 1.0, 0.5))
	panel.add_child(subtitle)

	var spacer := Control.new()
	spacer.custom_minimum_size = Vector2(0, 60)
	panel.add_child(spacer)

	# Buttons
	_main_panel = panel

	var start_btn := _make_button("Start Game", _on_start)
	panel.add_child(start_btn)

	var lb_btn := _make_button("Leaderboard", _on_leaderboard)
	panel.add_child(lb_btn)

	var settings_btn := _make_button("Settings", _on_settings)
	panel.add_child(settings_btn)

	var quit_btn := _make_button("Quit", _on_quit)
	panel.add_child(quit_btn)

	center.add_child(panel)


func _on_start() -> void:
	if _weapon_select_ui:
		_weapon_select_ui._on_back_callback = func(): _main_panel.show()
		_weapon_select_ui._on_start_callback = _start_game
		_main_panel.hide()
		_weapon_select_ui.show_panel()


func _start_game() -> void:
	get_tree().change_scene_to_file("res://scenes/main.tscn")


func _on_leaderboard() -> void:
	if _leaderboard_ui:
		_leaderboard_ui._on_back_callback = func(): _main_panel.show()
		_main_panel.hide()
		_leaderboard_ui.show_entries()


func _on_settings() -> void:
	if _settings_ui:
		_settings_ui._on_back_callback = func(): _main_panel.show()
		_main_panel.hide()
		_settings_ui.show_panel()


func _on_quit() -> void:
	get_tree().quit()


func _make_button(text: String, callback: Callable) -> Button:
	var btn := Button.new()
	btn.text = text
	btn.add_theme_font_size_override("font_size", 24)
	btn.custom_minimum_size = Vector2(260, 56)
	btn.pressed.connect(callback)
	return btn
