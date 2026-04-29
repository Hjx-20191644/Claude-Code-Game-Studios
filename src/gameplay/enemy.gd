extends CharacterBody2D
class_name Enemy

## Enemy with dual AI: melee (flank-and-charge) or ranged (keep-distance + shoot).
## Type determined by enemy_data.enemy_type.

enum MeleeState { SPAWN, FLANKING, CHARGING }
enum RangedState { SPAWN, APPROACH, SHOOTING, EVADING }

@export var enemy_data: EnemyData

@onready var health: HealthComponent = $HealthComponent
@onready var sprite: ColorRect = $Sprite

var _player: Player
var _contact_timer: float = -0.3
var _is_ranged: bool = false

# Melee FSM
var _m_state: MeleeState = MeleeState.SPAWN
var _spawn_timer: float = 0.3
var _flank_direction: Vector2 = Vector2.ZERO
var _flank_moved: float = 0.0
var _charge_target: Vector2 = Vector2.ZERO
var _charge_timer: float = 0.0

# Ranged FSM
var _r_state: RangedState = RangedState.SPAWN
var _shoot_timer: float = 0.0
var _evade_direction: Vector2 = Vector2.ZERO
var _evade_moved: float = 0.0

# Knockback (overrides FSM)
var _is_knocked_back: bool = false
var _knockback_velocity: Vector2 = Vector2.ZERO
var _knockback_timer: float = 0.0
var _knockback_duration: float = 0.0

var _bullet_scene: PackedScene


func _ready() -> void:
	add_to_group("enemies")
	if not enemy_data:
		enemy_data = GameConfig.get_enemy_data("melee_enemy") as EnemyData
	if enemy_data:
		enemy_data.validate()
		health.max_hp = enemy_data.max_hp
		health.current_hp = enemy_data.max_hp
		health.death_linger = GameConfig.ENEMY_DEATH_LINGER
		_is_ranged = enemy_data.enemy_type == "ranged"
		if _is_ranged:
			sprite.color = Color(0.8, 0.4, 0.2)
		else:
			sprite.color = Color(0.3, 0.7, 1.0)

	health.died.connect(_on_death)
	_find_player()
	_bullet_scene = load("res://scenes/bullet.tscn") as PackedScene
	_spawn_timer = 0.3


func _physics_process(delta: float) -> void:
	if not health.is_alive():
		return

	if _is_knocked_back:
		_process_knockback(delta)
		return

	if _is_ranged:
		_process_ranged(delta)
	else:
		_process_melee(delta)

	_check_contact_damage(delta)


func take_damage(amount: int, damage_type: String, source: Node, knockback_value: float = 0.0) -> int:
	var result := health.take_damage(amount, damage_type, source, knockback_value)
	if knockback_value > 0.0 and health.is_alive() and not _is_knocked_back:
		_start_knockback(source.global_position, knockback_value)
	return result


# --- Melee AI ---

func _process_melee(delta: float) -> void:
	match _m_state:
		MeleeState.SPAWN:
			_spawn_timer -= delta
			if _spawn_timer <= 0.0:
				_enter_melee(MeleeState.FLANKING)

		MeleeState.FLANKING:
			velocity = _flank_direction * _ed("flank_speed", 200.0)
			move_and_slide()
			_flank_moved += _ed("flank_speed", 200.0) * delta
			if _flank_moved >= _ed("flank_distance", 100.0):
				_enter_melee(MeleeState.CHARGING)

		MeleeState.CHARGING:
			_charge_timer += delta
			var cd := _ed("charge_duration", 0.5)
			var t := minf(_charge_timer / cd, 1.0)
			var mult := minf(0.5 + t * 2.0, 1.5)
			var dir := (_charge_target - global_position).normalized()
			velocity = dir * _ed("charge_speed", 500.0) * mult
			move_and_slide()
			if _charge_timer >= cd:
				_enter_melee(MeleeState.FLANKING)


func _enter_melee(new_state: MeleeState) -> void:
	_m_state = new_state
	match new_state:
		MeleeState.FLANKING:
			var tp := (_player.global_position - global_position).normalized()
			var perp := Vector2(-tp.y, tp.x)
			_flank_direction = perp if randi() % 2 == 0 else -perp
			_flank_moved = 0.0
		MeleeState.CHARGING:
			_charge_target = _player.global_position
			_charge_timer = 0.0


