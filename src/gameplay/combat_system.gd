extends Node
class_name CombatSystem

## Mixed combat system: melee fan attacks + ranged projectiles.
## Manages dual weapon slots, cooldowns, ammo, and attack direction.

# Weapon slots
var left_weapon: WeaponData
var right_weapon: WeaponData

# Per-weapon cooldowns (seconds remaining)
var _left_cooldown: float = 0.0
var _right_cooldown: float = 0.0

# Per-weapon ammo
var _left_ammo: int = 0
var _right_ammo: int = 0
var _left_ammo_timer: float = 0.0
var _right_ammo_timer: float = 0.0

# Attack mode (mutual exclusivity: first pressed wins)
enum AttackMode { NONE, MELEE, RANGED }
var _attack_mode: AttackMode = AttackMode.NONE

# Melee state
var _dual_melee_queue: bool = false
var _dual_melee_timer: float = 0.0
var _melee_first_hits: Array[Node] = []  # enemies hit by first weapon in dual melee
var _melee_first_weapon_dmg: int = 0

# References
@onready var player: Player = _find_player()
@onready var input_buffer: Node = $"../InputBuffer"
var _bullet_scene: PackedScene = preload("res://scenes/bullet.tscn")
var _arena_enemies: Node2D


func _ready() -> void:
	_load_default_weapons()
	_init_ammo()
	_arena_enemies = get_node("../../Arena/Enemies")
	input_buffer.melee_attack_pressed.connect(_on_melee_pressed)
	input_buffer.ranged_attack_pressed.connect(_on_ranged_pressed)


func _physics_process(delta: float) -> void:
	if not player or not player.health.is_alive():
		return

	_update_aim_direction()
	_update_cooldowns(delta)
	_update_ammo(delta)
	_check_continuous_attack()


func _find_player() -> Player:
	var players := get_tree().get_nodes_in_group("players")
	if players.size() > 0:
		return players[0] as Player
	return null


func _load_default_weapons() -> void:
	left_weapon = GameConfig.get_weapon_data("great_sword")
	right_weapon = GameConfig.get_weapon_data("pistol")


func _init_ammo() -> void:
	if left_weapon and left_weapon.max_ammo > 0:
		_left_ammo = left_weapon.max_ammo
	if right_weapon and right_weapon.max_ammo > 0:
		_right_ammo = right_weapon.max_ammo


func reset_ammo() -> void:
	_init_ammo()
	_left_cooldown = 0.0
	_right_cooldown = 0.0


func get_ammo_display() -> String:
	var parts: Array[String] = []
	if left_weapon and left_weapon.weapon_type == "ranged":
		parts.append(str(_left_ammo))
	if right_weapon and right_weapon.weapon_type == "ranged":
		parts.append(str(_right_ammo))
	if parts.is_empty():
		return "∞"
	return " ".join(PackedStringArray(parts))


func _update_aim_direction() -> void:
	var mouse_pos := get_viewport().get_camera_2d().get_global_mouse_position()
	var dir := mouse_pos - player.global_position
	if dir.length() > 1.0:
		dir = dir.normalized()
		player.aim_direction = dir
	player.facing_direction = player.aim_direction


func _update_cooldowns(delta: float) -> void:
	_left_cooldown = maxf(0.0, _left_cooldown - delta)
	_right_cooldown = maxf(0.0, _right_cooldown - delta)


func _update_ammo(delta: float) -> void:
	if left_weapon and left_weapon.max_ammo > 0 and _left_ammo < left_weapon.max_ammo:
		_left_ammo_timer += delta
		if _left_ammo_timer >= GameConfig.RANGED_AMMO_REGEN_RATE:
			_left_ammo = mini(left_weapon.max_ammo, _left_ammo + 1)
			_left_ammo_timer -= GameConfig.RANGED_AMMO_REGEN_RATE

	if right_weapon and right_weapon.max_ammo > 0 and _right_ammo < right_weapon.max_ammo:
		_right_ammo_timer += delta
		if _right_ammo_timer >= GameConfig.RANGED_AMMO_REGEN_RATE:
			_right_ammo = mini(right_weapon.max_ammo, _right_ammo + 1)
			_right_ammo_timer -= GameConfig.RANGED_AMMO_REGEN_RATE


