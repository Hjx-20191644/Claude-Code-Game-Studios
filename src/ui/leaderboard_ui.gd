extends Control
class_name LeaderboardUI

## Leaderboard panel: shows top 10 runs from LeaderboardManager.
## Embedded in the main menu, toggled by the "Leaderboard" button.

var _main_menu: MainMenu
var _on_back_callback: Callable
var _overlay: ColorRect
var _entry_container: VBoxContainer


func _ready() -> void:
	mouse_filter = MOUSE_FILTER_STOP
	_build_ui()
	hide()


func show_entries() -> void:
	_refresh()
	show()


func _build_ui() -> void:
	anchor_left = 0.0
	anchor_right = 1.0
	anchor_top = 0.0
	anchor_bottom = 1.0

	_overlay = ColorRect.new()
	_overlay.color = Color(0.08, 0.08, 0.12)
	_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(_overlay)

	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(center)

	var panel := VBoxContainer.new()
	panel.add_theme_constant_override("separation", 16)

	var title := Label.new()
	title.text = "Leaderboard"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 36)
	title.add_theme_color_override("font_color", Color(1.0, 0.84, 0.0))
	panel.add_child(title)

	var spacer := Control.new()
	spacer.custom_minimum_size = Vector2(0, 8)
	panel.add_child(spacer)

	# Column headers
	var header := _make_row(["#", "Score", "Wave", "Kills", "Time"], true)
	panel.add_child(header)

	var sep := HSeparator.new()
	sep.custom_minimum_size = Vector2(400, 1)
	panel.add_child(sep)

	_entry_container = VBoxContainer.new()
	_entry_container.add_theme_constant_override("separation", 4)
	panel.add_child(_entry_container)

	var spacer2 := Control.new()
	spacer2.custom_minimum_size = Vector2(0, 16)
	panel.add_child(spacer2)

	var back_btn := Button.new()
	back_btn.text = "Back"
	back_btn.add_theme_font_size_override("font_size", 20)
	back_btn.custom_minimum_size = Vector2(180, 44)
	back_btn.pressed.connect(_on_back)
	panel.add_child(back_btn)

	center.add_child(panel)


func _refresh() -> void:
	for child in _entry_container.get_children():
		child.queue_free()

	var entries := LeaderboardManager.load_entries()
	if entries.is_empty():
		var empty := Label.new()
		empty.text = "  No records yet"
		empty.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		empty.add_theme_font_size_override("font_size", 16)
		empty.add_theme_color_override("font_color", Color(1.0, 1.0, 1.0, 0.4))
		_entry_container.add_child(empty)
		return

	for i in entries.size():
		var entry: Dictionary = entries[i]
		var score := entry.get("score", 0) as int
		var wave := entry.get("wave", 0) as int
		var kills := entry.get("kills", 0) as int
		var time_val: float = entry.get("time", 0.0)
		var time_str := _format_time(time_val)

		var row := _make_row([
			str(i + 1),
			str(score),
			str(wave),
			str(kills),
			time_str,
		], false)
		_entry_container.add_child(row)


func _on_back() -> void:
	hide()
	if _on_back_callback.is_valid():
		_on_back_callback.call()


func _make_row(values: Array[String], is_header: bool) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 20)

	var widths := [40, 80, 60, 60, 70]
	for i in values.size():
		var label := Label.new()
		label.text = values[i]
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.custom_minimum_size = Vector2(widths[i], 0)
		if is_header:
			label.add_theme_font_size_override("font_size", 14)
			label.add_theme_color_override("font_color", Color(1.0, 1.0, 1.0, 0.5))
		else:
			label.add_theme_font_size_override("font_size", 16)
			label.add_theme_color_override("font_color", Color(1.0, 1.0, 1.0, 0.85))
		row.add_child(label)

	return row


func _format_time(seconds: float) -> String:
	var total := int(seconds)
	var m := total / 60
	var s := total % 60
	return "%d:%02d" % [m, s]
