extends CharacterBody2D
class_name Enemy

## Basic enemy: tracks player, deals contact damage, reacts to knockback.
## Expandable to full state machine (flanking/charging/ranged) per GDD.

@export var enemy_data: EnemyData

@onready var health: HealthComponent = $HealthComponent
@onready var sprite: ColorRect = $Sprite

var _player: Player
var _contact_timer: float = -0.3  # negative = 0.3s spawn protection

# Knockback state
var _is_knocked_back: bool = false
var _knockback_velocity: Vector2 = Vector2.ZERO
var _knockback_timer: float = 0.0
var _knockback_duration: float = 0.0


func _ready() -> void:
	add_to_group("enemies")
	if not enemy_data:
		enemy_data = GameConfig.get_enemy_data("melee_enemy") as EnemyData
	if enemy_data:
		enemy_data.validate()
		health.max_hp = enemy_data.max_hp
		health.current_hp = enemy_data.max_hp
		health.death_linger = GameConfig.ENEMY_DEATH_LINGER

	health.died.connect(_on_death)
	_find_player()


func _physics_process(delta: float) -> void:
	if not health.is_alive():
		return

	if _is_knocked_back:
		_process_knockback(delta)
		return

	_track_player(delta)
	_check_contact_damage(delta)


func take_damage(amount: int, damage_type: String, source: Node, knockback_value: float = 0.0) -> int:
	var result := health.take_damage(amount, damage_type, source, knockback_value)

	if knockback_value > 0.0 and health.is_alive() and not _is_knocked_back:
		_start_knockback(source.global_position, knockback_value)

	return result


# --- Tracking ---

func _track_player(delta: float) -> void:
	if not _player or not _player.health.is_alive():
		return

	if not enemy_data:
		return

	var direction := (_player.global_position - global_position).normalized()
	velocity = direction * enemy_data.move_speed
	move_and_slide()


# --- Contact damage ---

func _check_contact_damage(delta: float) -> void:
	if not _player or not enemy_data:
		return

	_contact_timer += delta
	if _contact_timer < enemy_data.contact_damage_interval:
		return

	var distance := global_position.distance_to(_player.global_position)
	if distance <= enemy_data.contact_radius:
		_contact_timer = 0.0
		_player.take_damage(enemy_data.contact_damage, "melee", self, 0.0)


# --- Knockback ---

func _start_knockback(source_position: Vector2, distance: float) -> void:
	_is_knocked_back = true
	_knockback_timer = 0.0

	var kb_speed := enemy_data.knockback_speed if enemy_data else GameConfig.MELEE_KNOCKBACK_SPEED
	_knockback_duration = distance / kb_speed
	var direction := (global_position - source_position).normalized()
	_knockback_velocity = direction * kb_speed


func _process_knockback(delta: float) -> void:
	_knockback_timer += delta
	if _knockback_timer >= _knockback_duration:
		_is_knocked_back = false
		return

	velocity = _knockback_velocity
	move_and_slide()


# --- Death ---

func _on_death() -> void:
	queue_free()


func _find_player() -> void:
	var players := get_tree().get_nodes_in_group("players")
	if players.size() > 0:
		_player = players[0] as Player