# --- Ranged AI ---

func _process_ranged(delta: float) -> void:
	var dist := global_position.distance_to(_player.global_position)

	match _r_state:
		RangedState.SPAWN:
			_spawn_timer -= delta
			if _spawn_timer <= 0.0:
				_enter_ranged(RangedState.APPROACH)

		RangedState.APPROACH:
			if dist <= _ed("shoot_range", 300.0):
				_enter_ranged(RangedState.SHOOTING)
			else:
				var dir := (_player.global_position - global_position).normalized()
				velocity = dir * _ed("approach_speed", 120.0)
				move_and_slide()

		RangedState.SHOOTING:
			if dist <= _ed("evade_range", 120.0):
				_enter_ranged(RangedState.EVADING)
			elif dist > _ed("shoot_range", 300.0):
				_enter_ranged(RangedState.APPROACH)
			else:
				_shoot_timer += delta
				if _shoot_timer >= _ed("shoot_interval", 1.5):
					_shoot_timer = 0.0
					_fire_bullet()
				velocity = Vector2.ZERO

		RangedState.EVADING:
			velocity = _evade_direction * _ed("evade_speed", 250.0)
			move_and_slide()
			_evade_moved += _ed("evade_speed", 250.0) * delta
			if _evade_moved >= _ed("evade_distance", 80.0):
				_enter_ranged(RangedState.SHOOTING)


func _enter_ranged(new_state: RangedState) -> void:
	_r_state = new_state
	match new_state:
		RangedState.SHOOTING:
			_shoot_timer = _ed("shoot_interval", 1.5) * randf()
		RangedState.EVADING:
			var tp := (_player.global_position - global_position).normalized()
			var perp := Vector2(-tp.y, tp.x)
			_evade_direction = perp if randi() % 2 == 0 else -perp
			_evade_moved = 0.0


func _fire_bullet() -> void:
	if not _bullet_scene or not _player:
		return
	var bullet := _bullet_scene.instantiate() as Bullet
	var dir := (_player.global_position - global_position).normalized()
	# Spawn forward to avoid hitting self
	bullet.global_position = global_position + dir * 16.0
	bullet.direction = dir
	bullet.damage = _ed("bullet_damage", 10)
	bullet.speed = _ed("bullet_speed", 250.0)
	bullet.max_range = _ed("shoot_range", 300.0) * 1.2
	bullet.source = self
	bullet.damage_type = "ranged"
	# Hit player (layer 1) + walls (layer 8), not enemies
	bullet.collision_mask = 1 + 128
	get_node("../../Effects").add_child(bullet)


# --- Knockback ---

func _start_knockback(source_position: Vector2, distance: float) -> void:
	_is_knocked_back = true
	_knockback_timer = 0.0
	var kb_speed := enemy_data.knockback_speed if enemy_data else GameConfig.MELEE_KNOCKBACK_SPEED
	_knockback_duration = distance / kb_speed
	_knockback_velocity = (global_position - source_position).normalized() * kb_speed


func _process_knockback(delta: float) -> void:
	_knockback_timer += delta
	if _knockback_timer >= _knockback_duration:
		_is_knocked_back = false
		if health.is_alive():
			if _is_ranged:
				_enter_ranged(RangedState.APPROACH)
			else:
				_enter_melee(MeleeState.FLANKING)
		return
	velocity = _knockback_velocity
	move_and_slide()


# --- Contact damage ---

func _check_contact_damage(delta: float) -> void:
	if not _player or not enemy_data:
		return
	_contact_timer += delta
	if _contact_timer < enemy_data.contact_damage_interval:
		return
	if global_position.distance_to(_player.global_position) <= enemy_data.contact_radius:
		_contact_timer = 0.0
		_player.take_damage(enemy_data.contact_damage, "melee", self, 0.0)


# --- Death ---

func _on_death() -> void:
	queue_free()


func _find_player() -> void:
	var players := get_tree().get_nodes_in_group("players")
	if players.size() > 0:
		_player = players[0] as Player


## Safe enemy_data field access with fallback.
func _ed(field: String, default: float) -> float:
	if not enemy_data:
		return default
	return enemy_data.get(field) as float
