extends Control
class_name UpgradeUI

## In-run upgrade selection overlay. Cards slide in from bottom, rarity glow,
## tag chips, stack counter, smooth hover/select animations.

enum State { INACTIVE, SHOWING, SELECTING, CONFIRMED }

@export var card_width: float = 220.0
@export var card_height: float = 300.0
@export var card_gap: float = 28.0
@export var slide_in_duration: float = 0.35
@export var select_anim_duration: float = 0.25
@export var exit_anim_duration: float = 0.2
@export var ui_timeout: float = 30.0

var _state: State = State.INACTIVE
var _upgrade_pool: UpgradePool
var _wave_manager: WaveManager
var _upgrades: Array[UpgradeData] = []
var _highlighted_index: int = 0
var _timeout_timer: float = 0.0

var _upgrade_names: Dictionary = {}

var _overlay: ColorRect
var _cards_hbox: HBoxContainer
var _card_panels: Array[PanelContainer] = []
var _acquired_list: VBoxContainer
var _title_label: Label
var _timer_bar: ColorRect


func _ready() -> void:
	process_mode = PROCESS_MODE_ALWAYS
	mouse_filter = MOUSE_FILTER_STOP

	_upgrade_pool = _find_upgrade_pool()
	_wave_manager = _find_wave_manager()

	_build_ui()
	EventBus.upgrade_window_requested.connect(_on_upgrade_requested)
	EventBus.upgrade_applied.connect(_on_upgrade_applied)
	EventBus.player_died.connect(_on_player_died)
	hide()


func _process(delta: float) -> void:
	if _state == State.SELECTING and visible:
		_timeout_timer -= delta
		_timer_bar.scale.x = _timeout_timer / ui_timeout
		if _timeout_timer <= 0.0:
			_confirm_selection(_highlighted_index)


func _input(event: InputEvent) -> void:
	if _state == State.INACTIVE or _state == State.CONFIRMED:
		return

	if event is InputEventKey and event.pressed:
		_handle_key(event.keycode)
	elif event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_handle_click(event.position)


# --- Signal handlers ---

func _on_upgrade_requested() -> void:
	if _state != State.INACTIVE:
		return

	_upgrades = _upgrade_pool.draw_upgrades(3)
	if _upgrades.is_empty():
		_wave_manager.upgrade_completed()
		return

	_highlighted_index = 0
	_timeout_timer = ui_timeout
	_state = State.SHOWING
	_render_cards()
	_refresh_acquired_list()
	show()
	get_tree().paused = true
	_timer_bar.scale.x = 1.0
	_animate_cards_enter()


func _on_upgrade_applied(data: Dictionary) -> void:
	_upgrade_names[data["upgrade_id"]] = data["display_name"]


func _on_player_died() -> void:
	if _state != State.INACTIVE:
		_close_ui()


# --- Input handling ---

func _handle_key(keycode: int) -> void:
	match keycode:
		KEY_1, KEY_2, KEY_3:
			var idx := keycode - KEY_1
			if idx < _upgrades.size():
				if _state == State.SELECTING:
					_confirm_selection(idx)
				else:
					_highlight_card(idx)

		KEY_LEFT, KEY_A:
			if _state == State.SELECTING and _upgrades.size() > 1:
				_highlight_card((_highlighted_index - 1 + _upgrades.size()) % _upgrades.size())

		KEY_RIGHT, KEY_D:
			if _state == State.SELECTING and _upgrades.size() > 1:
				_highlight_card((_highlighted_index + 1) % _upgrades.size())

		KEY_ENTER, KEY_SPACE:
			if _state == State.SELECTING:
				_confirm_selection(_highlighted_index)


func _handle_click(pos: Vector2) -> void:
	for i in _card_panels.size():
		var rect := _card_panels[i].get_global_rect()
		if rect.has_point(pos):
			if _state == State.SELECTING:
				_confirm_selection(i)
			elif _state == State.SHOWING:
				_highlight_card(i)
			return


