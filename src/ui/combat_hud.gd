extends Control
class_name CombatHUD

## In-game HUD: health bar, ammo, dodge, score, wave, kills, wave announce.
## World-space elements track player; screen-space elements use anchors.

@export var health_bar_width: float = 30.0
@export var health_bar_height: float = 3.0
@export var health_bar_offset_y: float = -21.0
@export var health_bar_tween_duration: float = 0.2
@export var hud_margin: float = 15.0
@export var wave_announce_duration: float = 2.0
@export var wave_announce_font_size: int = 36

var _player: Player
var _health_bar: ColorRect
var _health_bar_bg: ColorRect

var _dodge_dot: ColorRect
var _score_label: Label
var _wave_label: Label
var _wave_timer_label: Label
var _kills_label: Label
var _shard_label: Label
var _wave_announce: Label

var _combat_system: Node
var _dodge_system: DodgeSystem
var _score_manager: ScoreManager
var _wave_manager: WaveManager


func _ready() -> void:
	mouse_filter = MOUSE_FILTER_IGNORE
	anchor_left = 0.0
	anchor_right = 1.0
	anchor_top = 0.0
	anchor_bottom = 1.0

	_player = _find_player()
	_combat_system = _find_node_in_systems("CombatSystem")
	_dodge_system = _find_node_in_systems("DodgeSystem") as DodgeSystem
	_score_manager = _find_node_in_systems("ScoreManager") as ScoreManager
	_wave_manager = _find_node_in_systems("WaveManager") as WaveManager

	_build_health_bar()
	_build_dodge_indicator()
	_build_score_labels()
	_build_wave_announce()

	EventBus.score_changed.connect(_on_score_changed)
	EventBus.wave_started.connect(_on_wave_started)
	EventBus.player_died.connect(_on_player_died)
	EventBus.wave_completed.connect(_on_wave_completed)
	EventBus.wave_timer_updated.connect(_on_wave_timer_updated)
	EventBus.shard_collected.connect(_on_shard_collected)


func _process(_delta: float) -> void:
	if not _player or not is_instance_valid(_player):
		return
	_update_world_space_elements()
	_update_dodge()
	_update_health_bar()


# --- World-space elements ---

func _build_health_bar() -> void:
	_health_bar_bg = ColorRect.new()
	_health_bar_bg.color = Color(0.0, 0.0, 0.0, 0.5)
	_health_bar_bg.size = Vector2(health_bar_width, health_bar_height)
	_health_bar_bg.hide()
	add_child(_health_bar_bg)

	_health_bar = ColorRect.new()
	_health_bar.color = Color.GREEN
	_health_bar.size = Vector2(health_bar_width, health_bar_height)
	_health_bar.hide()
	add_child(_health_bar)


func _update_health_bar() -> void:
	if not _player or not _player.health:
		return

	var ratio := _player.health.get_hp_ratio()
	var is_full := ratio >= 1.0

	_health_bar.visible = not is_full
	_health_bar_bg.visible = not is_full

	if is_full:
		return

	var screen_pos := _world_to_screen(_player.global_position)
	var offset := Vector2(-health_bar_width / 2.0, health_bar_offset_y)
	_health_bar_bg.position = screen_pos + offset
	_health_bar.position = screen_pos + offset

	_health_bar.color = Color(1.0 - ratio, ratio, 0.0)
	_health_bar.size.x = health_bar_width * ratio


func _build_dodge_indicator() -> void:
	_dodge_dot = ColorRect.new()
	_dodge_dot.size = Vector2(6, 6)
	_dodge_dot.color = Color(0.3, 0.7, 1.0, 0.9)
	add_child(_dodge_dot)


func _update_dodge() -> void:
	if not _player or not _dodge_system:
		return

	var screen_pos := _world_to_screen(_player.global_position)
	_dodge_dot.position = screen_pos + Vector2(-22, 8)

	var ratio := _dodge_system.get_cooldown_ratio()
	if ratio >= 1.0:
		_dodge_dot.color = Color(0.3, 0.7, 1.0, 0.9)  # Ready: bright blue
	else:
		_dodge_dot.color = Color(0.3, 0.7, 1.0, 0.25)  # Cooldown: dim


func _update_world_space_elements() -> void:
	pass  # Each element updates itself in its own method


# --- Screen-space elements ---

