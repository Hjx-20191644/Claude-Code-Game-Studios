extends Control
class_name MainMenu

## Main menu screen: game title, Start Game, Quit.


func _ready() -> void:
	_build_ui()


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
	var start_btn := _make_button("Start Game", _on_start)
	panel.add_child(start_btn)

	var quit_btn := _make_button("Quit", _on_quit)
	panel.add_child(quit_btn)

	center.add_child(panel)


func _on_start() -> void:
	get_tree().change_scene_to_file("res://scenes/main.tscn")


func _on_quit() -> void:
	get_tree().quit()


func _make_button(text: String, callback: Callable) -> Button:
	var btn := Button.new()
	btn.text = text
	btn.add_theme_font_size_override("font_size", 24)
	btn.custom_minimum_size = Vector2(260, 56)
	btn.pressed.connect(callback)
	return btn
