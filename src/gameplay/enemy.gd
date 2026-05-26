extends CharacterBody2D
class_name Enemy
const PA = preload("res://src/visuals/pixel_art.gd")
const ST = preload("res://src/visuals/sprite_templates.gd")

## Enemy with multi-type AI: melee (flank-and-charge), ranged (keep-distance + shoot),
## charger (periodic dash + stun), exploder (rush + AoE blast), tank (slow + front shield).
## Type determined by enemy_data.enemy_type.

enum MeleeState { SPAWN, FLANKING, CHARGING }
enum RangedState { SPAWN, APPROACH, SHOOTING, EVADING }
enum ChargerState { SPAWN, TRACKING, CHARGE_PREP, CHARGING, STUN }
enum ExploderState { SPAWN, RUSHING, WARNING, EXPLODING }
enum BossState { SPAWN, TRACKING, CHARGE_WINDUP, CHARGING, STUN, SLAM_WINDUP, SLAM }
enum BossPhase { PHASE_1, PHASE_2 }

@export var enemy_data: EnemyData

@onready var health: HealthComponent = $HealthComponent
@onready var sprite: Sprite2D = $Sprite

var _base_scale: float = 1.0
var _anim_frames: Array[ImageTexture] = []
var _anim_frame: int = 0
var _anim_timer: float = 0.0
var _anim_interval: float = 0.75
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

# Boss
var _is_boss: bool = false
var _boss_state: BossState = BossState.SPAWN
var _boss_phase: BossPhase = BossPhase.PHASE_1
var _boss_cooldown: float = 0.0
var _boss_timer: float = 0.0
var _boss_charge_dir: Vector2 = Vector2.ZERO
var _boss_has_slammed: bool = false

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
		_is_boss = enemy_data.enemy_type == "boss"

		# Generate pixel art sprite based on type
		if _is_boss:
			sprite.texture = PA.generate_sprite(144, 144, ST.enemy_boss_sprite, [PA.MATERIAL_FLESH])
		elif _is_tank:
			sprite.texture = PA.generate_sprite(96, 96, ST.enemy_ref_tank_sprite, [PA.MATERIAL_METAL])
			sprite.self_modulate = Color.WHITE
		elif _is_exploder:
			sprite.texture = PA.generate_sprite(48, 48, ST.enemy_exploder_sprite, [PA.MATERIAL_FLESH])
		elif _is_charger:
			sprite.texture = PA.generate_sprite(48, 48, ST.enemy_ref_charger_sprite, [PA.MATERIAL_FLESH])
			sprite.self_modulate = Color.WHITE
		elif _is_ranged:
			sprite.texture = PA.generate_sprite(48, 48, ST.enemy_ref_ranged_sprite, [PA.MATERIAL_FLESH])
			sprite.self_modulate = Color.WHITE
		else:
			sprite.texture = PA.generate_sprite(48, 48, ST.enemy_ref_melee_sprite, [PA.MATERIAL_FLESH])
			sprite.self_modulate = Color.WHITE

		if enemy_data.is_elite:
			_base_scale = enemy_data.elite_scale
			sprite.self_modulate = Color(1.0, 0.84, 0.0)
			health.is_elite = true
			health.max_hp = int(health.max_hp * enemy_data.elite_hp_mult)
			health.current_hp = health.max_hp
		elif _is_ranged:
			sprite.self_modulate = Color(0.8, 0.4, 0.2)
			_base_scale = 1.0
		elif _is_charger:
			sprite.self_modulate = Color(0.9, 0.2, 0.1)
			_base_scale = 1.0
		elif _is_exploder:
			sprite.self_modulate = Color(1.0, 0.5, 0.0)
			_base_scale = 1.0
		elif _is_tank:
			sprite.self_modulate = Color(0.4, 0.4, 0.5)
			_base_scale = 1.5
		elif _is_boss:
			_base_scale = enemy_data.boss_scale * 0.5
			sprite.self_modulate = Color(0.7, 0.15, 0.1)
		else:
			sprite.self_modulate = Color(0.3, 0.7, 1.0)
			_base_scale = 1.0

	sprite.scale = Vector2(_base_scale, _base_scale)

	health.died.connect(_on_death)
	_find_player()
	_bullet_scene = load("res://scenes/bullet.tscn") as PackedScene
	_spawn_timer = 0.3

	# Build idle animation frame array
	if _is_boss:
		_anim_frames = PA.generate_animated_frames(
			[ST.enemy_boss_sprite, ST.enemy_boss_sprite_idle_1, ST.enemy_boss_sprite_idle_2],
			144, 144, [PA.MATERIAL_FLESH]
		)
		_anim_interval = 0.67
	elif _is_tank:
		_anim_frames = PA.generate_animated_frames(
			[ST.enemy_ref_tank_sprite, ST.enemy_ref_tank_sprite],
			96, 96, [PA.MATERIAL_METAL]
		)
		_anim_interval = 0.75
	elif _is_exploder:
		_anim_frames = PA.generate_animated_frames(
			[ST.enemy_exploder_sprite, ST.enemy_exploder_sprite_blink],
			48, 48, [PA.MATERIAL_FLESH]
		)
		_anim_interval = 0.75
	elif _is_charger:
		_anim_frames = PA.generate_animated_frames(
			[ST.enemy_ref_charger_sprite, ST.enemy_ref_charger_sprite],
			48, 48, [PA.MATERIAL_FLESH]
		)
		_anim_interval = 0.75
	elif _is_ranged:
		_anim_frames = PA.generate_animated_frames(
			[ST.enemy_ref_ranged_sprite, ST.enemy_ref_ranged_sprite],
			48, 48, [PA.MATERIAL_FLESH]
		)
		_anim_interval = 0.75
	else:
		_anim_frames = PA.generate_animated_frames(
			[ST.enemy_ref_melee_sprite, ST.enemy_ref_melee_sprite],
			48, 48, [PA.MATERIAL_FLESH]
		)
		_anim_interval = 0.75

	if _is_charger:
		_c_cooldown_timer = randf_range(3.0, 5.0)

	if _is_boss:
		_boss_cooldown = randf_range(3.0, 5.0)
		EventBus.boss_spawned.emit(enemy_data.enemy_name, health.max_hp)
		EventBus.boss_damaged.emit(health.current_hp, health.max_hp)