func _build_score_labels() -> void:
	# Score
	_score_label = Label.new()
	_score_label.text = "0"
	_score_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	_score_label.add_theme_font_size_override("font_size", 13)
	_score_label.add_theme_color_override("font_color", Color.WHITE)
	_score_label.position = Vector2(hud_margin, hud_margin)
	add_child(_score_label)

	# Wave
	_wave_label = Label.new()
	_wave_label.text = "%s 0" % Locale.t("wave")
	_wave_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	_wave_label.add_theme_font_size_override("font_size", 13)
	_wave_label.add_theme_color_override("font_color", Color(1.0, 1.0, 1.0, 0.7))
	_wave_label.position = Vector2(hud_margin, hud_margin + 22)
	add_child(_wave_label)

	# Timer
	_wave_timer_label = Label.new()
	_wave_timer_label.text = "60"
	_wave_timer_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	_wave_timer_label.add_theme_font_size_override("font_size", 20)
	_wave_timer_label.add_theme_color_override("font_color", Color(1.0, 0.84, 0.0))
	_wave_timer_label.position = Vector2(hud_margin, hud_margin + 38)
	add_child(_wave_timer_label)

	# Kills
	_kills_label = Label.new()
	_kills_label.text = "%s: 0" % Locale.t("kills")
	_kills_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	_kills_label.add_theme_font_size_override("font_size", 11)
	_kills_label.add_theme_color_override("font_color", Color(1.0, 1.0, 1.0, 0.5))
	_kills_label.position = Vector2(hud_margin, hud_margin + 38)
	add_child(_kills_label)

	# Shards
	_shard_label = Label.new()
	_shard_label.text = "%s: 0" % Locale.t("shards")
	_shard_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	_shard_label.add_theme_font_size_override("font_size", 11)
	_shard_label.add_theme_color_override("font_color", Color(0.2, 0.9, 1.0, 0.8))
	_shard_label.position = Vector2(hud_margin, hud_margin + 54)
	add_child(_shard_label)


func _on_wave_timer_updated(seconds: float) -> void:
	if _wave_timer_label:
		_wave_timer_label.text = "%.0f" % seconds
		if seconds <= 10.0:
			_wave_timer_label.add_theme_color_override("font_color", Color(1.0, 0.2, 0.1))
		else:
			_wave_timer_label.add_theme_color_override("font_color", Color(1.0, 0.84, 0.0))


func _on_score_changed(new_score: int) -> void:
	_score_label.text = str(new_score)
	if _score_manager:
		_kills_label.text = "%s: %d" % [Locale.t("kills"), _score_manager.get_total_kills()]


func _on_wave_started(wave_number: int) -> void:
	if wave_number == 1:
		modulate.a = 1.0  # Reset death fade
	_wave_label.text = "%s %d" % [Locale.t("wave"), wave_number]
	_show_wave_announce(wave_number)


func _on_wave_completed(_wave_number: int) -> void:
	if _score_manager:
		_kills_label.text = "%s: %d" % [Locale.t("kills"), _score_manager.get_total_kills()]


func _on_shard_collected(_amount: int, run_total: int) -> void:
	_shard_label.text = "%s: %d" % [Locale.t("shards"), run_total]


func _on_player_died() -> void:
	# Fade out HUD on death
	var tw := create_tween()
	tw.tween_property(self, "modulate:a", 0.0, 0.5)


# --- Wave announce ---

func _build_wave_announce() -> void:
	_wave_announce = Label.new()
	_wave_announce.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_wave_announce.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_wave_announce.add_theme_font_size_override("font_size", wave_announce_font_size)
	_wave_announce.add_theme_color_override("font_color", Color(1.0, 1.0, 1.0, 0.9))
	_wave_announce.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	_wave_announce.modulate.a = 0.0
	add_child(_wave_announce)


func _show_wave_announce(wave_number: int) -> void:
	_wave_announce.text = "%s %d" % [Locale.t("wave"), wave_number]
	_wave_announce.modulate.a = 1.0

	var tw := create_tween()
	tw.tween_property(_wave_announce, "modulate:a", 0.0, wave_announce_duration).set_delay(0.3)


# --- Helpers ---

func _world_to_screen(world_pos: Vector2) -> Vector2:
	var camera := get_viewport().get_camera_2d()
	if camera:
		var vs := get_viewport().get_visible_rect().size
		return world_pos - camera.global_position + vs / 2.0
	return world_pos


func _find_player() -> Player:
	var players := get_tree().get_nodes_in_group("players")
	if players.size() > 0:
		return players[0] as Player
	return null


func _find_node_in_systems(node_name: String) -> Node:
	var parent := get_parent()
	if parent:
		var systems := parent.get_node_or_null("../Systems")
		if systems:
			return systems.get_node_or_null(node_name)
	return null
