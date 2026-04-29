extends Node
class_name SpawnManager

## Enemy spawn system: creates enemies at valid positions around the player.
## Stateless — each spawn_enemies() call is independent.

@export var spawn_min_distance: float = 200.0
@export var spawn_max_distance: float = 400.0
@export var spawn_angle_spread: float = 30.0
@export var max_spawn_retries: int = 3

var _enemy_scene: PackedScene = preload("res://scenes/enemy.tscn")

# Type → data file ID mapping
var _type_data_map := {
	"melee": "melee_enemy",
	"ranged": "melee_enemy",  # MVP: same data for ranged until ranged enemy is implemented
}

@onready var _player: Player = _find_player()
@onready var _enemies_container: Node2D = $"../../Arena/Enemies"


func _ready() -> void:
	assert(spawn_max_distance > spawn_min_distance, "SpawnManager: max_distance must be > min_distance")


## Spawn N enemies of a given type. Called by WaveManager.
func spawn_enemies(enemy_type: String, count: int, _wave_number: int = 1, spawn_delay: float = 0.4) -> void:
	assert(enemy_type in _type_data_map, "SpawnManager: unknown enemy_type '%s'" % enemy_type)
	if count <= 0:
		return

	var data_id: String = _type_data_map[enemy_type]
	var data := GameConfig.get_enemy_data(data_id)
	if not data:
		push_warning("SpawnManager: enemy data not found for type '%s'" % enemy_type)
		return

	var base_angle := randf() * TAU

	for i in count:
		var pos := _compute_spawn_position(base_angle, i)
		_spawn_one(pos, data)
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


func _spawn_one(pos: Vector2, data: EnemyData) -> void:
	var enemy := _enemy_scene.instantiate() as Enemy
	enemy.enemy_data = data
	enemy.global_position = pos
	_enemies_container.add_child(enemy)


func _clamp_to_arena(pos: Vector2) -> Vector2:
	var rect := _get_arena_rect()
	pos.x = clampf(pos.x, rect.position.x, rect.end.x)
	pos.y = clampf(pos.y, rect.position.y, rect.end.y)
	return pos


func _get_arena_rect() -> Rect2:
	return Rect2(140, 60, GameConfig.ARENA_WIDTH, GameConfig.ARENA_HEIGHT)


func _find_player() -> Player:
	var players := get_tree().get_nodes_in_group("players")
	if players.size() > 0:
		return players[0] as Player
	return null
