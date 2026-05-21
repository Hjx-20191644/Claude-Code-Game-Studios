extends Control
class_name WeaponSelectUI

## Pre-game weapon selection panel. Shows available weapons,
## lets player pick left + right slots, then starts the game.
## Custom dropdown boxes — avoids Godot's PopupMenu which breaks
## under canvas_items stretch + fullscreen.

var _on_start_callback: Callable
var _on_back_callback: Callable

var _weapons: Array[WeaponData] = []
var _left_index: int = 0
var _right_index: int = 0

var _left_dropdown: Control
var _right_dropdown: Control
var _left_stats: Label
var _right_stats: Label


func _ready() -> void:
	mouse_filter = MOUSE_FILTER_STOP
	_weapons = WeaponSelection.get_available_weapons()
	# Fallback: if DirAccess failed, load weapons by known paths
	if _weapons.is_empty():
		_weapons = _load_weapons_fallback()
	# Set default selections
	for i in _weapons.size():
		match _weapons[i].weapon_name:
			"双匕首": _left_index = i
			"霰弹枪": _right_index = i
	if _weapons.size() > 0:
		WeaponSelection.left_weapon_id = _file_id(_weapons[_left_index])
		WeaponSelection.right_weapon_id = _file_id(_weapons[_right_index])
	_build_ui()
	hide()


func _load_weapons_fallback() -> Array[WeaponData]:
	var result: Array[WeaponData] = []
	var known := ["dual_daggers", "great_sword", "pistol", "shotgun",
		"fists", "spear", "warhammer", "smg", "grenade",
		"longsword", "crossbow", "rifle", "sniper"]
	for id in known:
		var path := "res://assets/data/weapons/%s.tres" % id
		if ResourceLoader.exists(path):
			var w := load(path) as WeaponData
			if w:
				result.append(w)
	result.sort_custom(func(a, b): return a.weapon_name < b.weapon_name)
	return result


func show_panel() -> void:
	_refresh_dropdown_labels()
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

	_left_dropdown = _build_dropdown(func(idx: int): _on_left_selected(idx))
	left_col.add_child(_left_dropdown)

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

	_right_dropdown = _build_dropdown(func(idx: int): _on_right_selected(idx))
	right_col.add_child(_right_dropdown)

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


func _build_dropdown(on_select: Callable) -> Control:
	var container := Control.new()
	container.custom_minimum_size = Vector2(200, 28)
	container.mouse_filter = MOUSE_FILTER_PASS

	# Trigger button (always visible, anchored to top)
	var btn := Button.new()
	btn.name = "TriggerBtn"
	btn.text = ""
	btn.add_theme_font_size_override("font_size", 16)
	btn.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	btn.mouse_filter = MOUSE_FILTER_STOP
	btn.pressed.connect(func():
		var list := container.get_node_or_null("DropList") as Control
		if list:
			list.visible = not list.visible
			if list.visible:
				container.custom_minimum_size.y = 28 + list.custom_minimum_size.y
				# Hide other dropdown if open
				var other: Control = null
				if container == _right_dropdown:
					other = _left_dropdown
				elif container == _left_dropdown:
					other = _right_dropdown
				if other:
					var other_list := other.get_node_or_null("DropList") as Control
					if other_list and other_list.visible:
						other_list.visible = false
						other.custom_minimum_size.y = 28
			else:
				container.custom_minimum_size.y = 28
	)
	container.add_child(btn)

	# Dropdown list — manually positioned below the button
	var list := Control.new()
	list.name = "DropList"
	list.mouse_filter = MOUSE_FILTER_STOP
	list.visible = false
	list.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	list.offset_top = 28

	var list_vbox := VBoxContainer.new()
	list_vbox.add_theme_constant_override("separation", 0)
	list_vbox.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	list.add_child(list_vbox)

	var bg_style := StyleBoxFlat.new()
	bg_style.bg_color = Color(0.12, 0.12, 0.16, 0.98)
	bg_style.border_width_left = 2
	bg_style.border_width_right = 2
	bg_style.border_width_top = 2
	bg_style.border_width_bottom = 2
	bg_style.border_color = Color(0.3, 0.7, 1.0, 0.6)
	bg_style.corner_radius_top_left = 0
	bg_style.corner_radius_top_right = 0
	bg_style.corner_radius_bottom_left = 0
	bg_style.corner_radius_bottom_right = 0

	var bg := PanelContainer.new()
	bg.add_theme_stylebox_override("panel", bg_style)
	bg.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	bg.mouse_filter = MOUSE_FILTER_STOP
	list_vbox.add_child(bg)

	var items := VBoxContainer.new()
	items.add_theme_constant_override("separation", 0)
	bg.add_child(items)

	var item_style := StyleBoxFlat.new()
	item_style.bg_color = Color(0, 0, 0, 0)

	var hover_style := StyleBoxFlat.new()
	hover_style.bg_color = Color(0.25, 0.25, 0.35, 0.9)

	for i in _weapons.size():
		var w := _weapons[i]
		var row := Button.new()
		row.text = "%s [%s]" % [w.weapon_name, _type_icon(w.weapon_type)]
		row.alignment = HORIZONTAL_ALIGNMENT_LEFT
		row.add_theme_font_size_override("font_size", 14)
		row.add_theme_stylebox_override("normal", item_style)
		row.add_theme_stylebox_override("hover", hover_style)
		row.custom_minimum_size = Vector2(200, 28)
		var idx := i
		row.pressed.connect(func():
			on_select.call(idx)
			list.visible = false
			# Shrink container back to button-only height
			container.custom_minimum_size.y = 28
		)
		items.add_child(row)

	list_vbox.size = Vector2(200, 28 * _weapons.size())
	list.custom_minimum_size = Vector2(200, 28 * _weapons.size())

	container.add_child(list)
	return container


func _refresh_dropdown_labels() -> void:
	_refresh_one_dropdown(_left_dropdown, _left_index)
	_refresh_one_dropdown(_right_dropdown, _right_index)


func _refresh_one_dropdown(dd: Control, idx: int) -> void:
	var btn := dd.get_node_or_null("TriggerBtn") as Button
	if btn and idx >= 0 and idx < _weapons.size():
		var w := _weapons[idx]
		if w:
			btn.text = "%s [%s]" % [w.weapon_name, _type_icon(w.weapon_type)]
		else:
			btn.text = "—"
	else:
		btn.text = "—" if btn else ""
	# Ensure dropdown list is closed
	var list := dd.get_node_or_null("DropList") as Control
	if list:
		list.visible = false
	dd.custom_minimum_size.y = 28


func _on_left_selected(idx: int) -> void:
	_left_index = idx
	WeaponSelection.left_weapon_id = _file_id(_weapons[idx])
	_refresh_one_dropdown(_left_dropdown, idx)
	_refresh_stats()


func _on_right_selected(idx: int) -> void:
	_right_index = idx
	WeaponSelection.right_weapon_id = _file_id(_weapons[idx])
	_refresh_one_dropdown(_right_dropdown, idx)
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
