extends Control
class_name UpgradeUI

## In-run upgrade selection overlay.
## Listens for upgrade_window_requested, draws 3 cards, pauses game, handles input.

enum State { INACTIVE, SHOWING, SELECTING, CONFIRMED }

@export var card_width: float = 200.0
@export var card_height: float = 280.0
@export var card_gap: float = 24.0
@export var slide_in_duration: float = 0.3
@export var select_anim_duration: float = 0.2
@export var exit_anim_duration: float = 0.2
@export var ui_timeout: float = 30.0

var _state: State = State.INACTIVE
var _upgrade_pool: UpgradePool
var _wave_manager: WaveManager
var _upgrades: Array[UpgradeData] = []
var _highlighted_index: int = 0
var _timeout_timer: float = 0.0

var _upgrade_names: Dictionary = {}  # upgrade_id -> display_name

var _overlay: ColorRect
var _cards_hbox: HBoxContainer
var _card_panels: Array[PanelContainer] = []
var _acquired_list: VBoxContainer
var _title_label: Label


func _ready() -> void:
	process_mode = PROCESS_MODE_ALWAYS
	mouse_filter = MOUSE_FILTER_STOP

	_upgrade_pool = _find_upgrade_pool()
	_wave_manager = _find_wave_manager()
	assert(_upgrade_pool, "UpgradeUI: UpgradePool not found")
	assert(_wave_manager, "UpgradeUI: WaveManager not found")

	_build_ui()
	EventBus.upgrade_window_requested.connect(_on_upgrade_requested)
	EventBus.upgrade_applied.connect(_on_upgrade_applied)
	EventBus.player_died.connect(_on_player_died)
	hide()


func _process(delta: float) -> void:
	if _state == State.SELECTING and visible:
		_timeout_timer -= delta
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
		return  # Prevent double-trigger

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


# --- Card management ---

func _render_cards() -> void:
	_clear_cards()

	for i in _upgrades.size():
		var card := _build_card(_upgrades[i], i)
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
	vbox.add_theme_constant_override("separation", 8)

	var name_label := Label.new()
	name_label.text = data.display_name
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_label.add_theme_font_size_override("font_size", 18)

	var rarity_label := Label.new()
	rarity_label.text = _rarity_text(data.rarity)
	rarity_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	rarity_label.add_theme_color_override("font_color", _rarity_color(data.rarity))
	rarity_label.add_theme_font_size_override("font_size", 12)

	var sep := HSeparator.new()

	var desc_label := Label.new()
	desc_label.text = data.description
	desc_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	desc_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	desc_label.add_theme_font_size_override("font_size", 13)
	desc_label.size_flags_vertical = Control.SIZE_EXPAND_FILL

	var key_hint := Label.new()
	key_hint.text = "[%d]" % (index + 1)
	key_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	key_hint.add_theme_font_size_override("font_size", 22)
	key_hint.add_theme_color_override("font_color", Color(1.0, 1.0, 1.0, 0.5))

	vbox.add_child(name_label)
	vbox.add_child(rarity_label)
	vbox.add_child(sep)
	vbox.add_child(desc_label)
	vbox.add_child(key_hint)

	panel.add_child(vbox)
	return panel


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
		if i == index:
			panel.modulate = Color(1.0, 1.0, 1.0, 1.0)
		else:
			panel.modulate = Color(0.55, 0.55, 0.55, 1.0)


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
	# MVP: instant appear with short delay for "feel" (avoid tween-during-pause issues)
	for panel in _card_panels:
		panel.modulate.a = 1.0
	if slide_in_duration > 0.0:
		await get_tree().create_timer(slide_in_duration).timeout
	if _state == State.SHOWING:
		_state = State.SELECTING


func _animate_card_selected(index: int) -> void:
	for i in _card_panels.size():
		var panel := _card_panels[i]
		if i == index:
			panel.scale = Vector2(1.05, 1.05)
		else:
			panel.modulate.a = 0.0


# --- Private helpers ---

func _close_ui() -> void:
	get_tree().paused = false
	_state = State.INACTIVE
	hide()


func _build_ui() -> void:
	anchor_left = 0.0
	anchor_right = 1.0
	anchor_top = 0.0
	anchor_bottom = 1.0

	# Semi-transparent background overlay
	_overlay = ColorRect.new()
	_overlay.color = Color(0.0, 0.0, 0.0, 0.45)
	_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(_overlay)

	# Title
	_title_label = Label.new()
	_title_label.text = "Choose an Upgrade"
	_title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_title_label.add_theme_font_size_override("font_size", 24)
	_title_label.set_anchors_and_offsets_preset(Control.PRESET_CENTER_TOP)
	_title_label.position.y = 60.0
	add_child(_title_label)

	# Cards container (center of screen via CenterContainer)
	var center_cards := CenterContainer.new()
	center_cards.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(center_cards)

	_cards_hbox = HBoxContainer.new()
	_cards_hbox.add_theme_constant_override("separation", int(card_gap))
	center_cards.add_child(_cards_hbox)

	# Acquired upgrades list (bottom-left)
	_acquired_list = VBoxContainer.new()
	_acquired_list.add_theme_constant_override("separation", 2)
	_acquired_list.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_LEFT, Control.PRESET_MODE_KEEP_SIZE, 20)
	_acquired_list.position = Vector2(16.0, -16.0)
	add_child(_acquired_list)


func _build_acquired_list() -> void:
	pass  # Built on-demand in _refresh_acquired_list


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
	style.border_width_left = 2
	style.border_width_right = 2
	style.border_width_top = 2
	style.border_width_bottom = 2
	style.border_color = _rarity_color(rarity)
	style.bg_color = Color(0.08, 0.08, 0.12, 0.92)
	style.corner_radius_top_left = 8
	style.corner_radius_top_right = 8
	style.corner_radius_bottom_left = 8
	style.corner_radius_bottom_right = 8
	style.content_margin_left = 12
	style.content_margin_right = 12
	style.content_margin_top = 12
	style.content_margin_bottom = 12
	return style


func _rarity_color(rarity: int) -> Color:
	match rarity:
		UpgradeData.Rarity.COMMON:
			return Color(0.8, 0.8, 0.8)
		UpgradeData.Rarity.UNCOMMON:
			return Color(0.2, 0.8, 0.3)
		UpgradeData.Rarity.RARE:
			return Color(0.2, 0.4, 1.0)
	return Color.WHITE


func _rarity_text(rarity: int) -> String:
	match rarity:
		UpgradeData.Rarity.COMMON:
			return "COMMON"
		UpgradeData.Rarity.UNCOMMON:
			return "UNCOMMON"
		UpgradeData.Rarity.RARE:
			return "RARE"
	return "???"


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
