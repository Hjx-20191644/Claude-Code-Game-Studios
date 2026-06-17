extends Control
class_name TutorialOverlay

## First-run control hints overlay. Shown once on the player's first run.
## Fades out after `auto_hide_delay` seconds OR as soon as the player
## performs any movement/attack/dodge input. "Seen" flag persisted via
## SettingsManager so it only appears once per profile.

@export var auto_hide_delay: float = 8.0
@export var fade_duration: float = 0.6

var _panel: ColorRect
var _vbox: VBoxContainer
var _timer: float = 0.0
var _fading: bool = false
var _fade_alpha: float = 1.0


func _ready() -> void:
	mouse_filter = MOUSE_FILTER_IGNORE
	visible = false
	_build_ui()


## Show the overlay unless this profile has already seen it.
func show_if_first_run() -> void:
	if SettingsManager.has_seen_tutorial():
		return
	visible = true
	_timer = 0.0
	_fading = false
	_fade_alpha = 1.0
	modulate.a = 1.0


func _build_ui() -> void:
	anchor_left = 0.0
	anchor_right = 1.0
	anchor_top = 0.0
	anchor_bottom = 1.0

	_panel = ColorRect.new()
	_panel.color = Color(0.0, 0.0, 0.0, 0.45)
	_panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	_panel.mouse_filter = MOUSE_FILTER_IGNORE
	add_child(_panel)

	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	center.mouse_filter = MOUSE_FILTER_IGNORE
	add_child(center)

	_vbox = VBoxContainer.new()
	_vbox.add_theme_constant_override("separation", 10)
	_vbox.add_theme_constant_override("margin_left", 40)
	_vbox.add_theme_constant_override("margin_right", 40)
	_vbox.add_theme_constant_override("margin_top", 24)
	_vbox.add_theme_constant_override("margin_bottom", 24)

	var title := Label.new()
	title.text = Locale.t("tutorial_title")
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 24)
	title.add_theme_color_override("font_color", Color(0.3, 0.7, 1.0))
	_vbox.add_child(title)

	var spacer := Control.new()
	spacer.custom_minimum_size = Vector2(0, 8)
	_vbox.add_child(spacer)

	_add_hint("tutorial_move", "WASD")
	_add_hint("tutorial_melee", "LMB")
	_add_hint("tutorial_ranged", "RMB")
	_add_hint("tutorial_dodge", "Space")
	_add_hint("tutorial_pause", "ESC")

	var spacer2 := Control.new()
	spacer2.custom_minimum_size = Vector2(0, 12)
	_vbox.add_child(spacer2)

	var footer := Label.new()
	footer.text = Locale.t("tutorial_dismiss")
	footer.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	footer.add_theme_font_size_override("font_size", 13)
	footer.add_theme_color_override("font_color", Color(1.0, 1.0, 1.0, 0.5))
	_vbox.add_child(footer)

	center.add_child(_vbox)


func _add_hint(label_key: String, key: String) -> void:
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 20)

	var label := Label.new()
	label.text = Locale.t(label_key)
	label.add_theme_font_size_override("font_size", 16)
	label.add_theme_color_override("font_color", Color(1.0, 1.0, 1.0, 0.85))
	label.custom_minimum_size = Vector2(200, 0)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	row.add_child(label)

	var key_label := Label.new()
	key_label.text = key
	key_label.add_theme_font_size_override("font_size", 18)
	key_label.add_theme_color_override("font_color", Color(1.0, 0.85, 0.3))
	key_label.custom_minimum_size = Vector2(120, 0)
	key_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	row.add_child(key_label)

	_vbox.add_child(row)


func _process(delta: float) -> void:
	if not visible or _fading:
		if _fading:
			_fade_alpha -= delta / fade_duration
			if _fade_alpha <= 0.0:
				_fade_alpha = 0.0
				visible = false
				_fading = false
			modulate.a = _fade_alpha
		return

	_timer += delta
	if _timer >= auto_hide_delay:
		_dismiss()
		return

	# Dismiss as soon as the player acts.
	if _player_acted():
		_dismiss()


func _player_acted() -> bool:
	if Input.get_vector("move_left", "move_right", "move_up", "move_down").length() > 0.1:
		return true
	if Input.is_action_pressed("melee_attack") or Input.is_action_pressed("ranged_attack"):
		return true
	if Input.is_action_just_pressed("dodge"):
		return true
	return false


func _dismiss() -> void:
	_fading = true
	_fade_alpha = 1.0
	SettingsManager.mark_tutorial_seen()