# --- Card rendering ---

func _render_cards() -> void:
	_clear_cards()

	for i in _upgrades.size():
		var card := _build_card(_upgrades[i], i)
		card.modulate.a = 0.0
		card.position.y = 60.0
		_cards_hbox.add_child(card)
		_card_panels.append(card)

	_highlight_card(0)


func _build_card(data: UpgradeData, index: int) -> PanelContainer:
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(card_width, card_height)
	panel.mouse_filter = MOUSE_FILTER_STOP

	var style := _make_card_style(data.rarity)
	panel.add_theme_stylebox_override("panel", style)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 6)

	# Rarity stars
	var stars_label := Label.new()
	stars_label.text = _rarity_stars(data.rarity)
	stars_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	stars_label.add_theme_color_override("font_color", _rarity_color(data.rarity))
	stars_label.add_theme_font_size_override("font_size", 14)
	vbox.add_child(stars_label)

	# Name
	var name_label := Label.new()
	name_label.text = data.display_name
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_label.add_theme_font_size_override("font_size", 18)
	name_label.add_theme_color_override("font_color", Color(1.0, 1.0, 1.0, 0.95))
	vbox.add_child(name_label)

	# Tags as chips
	if not data.tags.is_empty():
		var tags_row := HBoxContainer.new()
		tags_row.add_theme_constant_override("separation", 4)
		for tag in data.tags:
			tags_row.add_child(_make_tag_chip(tag))
		vbox.add_child(tags_row)

	var sep := HSeparator.new()
	vbox.add_child(sep)

	# Description
	var desc_label := Label.new()
	desc_label.text = data.description
	desc_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	desc_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	desc_label.add_theme_font_size_override("font_size", 13)
	desc_label.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_child(desc_label)

	# Stack counter
	var stacks_label := Label.new()
	var current := _upgrade_pool.get_current_stacks(data.id)
	var max_s := data.max_stacks
	stacks_label.text = "Stack: %d/%d" % [current, max_s] if max_s > 0 else ""
	stacks_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	stacks_label.add_theme_font_size_override("font_size", 12)
	stacks_label.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7, 0.8))
	vbox.add_child(stacks_label)

	# Key hint
	var key_hint := Label.new()
	key_hint.text = "[%d]" % (index + 1)
	key_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	key_hint.add_theme_font_size_override("font_size", 22)
	key_hint.add_theme_color_override("font_color", _rarity_color(data.rarity))
	vbox.add_child(key_hint)

	panel.add_child(vbox)
	return panel


func _make_tag_chip(tag: String) -> Control:
	var container := PanelContainer.new()
	var style := StyleBoxFlat.new()
	style.bg_color = _tag_color(tag)
	style.corner_radius_top_left = 4
	style.corner_radius_top_right = 4
	style.corner_radius_bottom_left = 4
	style.corner_radius_bottom_right = 4
	style.content_margin_left = 6
	style.content_margin_right = 6
	style.content_margin_top = 1
	style.content_margin_bottom = 1
	container.add_theme_stylebox_override("panel", style)
	container.mouse_filter = MOUSE_FILTER_IGNORE

	var inner := Label.new()
	inner.text = tag
	inner.add_theme_font_size_override("font_size", 10)
	inner.add_theme_color_override("font_color", Color(0.1, 0.1, 0.1, 0.9))
	container.add_child(inner)
	return container


func _clear_cards() -> void:
	for panel in _card_panels:
		panel.queue_free()
	_card_panels.clear()
	for child in _cards_hbox.get_children():
		child.queue_free()


func _highlight_card(index: int) -> void:
	_highlighted_index = index
	for i in _card_panels.size():
		var panel := _card_panels[i]
		var tw: Tween = create_tween()
		tw.set_paused(false)
		if i == index:
			tw.tween_property(panel, "modulate", Color(1.0, 1.0, 1.0, 1.0), 0.15)
			tw.parallel().tween_property(panel, "scale", Vector2(1.04, 1.04), 0.15)
		else:
			tw.tween_property(panel, "modulate", Color(0.45, 0.45, 0.45, 1.0), 0.15)
			tw.parallel().tween_property(panel, "scale", Vector2(1.0, 1.0), 0.15)