func _physics_process(delta: float) -> void:
	if not health.is_alive():
		return

	# Idle animation
	if _anim_frames.size() > 0 and sprite.visible:
		_anim_timer += delta
		if _anim_timer >= _anim_interval:
			_anim_timer -= _anim_interval
			_anim_frame = (_anim_frame + 1) % _anim_frames.size()
			sprite.texture = _anim_frames[_anim_frame]

	if _is_knocked_back:
		_process_knockback(delta)
		return

	if _is_boss:
		_process_boss(delta)
	elif _is_exploder:
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

	# Boss phase transition
	if _is_boss and health.is_alive():
		EventBus.boss_damaged.emit(health.current_hp, health.max_hp)
		if _boss_phase == BossPhase.PHASE_1:
			var hp_ratio := float(health.current_hp) / float(health.max_hp)
			var threshold := enemy_data.phase_threshold if enemy_data else 0.5
			if hp_ratio <= threshold:
				_boss_phase = BossPhase.PHASE_2
				_boss_has_slammed = false
				_boss_cooldown = 0.3
				EventBus.boss_phase_changed.emit(2)
				sprite.self_modulate = Color(1.0, 0.2, 0.05)

	if _is_boss and knockback_value > 0.0 and health.is_alive() and not _is_knocked_back:
		_start_knockback(source.global_position, knockback_value * 0.25)
	elif _is_charger and knockback_value > 0.0 and health.is_alive() and not _is_knocked_back:
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
				sprite.scale = Vector2(_base_scale * pulse, _base_scale * pulse)
			else:
				sprite.scale = Vector2(_base_scale * pulse, _base_scale * pulse)
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
				sprite.scale = Vector2(_base_scale * 1.5, _base_scale * 0.7)
		ChargerState.STUN:
			_c_prep_timer = 1.2
			if not enemy_data.is_elite:
				sprite.scale = Vector2(_base_scale * 0.8, _base_scale * 0.8)
			sprite.self_modulate = Color(0.6, 0.15, 0.07)
		ChargerState.TRACKING:
			_c_cooldown_timer = randf_range(4.0, 7.0)
			if not enemy_data.is_elite:
				sprite.scale = Vector2(_base_scale, _base_scale)
			sprite.visible = true
			sprite.self_modulate = Color(0.9, 0.2, 0.1)
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
				if dist <= 30.0:
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
			sprite.self_modulate = Color(2.0, 2.0, 2.0)
		ExploderState.EXPLODING:
			_explode(60.0, 25)
			queue_free()
		ExploderState.RUSHING:
			sprite.visible = true
			sprite.self_modulate = Color(1.0, 0.5, 0.0)


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
	bullet.global_position = global_position + dir * 12.0
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
			if _is_boss:
				_enter_boss(BossState.TRACKING)
			elif _is_exploder:
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
	if _is_boss:
		EventBus.boss_killed.emit(enemy_data.enemy_name if enemy_data else "Boss")
	if _is_exploder:
		_explode(60.0, 25)
	# Kill explosion upgrade
	var ua := get_node_or_null("/root/Main/Systems/UpgradeApplier")
	if ua:
		var kill_dmg: float = ua.get_absolute("kill_explosion_damage")
		if kill_dmg > 0.0:
			_explode(60.0, int(kill_dmg))
	queue_free()


