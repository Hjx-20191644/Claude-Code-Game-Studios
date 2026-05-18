extends CharacterBody2D
class_name Enemy

## Enemy with multi-type AI: melee (flank-and-charge), ranged (keep-distance + shoot),
## charger (periodic dash + stun), exploder (rush + AoE blast), tank (slow + front shield).
## Type determined by enemy_data.enemy_type.

enum MeleeState { SPAWN, FLANKING, CHARGING }
enum RangedState { SPAWN, APPROACH, SHOOTING, EVADING }
enum ChargerState { SPAWN, TRACKING, CHARGE_PREP, CHARGING, STUN }
enum ExploderState { SPAWN, RUSHING, WARNING, EXPLODING }

@export var enemy_data: EnemyData

@onready var health: HealthComponent = $HealthComponent
@onready var sprite: ColorRect = $Sprite

var _player: Player
var _contact_timer: float = -0.3
var _is_ranged: bool = false
var _is_charger: bool = false
var _is_exploder: bool = false
var _is_tank: bool = false

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

# Charger FSM
var _c_state: ChargerState = ChargerState.SPAWN
var _c_prep_timer: float = 0.0
var _c_stun_timer: float = 0.0
var _c_charge_dir: Vector2 = Vector2.ZERO
var _c_cooldown_timer: float = 0.0

# Exploder FSM
var _e_state: ExploderState = ExploderState.SPAWN
var _e_warning_timer: float = 0.0

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
		_is_charger = enemy_data.enemy_type == "charger"
		_is_exploder = enemy_data.enemy_type == "exploder"
		_is_tank = enemy_data.enemy_type == "tank"

		if enemy_data.is_elite:
			sprite.scale = Vector2(enemy_data.elite_scale, enemy_data.elite_scale)
			sprite.color = Color(1.0, 0.84, 0.0)
			health.is_elite = true
			health.max_hp = int(health.max_hp * enemy_data.elite_hp_mult)
			health.current_hp = health.max_hp
		elif _is_ranged:
			sprite.color = Color(0.8, 0.4, 0.2)
		elif _is_charger:
			sprite.color = Color(0.9, 0.2, 0.1)
		elif _is_exploder:
			sprite.color = Color(1.0, 0.5, 0.0)
		elif _is_tank:
			sprite.color = Color(0.4, 0.4, 0.5)
			sprite.scale = Vector2(2.0, 2.0)
		else:
			sprite.color = Color(0.3, 0.7, 1.0)

	health.died.connect(_on_death)
	_find_player()
	_bullet_scene = load("res://scenes/bullet.tscn") as PackedScene
	_spawn_timer = 0.3

	if _is_charger:
		_c_cooldown_timer = randf_range(3.0, 5.0)


func _physics_process(delta: float) -> void:
	if not health.is_alive():
		return

	if _is_knocked_back:
		_process_knockback(delta)
		return

	if _is_exploder:
		_process_exploder(delta)
	elif _is_charger:
		_process_charger(delta)
	elif _is_ranged:
		_process_ranged(delta)
	else:
		_process_melee(delta)

	_check_contact_damage(delta)


func take_damage(amount: int, damage_type: String, source: Node, knockback_value: float = 0.0) -> int:
	if _is_tank and source and is_instance_valid(source) and source is Node2D:
		var src_2d := source as Node2D
		var to_source := (src_2d.global_position - global_position).normalized()
		var facing := Vector2.RIGHT  # default
		if _player and is_instance_valid(_player):
			facing = (_player.global_position - global_position).normalized()
		var angle_diff := absf(facing.angle_to(to_source))
		if angle_diff <= deg_to_rad(90.0):
			amount = maxi(1, int(float(amount) * 0.5))

	var result := health.take_damage(amount, damage_type, source, knockback_value)

	if _is_charger and knockback_value > 0.0 and health.is_alive() and not _is_knocked_back:
		_start_knockback(source.global_position, knockback_value * 0.5)
	elif knockback_value > 0.0 and health.is_alive() and not _is_knocked_back:
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


# --- Charger AI ---

func _process_charger(delta: float) -> void:
	match _c_state:
		ChargerState.SPAWN:
			_spawn_timer -= delta
			if _spawn_timer <= 0.0:
				_enter_charger(ChargerState.TRACKING)

		ChargerState.TRACKING:
			_c_cooldown_timer -= delta
			if _c_cooldown_timer <= 0.0:
				_enter_charger(ChargerState.CHARGE_PREP)
			else:
				var dir := (_player.global_position - global_position).normalized()
				velocity = dir * _ed("move_speed", 150.0)
				move_and_slide()

		ChargerState.CHARGE_PREP:
			_c_prep_timer -= delta
			var pulse := 1.0 + sin(_c_prep_timer * 20.0) * 0.3
			if enemy_data.is_elite:
				sprite.scale = Vector2(enemy_data.elite_scale * pulse, enemy_data.elite_scale * pulse)
			else:
				sprite.scale = Vector2(pulse, pulse)
			if _c_prep_timer <= 0.0:
				_enter_charger(ChargerState.CHARGING)

		ChargerState.CHARGING:
			_c_stun_timer -= delta
			velocity = _c_charge_dir * _ed("charge_speed", 500.0)
			move_and_slide()
			if _c_stun_timer <= 0.0:
				_enter_charger(ChargerState.STUN)

		ChargerState.STUN:
			_c_prep_timer -= delta
			velocity = Vector2.ZERO
			# Flicker during stun
			sprite.visible = fmod(_c_prep_timer * 10.0, 1.0) > 0.3
			if _c_prep_timer <= 0.0:
				_enter_charger(ChargerState.TRACKING)


