extends Control
class_name MainMenu

## Main menu screen: game title, Start Game → weapon select, Meta Upgrades, Leaderboard, Settings, Quit.

var _leaderboard_ui: LeaderboardUI
var _settings_ui: SettingsUI
var _weapon_select_ui: WeaponSelectUI
var _unlock_tree_panel: UnlockTreePanel
var _statistics_ui: StatisticsUI
var _main_panel: VBoxContainer
var _shard_label: Label


func _ready() -> void:
	_leaderboard_ui = get_node_or_null("LeaderboardUI") as LeaderboardUI
	_settings_ui = get_node_or_null("SettingsUI") as SettingsUI
	_weapon_select_ui = get_node_or_null("WeaponSelectUI") as WeaponSelectUI
	_unlock_tree_panel = get_node_or_null("UnlockTreePanel") as UnlockTreePanel
	_statistics_ui = get_node_or_null("StatisticsUI") as StatisticsUI
	SettingsManager.init_lang()
	SettingsManager.apply_keybindings()
	SettingsManager.apply_window_mode()
	_build_ui()

	if _unlock_tree_panel:
		move_child(_unlock_tree_panel, get_child_count() - 1)
		_unlock_tree_panel._on_back_callback = func(): _main_panel.show()
	if _leaderboard_ui:
		move_child(_leaderboard_ui, get_child_count() - 1)
	if _settings_ui:
		move_child(_settings_ui, get_child_count() - 1)
	if _weapon_select_ui:
		move_child(_weapon_select_ui, get_child_count() - 1)
	if _statistics_ui:
		move_child(_statistics_ui, get_child_count() - 1)

	EventBus.shards_changed.connect(_on_shards_changed)
	EventBus.profile_loaded.connect(_on_shards_changed)


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
	panel.add_theme_constant_override("separation", 24)

	var title := Label.new()
	title.text = Locale.t("hunting_ground")
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 48)
	title.add_theme_color_override("font_color", Color(0.3, 0.7, 1.0))
	panel.add_child(title)

	var subtitle := Label.new()
	subtitle.text = Locale.t("arena_survival")
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle.add_theme_font_size_override("font_size", 18)
	subtitle.add_theme_color_override("font_color", Color(1.0, 1.0, 1.0, 0.5))
	panel.add_child(subtitle)

	var spacer := Control.new()
	spacer.custom_minimum_size = Vector2(0, 60)
	panel.add_child(spacer)

	_main_panel = panel

	var start_btn := _make_button(Locale.t("start_game"), _on_start)
	panel.add_child(start_btn)

	var upgrade_btn := _make_button(Locale.t("meta_upgrades"), _on_upgrades)
	panel.add_child(upgrade_btn)

	var lb_btn := _make_button(Locale.t("leaderboard"), _on_leaderboard)
	panel.add_child(lb_btn)

	var stats_btn := _make_button(Locale.t("statistics"), _on_statistics)
	panel.add_child(stats_btn)

	var settings_btn := _make_button(Locale.t("settings"), _on_settings)
	panel.add_child(settings_btn)

	# Shard display at bottom
	var spacer2 := Control.new()
	spacer2.custom_minimum_size = Vector2(0, 40)
	panel.add_child(spacer2)

	_shard_label = Label.new()
	_shard_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_shard_label.add_theme_font_size_override("font_size", 18)
	_shard_label.add_theme_color_override("font_color", Color(0.2, 0.9, 1.0, 0.85))
	_shard_label.text = "%s: %d" % [Locale.t("shards"), MetaProgress.get_shards()]
	panel.add_child(_shard_label)

	var quit_btn := _make_button(Locale.t("quit"), _on_quit)
	panel.add_child(quit_btn)

	center.add_child(panel)


func _on_shards_changed(_total: int = 0) -> void:
	_shard_label.text = "%s: %d" % [Locale.t("shards"), MetaProgress.get_shards()]


func _on_start() -> void:
	if _weapon_select_ui:
		_weapon_select_ui._on_back_callback = func(): _main_panel.show()
		_weapon_select_ui._on_start_callback = _start_game
		_main_panel.hide()
		_weapon_select_ui.show_panel()


func _on_upgrades() -> void:
	if _unlock_tree_panel:
		_main_panel.hide()
		_unlock_tree_panel.show_panel()


func _start_game() -> void:
	get_tree().change_scene_to_file("res://scenes/main.tscn")


func _on_leaderboard() -> void:
	if _leaderboard_ui:
		_leaderboard_ui._on_back_callback = func(): _main_panel.show()
		_main_panel.hide()
		_leaderboard_ui.show_entries()


func _on_statistics() -> void:
	if _statistics_ui:
		_statistics_ui._on_back_callback = func(): _main_panel.show()
		_main_panel.hide()
		_statistics_ui.show_panel()


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