func _confirm_selection(index: int) -> void:
	_state = State.CONFIRMED
	_animate_card_selected(index)

	await get_tree().create_timer(select_anim_duration + exit_anim_duration + 0.05).timeout

	var chosen := _upgrades[index]
	_upgrade_pool.acquire_upgrade(chosen.id)
	_close_ui()
	_wave_manager.upgrade_completed()


# --- Animation ---

func _animate_cards_enter() -> void:
	for i in _card_panels.size():
		var panel := _card_panels[i]
		var tw: Tween = create_tween()
		tw.set_paused(false)
		var delay := i * 0.08
		tw.tween_property(panel, "position:y", 0.0, slide_in_duration).set_ease(Tween.EASE_OUT).set_delay(delay)
		tw.parallel().tween_property(panel, "modulate:a", 1.0, slide_in_duration).set_ease(Tween.EASE_OUT).set_delay(delay)

	if slide_in_duration > 0.0:
		await get_tree().create_timer(slide_in_duration + _card_panels.size() * 0.08).timeout
	if _state == State.SHOWING:
		_state = State.SELECTING


func _animate_card_selected(index: int) -> void:
	for i in _card_panels.size():
		var panel := _card_panels[i]
		var tw: Tween = create_tween()
		tw.set_paused(false)
		if i == index:
			tw.tween_property(panel, "scale", Vector2(1.12, 1.12), select_anim_duration * 0.4)
			tw.tween_property(panel, "scale", Vector2(1.05, 1.05), select_anim_duration * 0.6)
			tw.parallel().tween_property(panel, "modulate", Color(1.0, 1.0, 1.0, 1.0), select_anim_duration)
		else:
			tw.tween_property(panel, "modulate:a", 0.0, exit_anim_duration)
			tw.parallel().tween_property(panel, "scale", Vector2(0.9, 0.9), exit_anim_duration)


# --- Helpers ---

func _close_ui() -> void:
	get_tree().paused = false
	_state = State.INACTIVE
	hide()


func _build_ui() -> void:
	anchor_left = 0.0
	anchor_right = 1.0
	anchor_top = 0.0
	anchor_bottom = 1.0

	_overlay = ColorRect.new()
	_overlay.color = Color(0.0, 0.0, 0.0, 0.5)
	_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(_overlay)

	_title_label = Label.new()
	_title_label.text = "Choose an Upgrade"
	_title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_title_label.add_theme_font_size_override("font_size", 28)
	_title_label.add_theme_color_override("font_color", Color(1.0, 1.0, 1.0, 0.9))
	_title_label.set_anchors_and_offsets_preset(Control.PRESET_CENTER_TOP)
	_title_label.position.y = 50.0
	add_child(_title_label)

	# Timeout bar
	_timer_bar = ColorRect.new()
	_timer_bar.color = Color(1.0, 0.3, 0.3, 0.6)
	_timer_bar.size = Vector2(300, 4)
	_timer_bar.position = Vector2(490, 90)
	add_child(_timer_bar)

	# Cards
	var center_cards := CenterContainer.new()
	center_cards.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(center_cards)

	_cards_hbox = HBoxContainer.new()
	_cards_hbox.add_theme_constant_override("separation", int(card_gap))
	center_cards.add_child(_cards_hbox)

	# Acquired list
	_acquired_list = VBoxContainer.new()
	_acquired_list.add_theme_constant_override("separation", 2)
	_acquired_list.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_LEFT, Control.PRESET_MODE_KEEP_SIZE, 20)
	_acquired_list.position = Vector2(16.0, -16.0)
	add_child(_acquired_list)


