extends Control
class_name PauseMenu

## ESC pause menu: overlay with Resume / Quit buttons + player stats panel.

@export var blur_alpha: float = 0.55

var _stats_vbox: VBoxContainer


func _ready() -> void:
	process_mode = PROCESS_MODE_ALWAYS
	mouse_filter = MOUSE_FILTER_STOP
	visible = false

	anchor_left = 0.0
	anchor_right = 1.0
	anchor_top = 0.0
	anchor_bottom = 1.0

	var overlay := ColorRect.new()
	overlay.color = Color(0.0, 0.0, 0.0, blur_alpha)
	overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(overlay)

	var hbox := HBoxContainer.new()
	hbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(hbox)

	# --- Left: Stats panel ---
	var stats_panel := _build_stats_panel()
	hbox.add_child(stats_panel)

	# --- Center: Menu ---
	var center := CenterContainer.new()
	center.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hbox.add_child(center)

	var panel := VBoxContainer.new()
	panel.add_theme_constant_override("separation", 20)

	var title := Label.new()
	title.text = Locale.t("paused")
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 36)
	title.add_theme_color_override("font_color", Color.WHITE)
	panel.add_child(title)

	var spacer := Control.new()
	spacer.custom_minimum_size = Vector2(0, 20)
	panel.add_child(spacer)

	var resume_btn := _make_button(Locale.t("resume"), _on_resume)
	panel.add_child(resume_btn)

	var main_menu_btn := _make_button(Locale.t("return_main_menu"), _on_main_menu)
	panel.add_child(main_menu_btn)

	var quit_btn := _make_button(Locale.t("quit_desktop"), _on_quit)
	panel.add_child(quit_btn)

	center.add_child(panel)

	# Right spacer for visual balance
	var right_spacer := Control.new()
	right_spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hbox.add_child(right_spacer)


func _input(event: InputEvent) -> void:
	if event.is_action_pressed("pause"):
		_toggle()


func _toggle() -> void:
	if visible:
		_close()
	else:
		_open()


func _close() -> void:
	get_tree().paused = false
	hide()


func _on_resume() -> void:
	_close()


func _on_main_menu() -> void:
	get_tree().paused = false
	get_tree().change_scene_to_file("res://scenes/main_menu.tscn")


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


func _build_stats_panel() -> Control:
	var container := MarginContainer.new()
	container.add_theme_constant_override("margin_left", 24)
	container.add_theme_constant_override("margin_top", 24)

	_stats_vbox = VBoxContainer.new()
	_stats_vbox.add_theme_constant_override("separation", 2)
	container.add_child(_stats_vbox)

	return container


func _open() -> void:
	if _is_other_ui_visible():
		return
	_refresh_stats()
	get_tree().paused = true
	show()


const LABEL_WIDTH: float = 130.0
const VALUE_WIDTH: float = 100.0


func _add_section_header(text: String) -> void:
	var sep := HSeparator.new()
	_stats_vbox.add_child(sep)

	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", 14)
	label.add_theme_color_override("font_color", Color(0.85, 0.85, 0.85, 0.85))
	_stats_vbox.add_child(label)


func _add_row(label_text: String, value_text: String) -> void:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)

	var key := Label.new()
	key.text = label_text
	key.custom_minimum_size = Vector2(LABEL_WIDTH, 0)
	key.add_theme_font_size_override("font_size", 13)
	key.add_theme_color_override("font_color", Color(0.55, 0.60, 0.70))
	key.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	row.add_child(key)

	var val := Label.new()
	val.text = value_text
	val.custom_minimum_size = Vector2(VALUE_WIDTH, 0)
	val.add_theme_font_size_override("font_size", 13)
	val.add_theme_color_override("font_color", Color(0.90, 0.92, 0.95))
	row.add_child(val)

	_stats_vbox.add_child(row)


