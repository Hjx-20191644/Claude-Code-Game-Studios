extends Control
class_name BossHealthBar

## Screen-top boss health bar. Listens to EventBus boss signals.

@export var bar_width: float = 300.0
@export var bar_height: float = 16.0
@export var margin_top: float = 12.0

var _container: Control
var _name_label: Label
var _bar_bg: ColorRect
var _bar_fill: ColorRect
var _phase_label: Label
var _max_hp: int = 1
var _displayed_width: float = 0.0


func _ready() -> void:
	mouse_filter = MOUSE_FILTER_IGNORE
	anchor_left = 0.5
	anchor_right = 0.5
	anchor_top = 0.0

	_build()
	hide()

	EventBus.boss_spawned.connect(_on_boss_spawned)
	EventBus.boss_damaged.connect(_on_boss_damaged)
	EventBus.boss_phase_changed.connect(_on_boss_phase_changed)
	EventBus.boss_killed.connect(_on_boss_killed)


func _build() -> void:
	_container = Control.new()
	_container.position = Vector2(-bar_width / 2.0, margin_top)
	add_child(_container)

	# Boss name
	_name_label = Label.new()
	_name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_name_label.add_theme_font_size_override("font_size", 18)
	_name_label.add_theme_color_override("font_color", Color(1.0, 0.3, 0.15))
	_name_label.size = Vector2(bar_width, 24)
	_container.add_child(_name_label)

	# Bar background
	_bar_bg = ColorRect.new()
	_bar_bg.color = Color(0.1, 0.1, 0.1, 0.7)
	_bar_bg.size = Vector2(bar_width, bar_height)
	_bar_bg.position = Vector2(0, 28)
	_container.add_child(_bar_bg)

	# Bar fill
	_bar_fill = ColorRect.new()
	_bar_fill.color = Color(0.85, 0.2, 0.1)
	_bar_fill.size = Vector2(bar_width, bar_height)
	_bar_fill.position = Vector2(0, 28)
	_container.add_child(_bar_fill)

	# Phase label
	_phase_label = Label.new()
	_phase_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_phase_label.add_theme_font_size_override("font_size", 13)
	_phase_label.add_theme_color_override("font_color", Color(1.0, 0.8, 0.3))
	_phase_label.size = Vector2(bar_width, 20)
	_phase_label.position = Vector2(0, 48)
	_container.add_child(_phase_label)


func _process(_delta: float) -> void:
	# Smooth bar animation
	if _bar_fill.size.x != _displayed_width:
		_bar_fill.size.x = lerpf(_bar_fill.size.x, _displayed_width, 0.15)


func _on_boss_spawned(boss_name: String, max_hp: int) -> void:
	_max_hp = max_hp
	_displayed_width = bar_width
	_bar_fill.size.x = bar_width
	_name_label.text = boss_name
	_phase_label.text = "Phase 1"
	show()
	# Fade in
	modulate.a = 0.0
	var tw := create_tween()
	tw.tween_property(self, "modulate:a", 1.0, 0.3)


func _on_boss_damaged(current_hp: int, max_hp: int) -> void:
	_max_hp = max_hp
	var ratio: float = clampf(float(current_hp) / float(max_hp), 0.0, 1.0)
	_displayed_width = bar_width * ratio
	# Color shifts from red to yellow as HP drops
	_bar_fill.color = Color(0.85, 0.2 + 0.6 * (1.0 - ratio), 0.1)


func _on_boss_phase_changed(phase: int) -> void:
	_phase_label.text = "Phase %d" % phase
	# Flash phase label
	var tw := create_tween()
	tw.tween_property(_phase_label, "modulate:a", 0.0, 0.1)
	tw.tween_property(_phase_label, "modulate:a", 1.0, 0.2)


func _on_boss_killed(_boss_name: String) -> void:
	# Fade out
	var tw := create_tween()
	tw.tween_property(self, "modulate:a", 0.0, 0.4)
	tw.tween_callback(hide)