func _check_continuous_attack() -> void:
	match _attack_mode:
		AttackMode.MELEE:
			if Input.is_action_pressed("melee_attack"):
				_try_melee_attack()
			else:
				_attack_mode = AttackMode.NONE
				if Input.is_action_pressed("ranged_attack"):
					_attack_mode = AttackMode.RANGED
					_try_ranged_attack()
		AttackMode.RANGED:
			if Input.is_action_pressed("ranged_attack"):
				_try_ranged_attack()
			else:
				_attack_mode = AttackMode.NONE
				if Input.is_action_pressed("melee_attack"):
					_attack_mode = AttackMode.MELEE
					_try_melee_attack()


# --- Input signals ---

func _on_melee_pressed() -> void:
	if _attack_mode == AttackMode.NONE:
		_attack_mode = AttackMode.MELEE
		_try_melee_attack()


func _on_ranged_pressed() -> void:
	if _attack_mode == AttackMode.NONE:
		_attack_mode = AttackMode.RANGED
		_try_ranged_attack()


# --- Melee attack ---

func _try_melee_attack() -> void:
	if _dual_melee_queue:
		return

	var melee_weapons: Array[WeaponData] = []
	var slots: Array[String] = []

	if left_weapon and left_weapon.weapon_type == "melee" and _left_cooldown <= 0.0:
		melee_weapons.append(left_weapon)
		slots.append("left")
	if right_weapon and right_weapon.weapon_type == "melee" and _right_cooldown <= 0.0:
		melee_weapons.append(right_weapon)
		slots.append("right")

	if melee_weapons.is_empty():
		return

	var aim := player.aim_direction

	if melee_weapons.size() == 1:
		_do_melee_sweep(melee_weapons[0])
		_apply_melee_cooldown(slots[0])
	elif melee_weapons.size() == 2:
		# Dual melee: first immediately, second after 0.1s
		_do_melee_sweep(melee_weapons[0])
		_apply_melee_cooldown(slots[0])
		_dual_melee_queue = true
		_dual_melee_timer = GameConfig.DUAL_MELEE_ATTACK_INTERVAL
		# Remember first hit for overlap bonus
		_melee_first_hits = _get_enemies_in_fan(player.global_position, aim, melee_weapons[0].melee_radius, melee_weapons[0].melee_angle)
		_melee_first_weapon_dmg = melee_weapons[0].base_damage
		# Defer second weapon
		await get_tree().create_timer(GameConfig.DUAL_MELEE_ATTACK_INTERVAL).timeout
		_dual_melee_queue = false
		if player and player.health.is_alive():
			_do_dual_melee_second(melee_weapons[1], slots[1], aim)


func _do_melee_sweep(weapon: WeaponData) -> void:
	var enemies := _get_enemies_in_fan(player.global_position, player.aim_direction, weapon.melee_radius, weapon.melee_angle)

	for enemy in enemies:
		enemy.take_damage(weapon.base_damage, "melee", player, GameConfig.MELEE_KNOCKBACK_DISTANCE)


func _do_dual_melee_second(weapon: WeaponData, slot: String, aim: Vector2) -> void:
	var enemies := _get_enemies_in_fan(player.global_position, aim, weapon.melee_radius, weapon.melee_angle)

	for enemy in enemies:
		if enemy in _melee_first_hits:
			# Overlap: (dmg_a + dmg_b) * 1.2 total, first already dealt dmg_a
			var overlap_total := int(float(_melee_first_weapon_dmg + weapon.base_damage) * GameConfig.DUAL_MELEE_OVERLAP_BONUS)
			var remaining := overlap_total - _melee_first_weapon_dmg
			enemy.take_damage(remaining, "melee", player, GameConfig.MELEE_KNOCKBACK_DISTANCE)
		else:
			enemy.take_damage(weapon.base_damage, "melee", player, GameConfig.MELEE_KNOCKBACK_DISTANCE)

	_melee_first_hits.clear()
	_apply_melee_cooldown(slot)


