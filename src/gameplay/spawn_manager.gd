extends Node
class_name SpawnManager

## Enemy spawn system: creates enemies at valid positions around the player.
## Stateless — each spawn_enemies() call is independent.

@export var spawn_min_distance: float = 150.0
@export var spawn_max_distance: float = 300.0
@export var spawn_angle_spread: float = 30.0
@export var max_spawn_retries: int = 3

const PA = preload("res://src/visuals/pixel_art.gd")
const ST = preload("res://src/visuals/sprite_templates.gd")

var _enemy_scene: PackedScene = preload("res://scenes/enemy.tscn")
var _elite_spawned_this_wave: bool = false
var _spawn_indicator_enabled: bool = true

# Type → data file ID mapping
var _type_data_map := {
	"melee": "melee_enemy",
	"ranged": "ranged_enemy",
	"charger": "charger",
	"exploder": "exploder",
	"tank": "tank",
	"boss": "warlord",
	"spawner": "spawner",
	"egg": "egg",
	"buffer": "buffer",
	"reward": "reward",
}

@onready var _player: Player = _find_player()
@onready var _enemies_container: Node2D = $"../../Arena/Enemies"


func _ready() -> void:
	assert(spawn_max_distance > spawn_min_distance, "SpawnManager: max_distance must be > min_distance")
	EventBus.wave_started.connect(_on_wave_started)

func _on_wave_started(_wave_number: int) -> void:
	_elite_spawned_this_wave = false


## Spawn N enemies of a given type. Called by WaveManager.
func spawn_enemies(enemy_type: String, count: int, wave_number: int = 1, spawn_delay: float = 0.4) -> void:
	assert(enemy_type in _type_data_map, "SpawnManager: unknown enemy_type '%s'" % enemy_type)
	if count <= 0:
		return

	var data_id: String = _type_data_map[enemy_type]
	var data := GameConfig.get_enemy_data(data_id)
	if not data:
		push_warning("SpawnManager: enemy data not found for type '%s'" % enemy_type)
		return

	# Boss: spawn at arena center with intro delay, no elite
	if enemy_type == "boss":
		var center := _get_arena_rect().get_center()
		await get_tree().create_timer(0.8).timeout  # intro anticipation
		await _spawn_one(center, data, wave_number, false, enemy_type == "boss")
		# boss_spawned is emitted by enemy._ready() with scaled HP
		EventBus.wave_spawn_complete.emit(count, enemy_type)
		return

	var elite_wave := wave_number > 0 and wave_number % 5 == 0
	var base_angle := randf() * TAU
	var is_boss_spawn := false

	for i in count:
		var pos := _compute_spawn_position(base_angle, i)
		var is_elite := elite_wave and not _elite_spawned_this_wave
		await _spawn_one(pos, data, wave_number, is_elite, is_boss_spawn)
		if is_elite:
			_elite_spawned_this_wave = true
		if spawn_delay > 0.0 and i < count - 1:
			await get_tree().create_timer(spawn_delay).timeout

	EventBus.wave_spawn_complete.emit(count, enemy_type)


func _compute_spawn_position(base_angle: float, _index: int) -> Vector2:
	var angle := base_angle + deg_to_rad(randf_range(-spawn_angle_spread, spawn_angle_spread))
	var distance := randf_range(spawn_min_distance, spawn_max_distance)
	var pos := _player.global_position + Vector2(cos(angle), sin(angle)) * distance
	pos = _clamp_to_arena(pos)

	# Retry if too close after boundary clamping
	var retries := 0
	while _player.global_position.distance_to(pos) < spawn_min_distance and retries < max_spawn_retries:
		angle = base_angle + deg_to_rad(randf_range(-spawn_angle_spread, spawn_angle_spread))
		distance = randf_range(spawn_min_distance, spawn_max_distance)
		pos = _player.global_position + Vector2(cos(angle), sin(angle)) * distance
		pos = _clamp_to_arena(pos)
		retries += 1

	return pos


const SPAWN_BLOCK_RADIUS: float = 38.0

