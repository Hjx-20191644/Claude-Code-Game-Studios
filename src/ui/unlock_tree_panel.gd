extends Control
class_name UnlockTreePanel
## Meta-upgrade unlock tree: shows all nodes, allows purchase, updates on shard change.

var _tree_manager: Node
var _on_back_callback: Callable

var _panel_bg: ColorRect
var _title_label: Label
var _shard_label: Label
var _grid: GridContainer
var _back_button: Button
var _status_label: Label


func _ready() -> void:
	visible = false
	_tree_manager = _find_tree_manager()
	_build_ui()
	EventBus.shards_changed.connect(_on_shards_changed)
	EventBus.item_unlocked.connect(_on_item_unlocked)


func show_panel() -> void:
	_refresh_shard_display()
	_build_grid()
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

	# Header
	_title_label = Label.new()
	_title_label.text = Locale.t("meta_upgrades")
	_title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_title_label.add_theme_font_size_override("font_size", 32)
	_title_label.add_theme_color_override("font_color", Color(0.3, 0.7, 1.0))
	vbox.add_child(_title_label)

	_shard_label = Label.new()
	_shard_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_shard_label.add_theme_font_size_override("font_size", 20)
	_shard_label.add_theme_color_override("font_color", Color(0.2, 0.9, 1.0, 0.9))
	vbox.add_child(_shard_label)

	var spacer := Control.new()
	spacer.custom_minimum_size = Vector2(0, 24)
	vbox.add_child(spacer)

	# Grid of unlock cards
	var scroll := ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL

	_grid = GridContainer.new()
	_grid.columns = 2
	_grid.add_theme_constant_override("h_separation", 16)
	_grid.add_theme_constant_override("v_separation", 12)
	scroll.add_child(_grid)
	vbox.add_child(scroll)

	var spacer2 := Control.new()
	spacer2.custom_minimum_size = Vector2(0, 16)
	vbox.add_child(spacer2)

	_status_label = Label.new()
	_status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_status_label.add_theme_font_size_override("font_size", 16)
	_status_label.add_theme_color_override("font_color", Color(1.0, 1.0, 0.3, 0.9))
	vbox.add_child(_status_label)

	_back_button = Button.new()
	_back_button.text = Locale.t("back")
	_back_button.add_theme_font_size_override("font_size", 20)
	_back_button.custom_minimum_size = Vector2(180, 44)
	_back_button.pressed.connect(_on_back)
	vbox.add_child(_back_button)


func _build_grid() -> void:
	for child in _grid.get_children():
		child.queue_free()

	if not _tree_manager:
		_status_label.text = Locale.t("no_unlock_data")
		return

	var all: Array = _tree_manager.get_all_unlocks()
	for ul in all:
		var card := _make_card(ul)
		_grid.add_child(card)


func _make_card(ul: Resource) -> Control:
	var card := VBoxContainer.new()
	card.add_theme_constant_override("separation", 6)
	card.custom_minimum_size = Vector2(280, 100)

	var unlocked: bool = MetaProgress.is_unlocked(ul.id)
	var affordable: bool = int(ul.cost) <= MetaProgress.get_shards()
	var prereqs_met := true
	for prereq in ul.prerequisites:
		if not MetaProgress.is_unlocked(prereq):
			prereqs_met = false
			break

	var can_buy: bool = not unlocked and affordable and prereqs_met

	# Name
	var name_label := Label.new()
	name_label.text = ul.display_name
	name_label.add_theme_font_size_override("font_size", 18)
	if unlocked:
		name_label.add_theme_color_override("font_color", Color(0.3, 0.9, 0.3))
		name_label.text += "  ✓"
	else:
		name_label.add_theme_color_override("font_color", Color(1.0, 1.0, 1.0, 0.9))
	card.add_child(name_label)

	# Description
	var desc := Label.new()
	desc.text = ul.description
	desc.add_theme_font_size_override("font_size", 13)
	desc.add_theme_color_override("font_color", Color(1.0, 1.0, 1.0, 0.6))
	card.add_child(desc)

	# Cost / Status
	var cost_label := Label.new()
	if unlocked:
		cost_label.text = Locale.t("unlocked")
		cost_label.add_theme_color_override("font_color", Color(0.3, 0.9, 0.3))
	elif not prereqs_met:
		cost_label.text = "%s: %s" % [Locale.t("requires"), ", ".join(ul.prerequisites)]
		cost_label.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5))
	else:
		cost_label.text = "%s: %d %s" % [Locale.t("cost"), ul.cost, Locale.t("shard_unit")]
		cost_label.add_theme_color_override("font_color", Color(0.8, 1.0, 0.3) if affordable else Color(1.0, 0.3, 0.3))
	cost_label.add_theme_font_size_override("font_size", 14)
	card.add_child(cost_label)

	# Purchase button
	if can_buy:
		var btn := Button.new()
		btn.text = Locale.t("purchase")
		btn.add_theme_font_size_override("font_size", 16)
		btn.custom_minimum_size = Vector2(120, 36)
		btn.pressed.connect(func(): _on_purchase(ul.id))
		card.add_child(btn)

	return card


func _on_purchase(id: String) -> void:
	if _tree_manager:
		var ok: bool = _tree_manager.purchase(id)
		if ok:
			_status_label.text = Locale.t("purchased")
			_build_grid()
			_refresh_shard_display()
		else:
			_status_label.text = "%s: %s" % [Locale.t("cannot_purchase"), _tree_manager.get_purchase_block_reason(id)]


func _refresh_shard_display() -> void:
	_shard_label.text = "%s: %d" % [Locale.t("shards"), MetaProgress.get_shards()]


func _on_shards_changed(_new_total: int) -> void:
	_refresh_shard_display()


func _on_item_unlocked(_unlock_id: String) -> void:
	_refresh_shard_display()


func _on_back() -> void:
	hide()
	if _on_back_callback.is_valid():
		_on_back_callback.call()


func _find_tree_manager() -> Node:
	var parent := get_parent()
	if not parent:
		return null
	for child in parent.get_children():
		if child.has_method("get_all_unlocks"):
			return child
	return null