func _apply_melee_cooldown(slot: String) -> void:
	match slot:
		"left":
			_left_cooldown = left_weapon.attack_cooldown
		"right":
			_right_cooldown = right_weapon.attack_cooldown


# --- Ranged attack ---

func _try_ranged_attack() -> void:
	var ranged_weapons: Array[WeaponData] = []
	var slots: Array[String] = []

	if left_weapon and left_weapon.weapon_type == "ranged" and _left_cooldown <= 0.0 and _left_ammo > 0:
		ranged_weapons.append(left_weapon)
		slots.append("left")
	if right_weapon and right_weapon.weapon_type == "ranged" and _right_cooldown <= 0.0 and _right_ammo > 0:
		ranged_weapons.append(right_weapon)
		slots.append("right")

	if ranged_weapons.is_empty():
		return

	var aim := player.aim_direction
	var is_dual := ranged_weapons.size() == 2

	for i in ranged_weapons.size():
		var weapon := ranged_weapons[i]
		var bullet_dir := aim

		if is_dual:
			bullet_dir = aim.rotated(deg_to_rad(randf_range(-weapon.scatter_degrees, weapon.scatter_degrees)))

		var dmg := int(float(weapon.base_damage) * GameConfig.DUAL_RANGED_DAMAGE_MULT) if is_dual else weapon.base_damage
		_spawn_bullet(weapon, bullet_dir, dmg)
		_consume_ammo(slots[i])

	if is_dual:
		var shared_cd := ranged_weapons[0].attack_cooldown * GameConfig.DUAL_RANGED_COOLDOWN_MULT
		_left_cooldown = shared_cd if left_weapon.weapon_type == "ranged" else _left_cooldown
		_right_cooldown = shared_cd if right_weapon.weapon_type == "ranged" else _right_cooldown
	else:
		_apply_ranged_cooldown(slots[0])


func _apply_ranged_cooldown(slot: String) -> void:
	match slot:
		"left":
			_left_cooldown = left_weapon.attack_cooldown
		"right":
			_right_cooldown = right_weapon.attack_cooldown


func _spawn_bullet(weapon: WeaponData, direction: Vector2, damage: int) -> void:
	var bullet := _bullet_scene.instantiate() as Bullet
	bullet.global_position = player.global_position
	bullet.direction = direction
	bullet.damage = damage
	bullet.speed = weapon.bullet_speed
	bullet.max_range = weapon.max_range
	bullet.source = player
	bullet.damage_type = "ranged"
	get_node("../../Arena/Effects").add_child(bullet)


func _consume_ammo(slot: String) -> void:
	match slot:
		"left":
			_left_ammo = maxi(0, _left_ammo - 1)
			_left_ammo_timer = 0.0
		"right":
			_right_ammo = maxi(0, _right_ammo - 1)
			_right_ammo_timer = 0.0


# --- Fan detection ---

func _get_enemies_in_fan(origin: Vector2, direction: Vector2, radius: float, angle_deg: float) -> Array[Node]:
	var result: Array[Node] = []
	var half_angle_rad := deg_to_rad(angle_deg / 2.0)

	for child in _arena_enemies.get_children():
		if not child.has_method("take_damage"):
			continue
		var enemy := child as Node2D
		var to_enemy: Vector2 = enemy.global_position - origin
		var distance: float = to_enemy.length()
		if distance <= radius and abs(direction.angle_to(to_enemy)) <= half_angle_rad:
			result.append(enemy)

	return result
