extends Control
class_name PauseMenu

## ESC pause menu: overlay with Resume / Quit buttons.

@export var blur_alpha: float = 0.55


func _ready() -> void:
	process_mode = PROCESS_MODE_ALWAYS
	mouse_filter = MOUSE_FILTER_STOP
	visible = false

	var overlay := ColorRect.new()
	overlay.color = Color(0.0, 0.0, 0.0, blur_alpha)
	overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(overlay)

	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(center)

	var panel := VBoxContainer.new()
	panel.add_theme_constant_override("separation", 20)

	var title := Label.new()
	title.text = "Paused"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 36)
	title.add_theme_color_override("font_color", Color.WHITE)
	panel.add_child(title)

	var spacer := Control.new()
	spacer.custom_minimum_size = Vector2(0, 20)
	panel.add_child(spacer)

	var resume_btn := _make_button("Resume", _on_resume)
	panel.add_child(resume_btn)

	var quit_btn := _make_button("Quit to Desktop", _on_quit)
	panel.add_child(quit_btn)

	center.add_child(panel)


func _input(event: InputEvent) -> void:
	if event.is_action_pressed("pause"):
		_toggle()


func _toggle() -> void:
	if visible:
		_close()
	else:
		_open()


func _open() -> void:
	# Don't open if upgrade UI or game over is showing
	if _is_other_ui_visible():
		return
	get_tree().paused = true
	show()


func _close() -> void:
	get_tree().paused = false
	hide()


func _on_resume() -> void:
	_close()


func _on_quit() -> void:
	get_tree().quit()


func _is_other_ui_visible() -> bool:
	# Check if UpgradeUI or GameOverUI are active
	var ui_layer := get_parent()
	if ui_layer:
		for child in ui_layer.get_children():
			if child is UpgradeUI and child.visible:
				return true
			if child is GameOverUI and child.visible:
				return true
	return false


func _make_button(text: String, callback: Callable) -> Button:
	var btn := Button.new()
	btn.text = text
	btn.add_theme_font_size_override("font_size", 22)
	btn.custom_minimum_size = Vector2(240, 50)
	btn.pressed.connect(callback)
	return btn
