extends Control
class_name StatisticsUI

## Career statistics panel: shows lifetime stats + unlock progress.
## Reads from MetaProgress.lifetime_stats and UnlockTreeManager.

var _on_back_callback: Callable

var _panel_bg: ColorRect
var _title_label: Label
var _stats_container: VBoxContainer
var _back_button: Button
var _tree_manager: Node


func _ready() -> void:
	visible = false
	_tree_manager = _find_tree_manager()
	_build_ui()


func show_panel() -> void:
	_refresh_stats()
	show()


func _build_ui() -> void:
	anchor_left = 0.0
	anchor_right = 1.0
	anchor_top = 0.0
	anchor_bottom = 1.0

	_panel_bg = ColorRect.new()
	_panel_bg.color = Color(0.06, 0.06, 0.10, 0.95)
	_panel_bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(_panel_bg)

	var vbox := VBoxContainer.new()
	vbox.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT, Control.PRESET_MODE_MINSIZE, 40)
	add_child(vbox)

	_title_label = Label.new()
	_title_label.text = Locale.t("statistics")
	_title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_title_label.add_theme_font_size_override("font_size", 32)
	_title_label.add_theme_color_override("font_color", Color(0.3, 0.7, 1.0))
	vbox.add_child(_title_label)

	var spacer := Control.new()
	spacer.custom_minimum_size = Vector2(0, 24)
	vbox.add_child(spacer)

	_stats_container = VBoxContainer.new()
	_stats_container.alignment = BoxContainer.ALIGNMENT_CENTER
	_stats_container.add_theme_constant_override("separation", 14)
	vbox.add_child(_stats_container)

	var spacer2 := Control.new()
	spacer2.custom_minimum_size = Vector2(0, 32)
	vbox.add_child(spacer2)

	_back_button = Button.new()
	_back_button.text = Locale.t("back")
	_back_button.add_theme_font_size_override("font_size", 18)
	_back_button.custom_minimum_size = Vector2(180, 44)
	_back_button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	_back_button.pressed.connect(_on_back)
	vbox.add_child(_back_button)


func _refresh_stats() -> void:
	for child in _stats_container.get_children():
		child.queue_free()

	var stats: Dictionary = MetaProgress.lifetime_stats
	_add_stat_row(Locale.t("total_kills"), str(stats.get("total_kills", 0)))
	_add_stat_row(Locale.t("total_deaths"), str(stats.get("total_deaths", 0)))
	_add_stat_row(Locale.t("total_victories"), str(stats.get("total_victories", 0)))
	_add_stat_row(Locale.t("highest_wave"), str(stats.get("highest_wave", 0)))
	_add_stat_row(Locale.t("total_shards_earned"), str(stats.get("total_shards_earned", 0)))
	_add_stat_row(Locale.t("unlock_progress"), _unlock_progress_text())


func _add_stat_row(label_text: String, value_text: String) -> void:
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 24)

	var label := Label.new()
	label.text = label_text
	label.add_theme_font_size_override("font_size", 18)
	label.add_theme_color_override("font_color", Color(1.0, 1.0, 1.0, 0.7))
	label.custom_minimum_size = Vector2(220, 0)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	row.add_child(label)

	var value := Label.new()
	value.text = value_text
	value.add_theme_font_size_override("font_size", 20)
	value.add_theme_color_override("font_color", Color(0.2, 0.9, 1.0, 0.95))
	value.custom_minimum_size = Vector2(160, 0)
	value.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	row.add_child(value)

	_stats_container.add_child(row)


func _unlock_progress_text() -> String:
	var total := 0
	if _tree_manager and _tree_manager.has_method("get_all_unlocks"):
		total = _tree_manager.get_all_unlocks().size()
	if total == 0:
		return "0 / 0 (0%)"
	var unlocked := 0
	for ul in _tree_manager.get_all_unlocks():
		if MetaProgress.is_unlocked(ul.id):
			unlocked += 1
	return "%d / %d (%d%%)" % [unlocked, total, int(float(unlocked) / float(total) * 100.0)]


func _on_back() -> void:
	hide()
	if _on_back_callback.is_valid():
		_on_back_callback.call()


func _find_tree_manager() -> Node:
	var parent := get_parent()
	if parent:
		var tm := parent.get_node_or_null("UnlockTreeManager")
		if tm:
			return tm
	# Fallback: scan siblings
	var p := get_parent()
	if p:
		for child in p.get_children():
			if child.has_method("get_all_unlocks"):
				return child
	return null