func _refresh_acquired_list() -> void:
	for child in _acquired_list.get_children():
		child.queue_free()

	var label := Label.new()
	label.text = "Acquired:"
	label.add_theme_font_size_override("font_size", 14)
	label.add_theme_color_override("font_color", Color(1.0, 1.0, 1.0, 0.6))
	_acquired_list.add_child(label)

	var acquired := _upgrade_pool.get_all_acquired()
	if acquired.is_empty():
		var empty := Label.new()
		empty.text = "  (none)"
		empty.add_theme_font_size_override("font_size", 12)
		empty.add_theme_color_override("font_color", Color(1.0, 1.0, 1.0, 0.3))
		_acquired_list.add_child(empty)
	else:
		for upgrade_id: String in acquired:
			var stacks: int = acquired[upgrade_id]
			var entry := Label.new()
			var display_name: String = _upgrade_names.get(upgrade_id, upgrade_id)
			entry.text = "  %s x%d" % [display_name, stacks]
			entry.add_theme_font_size_override("font_size", 12)
			entry.add_theme_color_override("font_color", Color(0.8, 0.8, 1.0, 0.7))
			_acquired_list.add_child(entry)


func _make_card_style(rarity: int) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.border_width_left = 3
	style.border_width_right = 3
	style.border_width_top = 3
	style.border_width_bottom = 3
	style.border_color = _rarity_color(rarity)
	style.bg_color = Color(0.06, 0.06, 0.10, 0.94)
	style.shadow_color = _rarity_color(rarity)
	style.shadow_size = 6 if rarity >= UpgradeData.Rarity.RARE else 2
	style.corner_radius_top_left = 10
	style.corner_radius_top_right = 10
	style.corner_radius_bottom_left = 10
	style.corner_radius_bottom_right = 10
	style.content_margin_left = 14
	style.content_margin_right = 14
	style.content_margin_top = 14
	style.content_margin_bottom = 14
	return style


func _rarity_color(rarity: int) -> Color:
	match rarity:
		UpgradeData.Rarity.COMMON:
			return Color(0.7, 0.7, 0.7)
		UpgradeData.Rarity.UNCOMMON:
			return Color(0.2, 0.85, 0.3)
		UpgradeData.Rarity.RARE:
			return Color(0.25, 0.45, 1.0)
	return Color.WHITE


func _rarity_stars(rarity: int) -> String:
	match rarity:
		UpgradeData.Rarity.COMMON:
			return "★"
		UpgradeData.Rarity.UNCOMMON:
			return "★★"
		UpgradeData.Rarity.RARE:
			return "★★★"
	return "?"


func _tag_color(tag: String) -> Color:
	match tag:
		"melee": return Color(0.8, 0.3, 0.2, 0.85)
		"ranged": return Color(0.2, 0.5, 0.9, 0.85)
		"offense": return Color(0.85, 0.35, 0.1, 0.85)
		"defense": return Color(0.2, 0.65, 0.3, 0.85)
		"movement": return Color(0.6, 0.3, 0.9, 0.85)
		"dodge": return Color(0.2, 0.7, 0.8, 0.85)
		"utility": return Color(0.5, 0.5, 0.5, 0.85)
		"healing": return Color(0.9, 0.3, 0.5, 0.85)
		"aoe": return Color(0.9, 0.6, 0.1, 0.85)
		"regen": return Color(0.3, 0.7, 0.4, 0.85)
		"reflect": return Color(0.7, 0.7, 0.2, 0.85)
	return Color(0.4, 0.4, 0.4, 0.85)


func _find_upgrade_pool() -> UpgradePool:
	var parent := get_parent()
	if parent:
		var systems := parent.get_node_or_null("../Systems")
		if systems:
			return systems.get_node_or_null("UpgradePool") as UpgradePool
	return null


func _find_wave_manager() -> WaveManager:
	var parent := get_parent()
	if parent:
		var systems := parent.get_node_or_null("../Systems")
		if systems:
			return systems.get_node_or_null("WaveManager") as WaveManager
	return null