func _refresh_stats() -> void:
	for child in _stats_vbox.get_children():
		child.queue_free()

	var player := _get_player()
	var ua := _get_upgrade_applier()

	if not player or not ua:
		_add_row("(no data)", "")
		return

	# === Survival ===
	_add_section_header(Locale.t("survival"))

	var hp_max := player.health.max_hp if player.health else 0
	var hp_cur := player.health.current_hp if player.health else 0
	_add_row(Locale.t("hp"), "%d / %d" % [hp_cur, hp_max])

	var regen: float = ua.get_absolute("hp_regen")
	_add_row(Locale.t("hp_regen"), "+%.1f/s" % regen)

	var lifesteal: float = ua.get_raw("lifesteal_ratio")
	_add_row(Locale.t("lifesteal"), "%.0f%%" % (lifesteal * 100.0))

	var thorns: float = ua.get_multiplier("thorn_reflect") - 1.0
	_add_row(Locale.t("thorns"), "%.0f%%" % (thorns * 100.0))

	var ds = _get_dodge_system()
	var dodge_cd: float = 2.0
	if ds:
		var dodge_sys: DodgeSystem = ds as DodgeSystem
		if dodge_sys:
			dodge_cd = dodge_sys._effective_cooldown()
	_add_row(Locale.t("dodge_cd"), "%.2fs" % dodge_cd)

	# === Offense ===
	_add_section_header(Locale.t("offense"))

	var atk_mult: float = ua.get_multiplier("attack_speed")
	_add_row(Locale.t("atk_speed"), "%+.0f%%" % ((1.0 - atk_mult) * 100.0))

	var melee_mult: float = ua.get_multiplier("melee_damage_bonus")
	_add_row(Locale.t("melee_dmg"), "%+.0f%%" % ((melee_mult - 1.0) * 100.0))

	var ranged_mult: float = ua.get_multiplier("ranged_damage_bonus")
	_add_row(Locale.t("ranged_dmg"), "%+.0f%%" % ((ranged_mult - 1.0) * 100.0))

	var crit: float = ua.get_raw("crit_chance")
	_add_row(Locale.t("crit_chance"), "%.0f%%" % (crit * 100.0))

	var aura: float = ua.get_absolute("damage_aura")
	_add_row(Locale.t("dmg_aura"), "%.0f/s" % aura)

	# === Utility ===
	_add_section_header(Locale.t("utility"))

	var speed_flat: float = ua.get_absolute("move_speed_flat")
	var speed_mult: float = ua.get_multiplier("move_speed_bonus")
	var speed: float = (player.base_speed + speed_flat) * speed_mult
	_add_row(Locale.t("move_speed"), "%.0f" % speed)

	var pickup: float = ua.get_multiplier("pickup_radius")
	_add_row(Locale.t("pickup"), "%+.0f%%" % ((pickup - 1.0) * 100.0))

	# === Weapons ===
	var cs = _get_combat_system()
	if cs:
		var combat: CombatSystem = cs as CombatSystem
		if combat:
			_add_section_header(Locale.t("weapons"))
			if combat.left_weapon:
				_add_row("L: %s" % combat.left_weapon.get_display_name(), "%d dmg" % combat.left_weapon.base_damage)
			if combat.right_weapon:
				_add_row("R: %s" % combat.right_weapon.get_display_name(), "%d dmg" % combat.right_weapon.base_damage)


func _get_player() -> Player:
	var players := get_tree().get_nodes_in_group("players")
	if players.size() > 0:
		return players[0] as Player
	return null


func _get_upgrade_applier() -> UpgradeApplier:
	var main := get_parent().get_parent()
	if main:
		var systems := main.get_node_or_null("Systems")
		if systems:
			return systems.get_node_or_null("UpgradeApplier") as UpgradeApplier
	return null


func _get_dodge_system():
	var main := get_parent().get_parent()
	if main:
		var systems := main.get_node_or_null("Systems")
		if systems:
			return systems.get_node_or_null("DodgeSystem")
	return null


func _get_combat_system():
	var main := get_parent().get_parent()
	if main:
		var systems := main.get_node_or_null("Systems")
		if systems:
			return systems.get_node_or_null("CombatSystem")
	return null