# --- Boss AI ---

func _process_boss(delta: float) -> void:
	match _boss_state:
		BossState.SPAWN:
			_spawn_timer -= delta
			if _spawn_timer <= 0.0:
				_enter_boss(BossState.TRACKING)

		BossState.TRACKING:
			_boss_cooldown -= delta
			if _boss_cooldown <= 0.0:
				if _boss_phase == BossPhase.PHASE_2 and not _boss_has_slammed and randf() < 0.4:
					_enter_boss(BossState.SLAM_WINDUP)
				else:
					_enter_boss(BossState.CHARGE_WINDUP)
			else:
				var dir := (_player.global_position - global_position).normalized()
				var speed := _ed("move_speed", 120.0)
				if _boss_phase == BossPhase.PHASE_2:
					speed *= 1.3
				velocity = dir * speed
				move_and_slide()

		BossState.CHARGE_WINDUP:
			_boss_timer -= delta
			var pulse := 1.0 + sin(_boss_timer * 18.0) * 0.2
			sprite.scale = Vector2(_base_scale * pulse, _base_scale * pulse)
			velocity = Vector2.ZERO
			if _boss_timer <= 0.0:
				_enter_boss(BossState.CHARGING)

		BossState.CHARGING:
			_boss_timer -= delta
			velocity = _boss_charge_dir * _ed("charge_speed", 600.0)
			move_and_slide()
			if _boss_timer <= 0.0:
				_enter_boss(BossState.STUN)

		BossState.STUN:
			_boss_timer -= delta
			velocity = Vector2.ZERO
			sprite.visible = fmod(_boss_timer * 10.0, 1.0) > 0.3
			if _boss_timer <= 0.0:
				_boss_has_slammed = false
				_enter_boss(BossState.TRACKING)

		BossState.SLAM_WINDUP:
			_boss_timer -= delta
			var pulse := 1.0 + sin(_boss_timer * 15.0) * 0.35
			sprite.scale = Vector2(_base_scale * pulse, _base_scale * pulse)
			sprite.self_modulate = Color(2.0, 2.0, 2.0)
			velocity = Vector2.ZERO
			if _boss_timer <= 0.0:
				_enter_boss(BossState.SLAM)

		BossState.SLAM:
			var sw := _ed("slam_windup", 0.5)
			if sw > 0.0:
				_explode(_ed("slam_radius", 90.0), int(_ed("slam_damage", 30)))
			EventBus.vfx_requested.emit("explosion", global_position)
			_boss_has_slammed = true
			_enter_boss(BossState.STUN)


func _enter_boss(new_state: BossState) -> void:
	_boss_state = new_state
	match new_state:
		BossState.TRACKING:
			_boss_cooldown = randf_range(3.0, 5.0)
			if _boss_phase == BossPhase.PHASE_2:
				_boss_cooldown *= 0.7
			sprite.visible = true
			sprite.scale = Vector2(_base_scale, _base_scale)
			if _boss_phase == BossPhase.PHASE_1:
				sprite.self_modulate = Color(0.7, 0.15, 0.1)
			else:
				sprite.self_modulate = Color(1.0, 0.2, 0.05)

		BossState.CHARGE_WINDUP:
			_boss_timer = 0.4
			_boss_charge_dir = (_player.global_position - global_position).normalized()

		BossState.CHARGING:
			_boss_timer = _ed("charge_duration", 0.6)
			sprite.scale = Vector2(_base_scale * 1.5, _base_scale * 0.7)

		BossState.STUN:
			_boss_timer = 0.8
			sprite.scale = Vector2(_base_scale * 0.9, _base_scale * 0.9)
			sprite.self_modulate = Color(0.5, 0.1, 0.07)

		BossState.SLAM_WINDUP:
			_boss_timer = _ed("slam_windup", 0.5)

		BossState.SLAM:
			pass

		BossState.SPAWN:
			pass


func _find_player() -> void:
	var players := get_tree().get_nodes_in_group("players")
	if players.size() > 0:
		_player = players[0] as Player


## Safe enemy_data field access with fallback.
func _ed(field: String, default: float) -> float:
	if not enemy_data:
		return default
	return enemy_data.get(field) as float
