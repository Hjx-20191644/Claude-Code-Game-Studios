extends Node
class_name ShardManager
## Spawns shard pickups on enemy death, tracks run shard count.

const SHARD_VALUES := {
	melee = 3,
	ranged = 4,
	charger = 8,
	exploder = 5,
	tank = 12,
}
const ELITE_MULTIPLIER: int = 2

var _run_shards: int = 0
var _player: Node2D
var _pickup_parent: Node
var _pickup_radius: float = 100.0


func _ready() -> void:
	EventBus.enemy_killed.connect(_on_enemy_killed)
	EventBus.shard_collected.connect(_on_shard_collected)
	EventBus.run_ended.connect(_on_run_ended)

	# Find player at runtime
	_player = get_tree().get_first_node_in_group("players") as Node2D
	_pickup_parent = get_parent().get_node_or_null("../Arena/Enemies") if get_parent() else null
	if not _pickup_parent:
		_pickup_parent = self  # fallback: spawn under self


func get_run_shards() -> int:
	return _run_shards


func get_pickup_radius() -> float:
	return _pickup_radius


func set_pickup_radius(r: float) -> void:
	_pickup_radius = r


func add_starting_shards(amount: int) -> void:
	_run_shards += amount
	EventBus.shard_collected.emit(amount, _run_shards)


func clear_run_shards() -> void:
	_run_shards = 0


func _on_enemy_killed(kill_type: String, position: Vector2, _enemy_color: Color, is_elite: bool) -> void:
	var base: int = SHARD_VALUES.get(kill_type, 0)
	if base == 0:
		return

	var amount := base * (ELITE_MULTIPLIER if is_elite else 1)
	_spawn_shard(position, amount)


func _on_shard_collected(amount: int, _total: int) -> void:
	_run_shards += amount


func _on_run_ended() -> void:
	# Shards are saved via run_completed signal in S5-04
	pass


func _spawn_shard(pos: Vector2, amount: int) -> void:
	var shard_scene := preload("res://src/gameplay/shard_pickup.gd")
	var shard: Area2D = shard_scene.new()
	shard.setup(pos, amount, _player, _pickup_radius)
	_pickup_parent.add_child(shard)
