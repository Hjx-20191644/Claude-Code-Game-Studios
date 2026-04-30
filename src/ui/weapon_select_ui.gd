extends Control
class_name WeaponSelectUI

## Pre-game weapon selection panel. Shows available weapons,
## lets player pick left + right slots, then starts the game.

var _on_start_callback: Callable
var _on_back_callback: Callable

var _weapons: Array[WeaponData] = []
var _left_index: int = 0
var _right_index: int = 0

var _left_btn: OptionButton
var _right_btn: OptionButton
var _left_stats: Label
var _right_stats: Label


func _ready() -> void:
	mouse_filter = MOUSE_FILTER_STOP
	_weapons = WeaponSelection.get_available_weapons()
	_build_ui()
	hide()


func show_panel() -> void:
	_populate_buttons()
	_refresh_stats()
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
	panel.add_theme_constant_override("separation", 16)

	var title := Label.new()
	title.text = "Select Weapons"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 32)
	title.add_theme_color_override("font_color", Color(0.3, 0.7, 1.0))
	panel.add_child(title)

	var spacer := Control.new()
	spacer.custom_minimum_size = Vector2(0, 8)
	panel.add_child(spacer)

	# Two columns: left weapon + right weapon
	var cols := HBoxContainer.new()
	cols.add_theme_constant_override("separation", 40)

	# Left column
	var left_col := VBoxContainer.new()
	left_col.add_theme_constant_override("separation", 8)

	var left_label := Label.new()
	left_label.text = "Left Hand (Melee/Ranged)"
	left_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	left_label.add_theme_font_size_override("font_size", 16)
	left_label.add_theme_color_override("font_color", Color(1.0, 1.0, 1.0, 0.7))
	left_col.add_child(left_label)

	_left_btn = OptionButton.new()
	_left_btn.add_theme_font_size_override("font_size", 16)
	_left_btn.custom_minimum_size = Vector2(200, 0)
	_left_btn.item_selected.connect(_on_left_selected)
	left_col.add_child(_left_btn)

	_left_stats = Label.new()
	_left_stats.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_left_stats.add_theme_font_size_override("font_size", 13)
	_left_stats.add_theme_color_override("font_color", Color(0.8, 0.8, 0.8, 0.8))
	left_col.add_child(_left_stats)

	cols.add_child(left_col)

	# Right column
	var right_col := VBoxContainer.new()
	right_col.add_theme_constant_override("separation", 8)

	var right_label := Label.new()
	right_label.text = "Right Hand (Melee/Ranged)"
	right_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	right_label.add_theme_font_size_override("font_size", 16)
	right_label.add_theme_color_override("font_color", Color(1.0, 1.0, 1.0, 0.7))
	right_col.add_child(right_label)

	_right_btn = OptionButton.new()
	_right_btn.add_theme_font_size_override("font_size", 16)
	_right_btn.custom_minimum_size = Vector2(200, 0)
	_right_btn.item_selected.connect(_on_right_selected)
	right_col.add_child(_right_btn)

	_right_stats = Label.new()
	_right_stats.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_right_stats.add_theme_font_size_override("font_size", 13)
	_right_stats.add_theme_color_override("font_color", Color(0.8, 0.8, 0.8, 0.8))
	right_col.add_child(_right_stats)

	cols.add_child(right_col)
	panel.add_child(cols)

	var spacer2 := Control.new()
	spacer2.custom_minimum_size = Vector2(0, 16)
	panel.add_child(spacer2)

	# Buttons row
	var btns := HBoxContainer.new()
	btns.add_theme_constant_override("separation", 16)

	var back_btn := Button.new()
	back_btn.text = "Back"
	back_btn.add_theme_font_size_override("font_size", 20)
	back_btn.custom_minimum_size = Vector2(140, 44)
	back_btn.pressed.connect(_on_back)
	btns.add_child(back_btn)

	var start_btn := Button.new()
	start_btn.text = "Start Game"
	start_btn.add_theme_font_size_override("font_size", 20)
	start_btn.custom_minimum_size = Vector2(180, 44)
	start_btn.pressed.connect(_on_start)
	btns.add_child(start_btn)

	panel.add_child(btns)
	center.add_child(panel)


func _populate_buttons() -> void:
	_left_btn.clear()
	_right_btn.clear()
	for w in _weapons:
		var label := "%s [%s]" % [w.weapon_name, _type_icon(w.weapon_type)]
		_left_btn.add_item(label)
		_right_btn.add_item(label)
	# Select defaults
	for i in _weapons.size():
		if _weapons[i].weapon_name == "双匕首":
			_left_btn.select(i)
			_left_index = i
		if _weapons[i].weapon_name == "霰弹枪":
			_right_btn.select(i)
			_right_index = i


func _on_left_selected(idx: int) -> void:
	_left_index = idx
	WeaponSelection.left_weapon_id = _file_id(_weapons[idx])
	_refresh_stats()


func _on_right_selected(idx: int) -> void:
	_right_index = idx
	WeaponSelection.right_weapon_id = _file_id(_weapons[idx])
	_refresh_stats()


func _on_start() -> void:
	if _on_start_callback.is_valid():
		_on_start_callback.call()


func _on_back() -> void:
	hide()
	if _on_back_callback.is_valid():
		_on_back_callback.call()


func _refresh_stats() -> void:
	_left_stats.text = _stats_text(_weapons[_left_index])
	_right_stats.text = _stats_text(_weapons[_right_index])


func _stats_text(w: WeaponData) -> String:
	if w.weapon_type == "melee":
		return "DMG:%d  CD:%.2fs  Angle:%d°  Range:%d" % [w.base_damage, w.attack_cooldown, int(w.melee_angle), int(w.melee_radius)]
	else:
		var extra := ""
		if w.pierce_count > 0:
			extra += " Pierce:%d" % w.pierce_count
		if w.explosive_radius > 0.0:
			extra += " Explosive"
		if w.bullet_count > 1:
			extra += " x%d" % w.bullet_count
		return "DMG:%d  CD:%.2fs  Ammo:%d  Range:%d%s" % [w.base_damage, w.attack_cooldown, w.max_ammo, int(w.max_range), extra]


func _file_id(w: WeaponData) -> String:
	# Derive file ID from weapon name: translate to lowercase pinyin/snake
	match w.weapon_name:
		"双匕首": return "dual_daggers"
		"大剑": return "great_sword"
		"长剑": return "longsword"
		"长矛": return "spear"
		"巨锤": return "warhammer"
		"拳套": return "fists"
		"手枪": return "pistol"
		"霰弹枪": return "shotgun"
		"步枪": return "rifle"
		"冲锋枪": return "smg"
		"弩": return "crossbow"
		"榴弹": return "grenade"
	return ""


func _type_icon(type_str: String) -> String:
	return "⚔" if type_str == "melee" else "➹"