func _spawn_one(pos: Vector2, data: EnemyData, wave_number: int, is_elite: bool = false, _skip_indicator: bool = false) -> void:
	var waves_elapsed := maxi(0, wave_number - 1)

	# Spawn indicator: flash red marker, player can block by standing on it
	var blocked: bool = false
	if _spawn_indicator_enabled and not _skip_indicator:
		var indicator: Node2D = _show_spawn_indicator(pos)
		var elapsed: float = 0.0
		while elapsed < 0.55:
			var dt := get_process_delta_time()
			elapsed += dt
			await get_tree().process_frame
			if _player and is_instance_valid(_player):
				if _player.global_position.distance_to(pos) < SPAWN_BLOCK_RADIUS:
					blocked = true
					break
		if is_instance_valid(indicator):
			indicator.queue_free()

	if blocked:
		return

	var enemy := _enemy_scene.instantiate() as Enemy

	# Dual-segment numeric design: base + wave * growth (not percentage)
	var scaled := data.duplicate() as EnemyData

	if data.enemy_type == "boss":
		scaled.max_hp = data.max_hp + waves_elapsed * 15
		scaled.contact_damage = data.contact_damage + waves_elapsed * 2
	elif data.enemy_type == "melee":
		scaled.max_hp = data.max_hp + waves_elapsed * 1
		scaled.contact_damage = data.contact_damage + waves_elapsed / 2
	elif data.enemy_type == "charger" or data.enemy_type == "tank":
		var growth: int = 12 if data.enemy_type == "tank" else 5
		scaled.max_hp = data.max_hp + waves_elapsed * growth
		scaled.contact_damage = data.contact_damage + waves_elapsed * 2
	elif data.enemy_type == "ranged" or data.enemy_type == "exploder":
		scaled.max_hp = data.max_hp + waves_elapsed * 2
		scaled.contact_damage = data.contact_damage + waves_elapsed
	elif data.enemy_type == "spawner":
		scaled.max_hp = data.max_hp + waves_elapsed * 3
		scaled.contact_damage = data.contact_damage + waves_elapsed
	elif data.enemy_type == "egg":
		scaled.max_hp = data.max_hp + waves_elapsed * 2
	elif data.enemy_type == "buffer":
		scaled.max_hp = data.max_hp + waves_elapsed * 2
	elif data.enemy_type == "reward":
		scaled.max_hp = data.max_hp + waves_elapsed * 2
	else:
		scaled.max_hp = data.max_hp + waves_elapsed * 3
		scaled.contact_damage = data.contact_damage + waves_elapsed

	if is_elite:
		scaled.is_elite = true
		scaled.contact_damage = int(scaled.contact_damage * scaled.elite_damage_mult)
		scaled.bullet_damage = int(scaled.bullet_damage * scaled.elite_damage_mult)

	enemy.enemy_data = scaled
	enemy.global_position = pos
	_enemies_container.add_child(enemy)


func _show_spawn_indicator(pos: Vector2) -> Node2D:
	var marker := Sprite2D.new()
	marker.texture = PA.generate_sprite(24, 24, ST.enemy_ref_melee_sprite, [PA.MATERIAL_FLESH])
	marker.self_modulate = Color(1.0, 0.12, 0.08)
	marker.scale = Vector2(1.3, 1.3)
	marker.global_position = pos
	_enemies_container.add_child(marker)
	var tw := create_tween()
	tw.set_loops()
	tw.tween_property(marker, "modulate:a", 0.1, 0.1)
	tw.tween_property(marker, "modulate:a", 1.0, 0.1)
	return marker


func _clamp_to_arena(pos: Vector2) -> Vector2:
	var rect := _get_arena_rect()
	pos.x = clampf(pos.x, rect.position.x, rect.end.x)
	pos.y = clampf(pos.y, rect.position.y, rect.end.y)
	return pos


func _get_arena_rect() -> Rect2:
	return Rect2(105, 45, GameConfig.ARENA_WIDTH, GameConfig.ARENA_HEIGHT)


func _find_player() -> Player:
	var players := get_tree().get_nodes_in_group("players")
	if players.size() > 0:
		return players[0] as Player
	return null
