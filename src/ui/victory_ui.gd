extends Control
class_name VictoryUI

## Victory screen: shown when the wave 20 final boss is slain.
## Displays run stats + completion shard bonus, and offers to either
## continue into endless mode (wave 21+) or return to the main menu.

@export var show_delay: float = 1.2
@export var completion_shard_bonus: int = 50

var _overlay: ColorRect
var _title_label: Label
var _score_label: Label
var _wave_label: Label
var _kills_label: Label
var _time_label: Label
var _shard_label: Label
var _continue_endless_button: Button
var _return_menu_button: Button
var _score_manager: ScoreManager
var _shard_manager: Node
var _wave_manager: Node
var _main: Main


func _ready() -> void:
	process_mode = PROCESS_MODE_ALWAYS
	mouse_filter = MOUSE_FILTER_STOP
	visible = false

	_score_manager = _find_score_manager()
	_shard_manager = _find_shard_manager()
	_wave_manager = _find_wave_manager()
	_main = _find_main()

	_build_ui()
	EventBus.run_won.connect(_on_run_won)


func _on_run_won() -> void:
	await get_tree().create_timer(show_delay, true, false, true).timeout
	_refresh_stats()
	show()


func _build_ui() -> void:
	anchor_left = 0.0
	anchor_right = 1.0
	anchor_top = 0.0
	anchor_bottom = 1.0

	_overlay = ColorRect.new()
	_overlay.color = Color(0.0, 0.0, 0.0, 0.65)
	_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(_overlay)

	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(center)

	var panel := VBoxContainer.new()
	panel.add_theme_constant_override("separation", 12)

	_title_label = Label.new()
	_title_label.text = Locale.t("victory")
	_title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_title_label.add_theme_font_size_override("font_size", 32)
	_title_label.add_theme_color_override("font_color", Color(1.0, 0.85, 0.3))
	panel.add_child(_title_label)

	var subtitle := Label.new()
	subtitle.text = Locale.t("victory_subtitle")
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle.add_theme_font_size_override("font_size", 16)
	subtitle.add_theme_color_override("font_color", Color(1.0, 1.0, 1.0, 0.6))
	panel.add_child(subtitle)

	var spacer1 := Control.new()
	spacer1.custom_minimum_size = Vector2(0, 12)
	panel.add_child(spacer1)

	_score_label = _make_stat_label("%s: 0" % Locale.t("score"))
	panel.add_child(_score_label)
	_wave_label = _make_stat_label("%s: 0" % Locale.t("wave"))
	panel.add_child(_wave_label)
	_kills_label = _make_stat_label("%s: 0" % Locale.t("kills"))
	panel.add_child(_kills_label)
	_time_label = _make_stat_label("%s: 0:00" % Locale.t("time"))
	panel.add_child(_time_label)

	_shard_label = Label.new()
	_shard_label.text = "%s: 0" % Locale.t("shards_earned")
	_shard_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_shard_label.add_theme_font_size_override("font_size", 16)
	_shard_label.add_theme_color_override("font_color", Color(0.2, 0.9, 1.0, 0.95))
	panel.add_child(_shard_label)

	var spacer2 := Control.new()
	spacer2.custom_minimum_size = Vector2(0, 20)
	panel.add_child(spacer2)

	_continue_endless_button = Button.new()
	_continue_endless_button.text = Locale.t("continue_endless")
	_continue_endless_button.add_theme_font_size_override("font_size", 16)
	_continue_endless_button.custom_minimum_size = Vector2(220, 38)
	_continue_endless_button.pressed.connect(_on_continue_endless_pressed)
	panel.add_child(_continue_endless_button)

	_return_menu_button = Button.new()
	_return_menu_button.text = Locale.t("return_main_menu")
	_return_menu_button.add_theme_font_size_override("font_size", 14)
	_return_menu_button.custom_minimum_size = Vector2(220, 30)
	_return_menu_button.pressed.connect(_on_return_menu_pressed)
	panel.add_child(_return_menu_button)

	center.add_child(panel)


func _refresh_stats() -> void:
	# Completion bonus is added on top of whatever shards the player collected.
	var run_shards: int = _shard_manager.get_run_shards() if _shard_manager else 0
	var total_shards := run_shards + completion_shard_bonus

	if _score_manager:
		var s := _score_manager.get_stats()
		_score_label.text = "%s: %d" % [Locale.t("score"), s.score]
		_wave_label.text = "%s: %d" % [Locale.t("wave"), s.wave_reached]
		_kills_label.text = "%s: %d" % [Locale.t("kills"), s.total_kills]
		_time_label.text = "%s: %s" % [Locale.t("time"), _format_time(s.survival_time)]

	_shard_label.text = "%s: %d" % [Locale.t("shards_earned"), total_shards]

	# Persist the run results (counts as a completed/victorious run).
	_save_and_notify(total_shards)


func _save_and_notify(shards_earned: int) -> void:
	var stats: RunStats = _score_manager.get_stats() if _score_manager else RunStats.new()
	EventBus.run_completed.emit(stats, shards_earned)
	MetaProgress.record_run(stats, shards_earned)
	MetaProgress.record_victory()


func _on_continue_endless_pressed() -> void:
	hide()
	if _wave_manager and _wave_manager.has_method("continue_endless"):
		_wave_manager.continue_endless()


func _on_return_menu_pressed() -> void:
	hide()
	get_tree().change_scene_to_file("res://scenes/main_menu.tscn")


func _format_time(seconds: float) -> String:
	var total := int(seconds)
	var m := total / 60
	var s := total % 60
	return "%d:%02d" % [m, s]


func _make_stat_label(text: String) -> Label:
	var l := Label.new()
	l.text = text
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.add_theme_font_size_override("font_size", 16)
	l.add_theme_color_override("font_color", Color(1.0, 1.0, 1.0, 0.85))
	return l


func _find_score_manager() -> ScoreManager:
	var systems := get_node_or_null("../../Systems")
	if systems:
		return systems.get_node_or_null("ScoreManager") as ScoreManager
	return null


func _find_shard_manager() -> Node:
	var systems := get_node_or_null("../../Systems")
	if systems:
		return systems.get_node_or_null("ShardManager")
	return null


func _find_wave_manager() -> Node:
	var systems := get_node_or_null("../../Systems")
	if systems:
		return systems.get_node_or_null("WaveManager")
	return null


func _find_main() -> Main:
	return get_node_or_null("../..") as Main
