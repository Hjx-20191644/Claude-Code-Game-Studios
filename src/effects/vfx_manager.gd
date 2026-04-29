extends Node
class_name VfxManager

## Visual feedback system: hit particles, screen shake, flash, vignette,
## afterimage, death burst, death sequence. Pure visual — no gameplay impact.

# Hit particles
@export var melee_hit_count: int = 10
@export var melee_hit_speed_min: float = 50.0
@export var melee_hit_speed_max: float = 150.0
@export var melee_hit_lifetime: float = 0.35

@export var ranged_hit_count: int = 5
@export var ranged_hit_speed_min: float = 80.0
@export var ranged_hit_speed_max: float = 120.0
@export var ranged_hit_lifetime: float = 0.2

@export var death_burst_count: int = 10
@export var death_burst_speed_min: float = 100.0
@export var death_burst_speed_max: float = 250.0
@export var death_burst_lifetime: float = 0.5

# Screen effects
@export var shake_intensity: float = 4.0
@export var shake_duration: float = 0.15
@export var hit_flash_duration: float = 0.1
@export var vignette_alpha: float = 0.3
@export var vignette_fade_duration: float = 0.3
@export var afterimage_alpha: float = 0.4
@export var afterimage_lifetime: float = 0.3

var _player: Player
var _camera: Camera2D
var _effects_2d: Node2D
var _vignette: ColorRect
var _death_overlay: ColorRect
var _is_dead: bool = false
var _shake_tween: Tween
var _flash_tween: Tween
var _vignette_tween: Tween


func _ready() -> void:
	_player = _find_player()
	_camera = _find_camera()
	_effects_2d = get_node("../../Arena/Effects")
	_create_overlays()

	EventBus.damage_dealt.connect(_on_damage_dealt)
	EventBus.damage_taken.connect(_on_damage_taken)
	EventBus.dodge_started.connect(_on_dodge_started)
	EventBus.enemy_killed.connect(_on_enemy_killed)
	EventBus.player_died.connect(_on_player_died)
	EventBus.wave_started.connect(_on_wave_started)


# --- Hit particles ---

func _on_damage_dealt(amount: float, hit_position: Vector2, attack_type: String) -> void:
	if _is_dead:
		return

	match attack_type:
		"melee":
			_emit_burst(hit_position, melee_hit_count, Color.WHITE,
				melee_hit_speed_min, melee_hit_speed_max, melee_hit_lifetime, 8.0)
		"ranged":
			_emit_burst(hit_position, ranged_hit_count, Color.ORANGE,
				ranged_hit_speed_min, ranged_hit_speed_max, ranged_hit_lifetime, 6.0)


# --- Player damage ---

func _on_damage_taken(_amount: float, _position: Vector2) -> void:
	if _is_dead:
		return
	_player_flash()
	_screen_shake()
	_show_vignette()


func _player_flash() -> void:
	if not _player:
		return
	var sprite := _player.get_node_or_null("Sprite") as ColorRect
	if not sprite:
		return

	if _flash_tween and _flash_tween.is_valid():
		_flash_tween.kill()

	sprite.modulate = Color.RED
	_flash_tween = create_tween()
	_flash_tween.tween_property(sprite, "modulate", Color.WHITE, hit_flash_duration)


func _screen_shake() -> void:
	if not _camera:
		return

	if _shake_tween and _shake_tween.is_valid():
		_shake_tween.kill()

	_camera.offset = Vector2.ZERO
	_shake_tween = create_tween()
	var steps := 8
	var step_dur := shake_duration / float(steps)
	for _i in steps:
		var rx := randf_range(-shake_intensity, shake_intensity)
		var ry := randf_range(-shake_intensity, shake_intensity)
		_shake_tween.tween_property(_camera, "offset", Vector2(rx, ry), step_dur)
	_shake_tween.tween_property(_camera, "offset", Vector2.ZERO, 0.0)


func _show_vignette() -> void:
	if not _vignette:
		return

	if _vignette_tween and _vignette_tween.is_valid():
		_vignette_tween.kill()

	_vignette.color.a = vignette_alpha
	_vignette.show()
	_vignette_tween = create_tween()
	_vignette_tween.tween_property(_vignette, "color:a", 0.0, vignette_fade_duration)


# --- Dodge afterimage ---

func _on_dodge_started() -> void:
	if _is_dead or not _player:
		return
	var sprite := _player.get_node_or_null("Sprite") as ColorRect
	if not sprite:
		return

	var ghost := VfxParticle.new()
	var world_pos := _player.global_position + sprite.position
	ghost.position = world_pos
	var c := sprite.color
	ghost.modulate = Color(c.r, c.g, minf(c.b + 0.2, 1.0), afterimage_alpha)
	ghost.set_draw_size(24.0)
	_effects_2d.add_child(ghost)
	ghost.play(afterimage_lifetime, Vector2.ZERO, 24.0)


# --- Enemy death burst ---

func _on_enemy_killed(_kill_type: String, position: Vector2, enemy_color: Color) -> void:
	if _is_dead:
		return
	_emit_burst(position, death_burst_count, enemy_color,
		death_burst_speed_min, death_burst_speed_max, death_burst_lifetime, 5.0)


# --- Player death ---

func _on_player_died() -> void:
	_is_dead = true

	# Gray overlay
	_death_overlay.modulate.a = 0.0
	_death_overlay.show()
	var tw := create_tween()
	tw.tween_property(_death_overlay, "modulate:a", 0.55, 0.5)

	# Slow motion
	Engine.time_scale = 0.3

	# Camera zoom if available
	if _camera:
		var zoom_tw := create_tween()
		zoom_tw.tween_property(_camera, "zoom", Vector2(1.3, 1.3), 0.6)


func _on_wave_started(wave_number: int) -> void:
	if wave_number == 1:
		_is_dead = false
		_death_overlay.hide()
		if _vignette:
			_vignette.hide()
		if _camera:
			_camera.zoom = Vector2(1.0, 1.0)
			_camera.offset = Vector2.ZERO


# --- Particle helpers ---

func _emit_burst(origin: Vector2, count: int, color: Color,
		speed_min: float, speed_max: float, lifetime: float, size: float) -> void:
	for _i in count:
		var p := VfxParticle.new()
		p.position = origin
		p.modulate = color
		_effects_2d.add_child(p)
		var angle := randf() * TAU
		var speed := randf_range(speed_min, speed_max)
		p.play(lifetime, Vector2(cos(angle), sin(angle)) * speed, size)


# --- Overlays ---

func _create_overlays() -> void:
	var hud := get_node_or_null("../../HUD")
	if not hud:
		return

	# Vignette — red edge glow on damage
	_vignette = ColorRect.new()
	_vignette.set_anchors_preset(Control.PRESET_FULL_RECT)
	_vignette.color = Color(1.0, 0.0, 0.0, 0.0)
	_vignette.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hud.add_child(_vignette)

	# Death overlay — gray on death
	_death_overlay = ColorRect.new()
	_death_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	_death_overlay.color = Color(0.1, 0.1, 0.1, 1.0)
	_death_overlay.modulate.a = 0.0
	_death_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_death_overlay.hide()
	hud.add_child(_death_overlay)


# --- Helpers ---

func _find_player() -> Player:
	var players := get_tree().get_nodes_in_group("players")
	if players.size() > 0:
		return players[0] as Player
	return null


func _find_camera() -> Camera2D:
	return get_viewport().get_camera_2d()