func _enter_charger(new_state: ChargerState) -> void:
	_c_state = new_state
	match new_state:
		ChargerState.CHARGE_PREP:
			_c_prep_timer = 0.3
			_c_charge_dir = (_player.global_position - global_position).normalized()
		ChargerState.CHARGING:
			_c_stun_timer = 0.5
			# Elongate during charge
			if not enemy_data.is_elite:
				sprite.scale = Vector2(1.5, 0.7)
		ChargerState.STUN:
			_c_prep_timer = 1.2
			if not enemy_data.is_elite:
				sprite.scale = Vector2(0.8, 0.8)
			sprite.color = Color(0.6, 0.15, 0.07)
		ChargerState.TRACKING:
			_c_cooldown_timer = randf_range(4.0, 7.0)
			if not enemy_data.is_elite:
				sprite.scale = Vector2(1.0, 1.0)
			sprite.visible = true
			sprite.color = Color(0.9, 0.2, 0.1)
		ChargerState.SPAWN:
			pass


# --- Exploder AI ---

func _process_exploder(delta: float) -> void:
	match _e_state:
		ExploderState.SPAWN:
			_spawn_timer -= delta
			if _spawn_timer <= 0.0:
				_enter_exploder(ExploderState.RUSHING)

		ExploderState.RUSHING:
			if _player:
				var dist := global_position.distance_to(_player.global_position)
				if dist <= 40.0:
					_enter_exploder(ExploderState.WARNING)
				else:
					var dir := (_player.global_position - global_position).normalized()
					velocity = dir * _ed("move_speed", 250.0)
					move_and_slide()

		ExploderState.WARNING:
			_e_warning_timer -= delta
			# Rapid blink
			sprite.visible = fmod(_e_warning_timer * 15.0, 1.0) > 0.4
			velocity = Vector2.ZERO
			if _e_warning_timer <= 0.0:
				_enter_exploder(ExploderState.EXPLODING)


func _enter_exploder(new_state: ExploderState) -> void:
	_e_state = new_state
	match new_state:
		ExploderState.WARNING:
			_e_warning_timer = 0.35
			sprite.color = Color(2.0, 2.0, 2.0)
		ExploderState.EXPLODING:
			_explode(80.0, 25)
			queue_free()
		ExploderState.RUSHING:
			sprite.visible = true
			sprite.color = Color(1.0, 0.5, 0.0)


# --- Explosion ---

func _explode(radius: float, damage: int) -> void:
	EventBus.vfx_requested.emit("explosion", global_position)
	if _player and global_position.distance_to(_player.global_position) <= radius:
		_player.take_damage(damage, "explosion", self, 0.0)
	# Damage nearby enemies (for chain reactions / upgrades)
	var enemies := get_tree().get_nodes_in_group("enemies")
	for e in enemies:
		if e == self or not is_instance_valid(e):
			continue
		var other := e as Node2D
		if other and other.global_position.distance_to(global_position) <= radius:
			if other.has_method("take_damage"):
				other.take_damage(damage, "explosion", self, 0.0)


# --- Fire bullet (ranged enemies) ---

func _fire_bullet() -> void:
	if not _bullet_scene or not _player:
		return
	var bullet := _bullet_scene.instantiate() as Bullet
	var dir := (_player.global_position - global_position).normalized()
	bullet.global_position = global_position + dir * 16.0
	bullet.direction = dir
	bullet.damage = _ed("bullet_damage", 10)
	bullet.speed = _ed("bullet_speed", 250.0)
	bullet.max_range = _ed("shoot_range", 300.0) * 1.2
	bullet.source = self
	bullet.damage_type = "ranged"
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
			if _is_exploder:
				_enter_exploder(ExploderState.RUSHING)
			elif _is_charger:
				_enter_charger(ChargerState.TRACKING)
			elif _is_ranged:
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
	if _is_exploder:
		return  # Exploder does no contact damage, uses explosion instead
	_contact_timer += delta
	if _contact_timer < enemy_data.contact_damage_interval:
		return
	if global_position.distance_to(_player.global_position) <= enemy_data.contact_radius:
		_contact_timer = 0.0
		_player.take_damage(enemy_data.contact_damage, "melee", self, 0.0)


# --- Death ---

func _on_death() -> void:
	if _is_exploder:
		_explode(80.0, 25)
	# Kill explosion upgrade
	var ua := get_node_or_null("/root/Main/Systems/UpgradeApplier")
	if ua:
		var kill_dmg: float = ua.get_absolute("kill_explosion_damage")
		if kill_dmg > 0.0:
			_explode(80.0, int(kill_dmg))
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
