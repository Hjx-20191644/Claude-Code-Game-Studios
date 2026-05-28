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


# Attack mode (mutual exclusivity: first pressed wins)
enum AttackMode { NONE, MELEE, RANGED }
var _attack_mode: AttackMode = AttackMode.NONE

# Melee state
var _dual_melee_queue: bool = false
var _dual_melee_timer: float = 0.0
var _melee_first_hits: Array[Node] = []  # enemies hit by first weapon in dual melee
var _melee_first_weapon_dmg: int = 0

const PA = preload("res://src/visuals/pixel_art.gd")
const ST = preload("res://src/visuals/sprite_templates.gd")

# References
@onready var player: Player = _find_player()
@onready var _hitstop: Node = $"../Hitstop"
@onready var input_buffer: Node = $"../InputBuffer"
var _upgrade_applier: UpgradeApplier
var _bullet_scene: PackedScene = preload("res://scenes/bullet.tscn")
var _arena_enemies: Node2D
var _effects_container: Node2D


func _ready() -> void:
	_load_default_weapons()
	_upgrade_applier = get_node("../UpgradeApplier") as UpgradeApplier
	_arena_enemies = get_node("../../Arena/Enemies")
	_effects_container = get_node("../../Arena/Effects")
	input_buffer.melee_attack_pressed.connect(_on_melee_pressed)
	input_buffer.ranged_attack_pressed.connect(_on_ranged_pressed)


func _physics_process(delta: float) -> void:
	if not player or not player.health.is_alive():
		return

	_update_aim_direction()
	_update_cooldowns(delta)
	# unlimited ammo
	_check_continuous_attack()


func _find_player() -> Player:
	var players := get_tree().get_nodes_in_group("players")
	if players.size() > 0:
		return players[0] as Player
	return null


func _load_default_weapons() -> void:
	left_weapon = GameConfig.get_weapon_data(WeaponSelection.left_weapon_id)
	right_weapon = GameConfig.get_weapon_data(WeaponSelection.right_weapon_id)
	if player:
		var display_type := left_weapon.weapon_type if left_weapon else right_weapon.weapon_type
		player.update_weapon_visual(display_type)


var _nearest_enemy_dist: float = INF

func _update_aim_direction() -> void:
	var nearest := _find_nearest_enemy()
	if nearest:
		var dir := nearest.global_position - player.global_position
		_nearest_enemy_dist = dir.length()
		if _nearest_enemy_dist > 1.0:
			player.aim_direction = dir.normalized()
	else:
		_nearest_enemy_dist = INF
	player.facing_direction = player.aim_direction


func _find_nearest_enemy() -> Node2D:
	var closest: Node2D = null
	var closest_weighted: float = INF
	for child in _arena_enemies.get_children():
		if not child.has_method("take_damage"):
			continue
		var enemy := child as Node2D
		var dist := player.global_position.distance_squared_to(enemy.global_position)
		var weighted := dist * _get_enemy_priority(child)
		if weighted < closest_weighted:
			closest_weighted = weighted
			closest = enemy
	return closest


func _get_enemy_priority(enemy: Node) -> float:
	var e := enemy as Enemy
	if not e or not e.enemy_data:
		return 1.0
	match e.enemy_data.enemy_type:
		"buffer":   return 0.25
		"ranged":   return 0.4
		"spawner":  return 0.5
		"egg":      return 0.55
		"charger":  return 0.65
		"exploder": return 0.7
		"melee":    return 0.8
		"tank":     return 1.0
		"reward":   return 1.5
		"boss":     return 1.0
		_:          return 1.0


func _update_cooldowns(delta: float) -> void:
	_left_cooldown = maxf(0.0, _left_cooldown - delta)
	_right_cooldown = maxf(0.0, _right_cooldown - delta)

const MELEE_PRE_FIRE_MULT: float = 1.6

func _check_continuous_attack() -> void:
	if _nearest_enemy_dist >= INF * 0.5:
		return

	# Melee: pre-fire when enemy is within 1.6x weapon range (anticipation)
	if _can_melee_attack() and _nearest_enemy_dist <= _max_melee_range() * MELEE_PRE_FIRE_MULT:
		_try_melee_attack()

	# Ranged: fire when enemy within max range
	if _can_ranged_attack() and _nearest_enemy_dist <= _max_ranged_range():
		_try_ranged_attack()


func _can_melee_attack() -> bool:
	return (left_weapon and left_weapon.weapon_type == "melee" and _left_cooldown <= 0.0) or \
		   (right_weapon and right_weapon.weapon_type == "melee" and _right_cooldown <= 0.0)


func _can_ranged_attack() -> bool:
	return (left_weapon and left_weapon.weapon_type == "ranged" and _left_cooldown <= 0.0) or \
		   (right_weapon and right_weapon.weapon_type == "ranged" and _right_cooldown <= 0.0)


func _max_melee_range() -> float:
	var r: float = 0.0
	if left_weapon and left_weapon.weapon_type == "melee":
		r = maxf(r, left_weapon.melee_radius)
	if right_weapon and right_weapon.weapon_type == "melee":
		r = maxf(r, right_weapon.melee_radius)
	return r


func _max_ranged_range() -> float:
	var r: float = 0.0
	if left_weapon and left_weapon.weapon_type == "ranged":
		r = maxf(r, left_weapon.max_range)
	if right_weapon and right_weapon.weapon_type == "ranged":
		r = maxf(r, right_weapon.max_range)
	return r


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
		_melee_first_weapon_dmg = _calc_melee_damage(melee_weapons[0].base_damage, _get_melee_damage_mult(), _roll_crit())
		# Defer second weapon
		await get_tree().create_timer(GameConfig.DUAL_MELEE_ATTACK_INTERVAL).timeout
		_dual_melee_queue = false
		if player and player.health.is_alive():
			_do_dual_melee_second(melee_weapons[1], slots[1], aim)


func _do_melee_sweep(weapon: WeaponData) -> void:
	_flash_player_melee()
	_spawn_slash_effect(player.aim_direction, weapon.melee_radius, weapon.melee_angle)
	var enemies := _get_enemies_in_fan(player.global_position, player.aim_direction, weapon.melee_radius, weapon.melee_angle)
	var dmg_mult := _get_melee_damage_mult()
	var is_crit := _roll_crit()

	for enemy in enemies:
		var dmg := _calc_melee_damage(weapon.base_damage, dmg_mult, is_crit)
		enemy.take_damage(dmg, "melee", player, GameConfig.MELEE_KNOCKBACK_DISTANCE * weapon.knockback_mult)
		EventBus.player_dealt_damage.emit(dmg)


func _do_dual_melee_second(weapon: WeaponData, slot: String, aim: Vector2) -> void:
	_spawn_slash_effect(aim, weapon.melee_radius, weapon.melee_angle)
	var enemies := _get_enemies_in_fan(player.global_position, aim, weapon.melee_radius, weapon.melee_angle)

	for enemy in enemies:
		if enemy in _melee_first_hits:
			# Overlap: (dmg_a + dmg_b) * 1.2 total, first already dealt dmg_a
			var second_dmg := _calc_melee_damage(weapon.base_damage, _get_melee_damage_mult(), _roll_crit())
			var overlap_total := int(float(_melee_first_weapon_dmg + second_dmg) * GameConfig.DUAL_MELEE_OVERLAP_BONUS)
			var remaining := overlap_total - _melee_first_weapon_dmg
			enemy.take_damage(remaining, "melee", player, GameConfig.MELEE_KNOCKBACK_DISTANCE * weapon.knockback_mult)
			EventBus.player_dealt_damage.emit(remaining)
		else:
			var dmg := _calc_melee_damage(weapon.base_damage, _get_melee_damage_mult(), _roll_crit())
			enemy.take_damage(dmg, "melee", player, GameConfig.MELEE_KNOCKBACK_DISTANCE * weapon.knockback_mult)
			EventBus.player_dealt_damage.emit(dmg)

	_melee_first_hits.clear()
	_apply_melee_cooldown(slot)


func _apply_melee_cooldown(slot: String) -> void:
	var speed_mult := 1.0
	if _upgrade_applier:
		speed_mult = _upgrade_applier.get_multiplier("attack_speed")
	match slot:
		"left":
			_left_cooldown = left_weapon.attack_cooldown * speed_mult
		"right":
			_right_cooldown = right_weapon.attack_cooldown * speed_mult


# --- Ranged attack ---

func _try_ranged_attack() -> void:
	var ranged_weapons: Array[WeaponData] = []
	var slots: Array[String] = []

	if left_weapon and left_weapon.weapon_type == "ranged" and _left_cooldown <= 0.0 :
		ranged_weapons.append(left_weapon)
		slots.append("left")
	if right_weapon and right_weapon.weapon_type == "ranged" and _right_cooldown <= 0.0 :
		ranged_weapons.append(right_weapon)
		slots.append("right")

	if ranged_weapons.is_empty():
		return

	var aim := player.aim_direction
	var is_dual := ranged_weapons.size() == 2

	for i in ranged_weapons.size():
		var weapon := ranged_weapons[i]
		var bullets := maxi(1, weapon.bullet_count)
		var half_spread := deg_to_rad(weapon.scatter_degrees / 2.0)

		for j in bullets:
			var bullet_dir := aim
			if bullets > 1:
				var t := float(j) / float(bullets - 1)
				var angle := lerpf(-half_spread, half_spread, t)
				bullet_dir = aim.rotated(angle)
			elif is_dual:
				bullet_dir = aim.rotated(deg_to_rad(randf_range(-weapon.scatter_degrees, weapon.scatter_degrees)))

			var dmg := weapon.base_damage
			if is_dual:
				dmg = int(float(dmg) * GameConfig.DUAL_RANGED_DAMAGE_MULT)
			dmg = int(float(dmg) * _get_ranged_damage_mult())
			_spawn_bullet(weapon, bullet_dir, dmg)

		# unlimited ammo

	if is_dual:
		var speed_mult := 1.0
		if _upgrade_applier:
			speed_mult = _upgrade_applier.get_multiplier("attack_speed")
		var shared_cd := ranged_weapons[0].attack_cooldown * GameConfig.DUAL_RANGED_COOLDOWN_MULT * speed_mult
		_left_cooldown = shared_cd if left_weapon.weapon_type == "ranged" else _left_cooldown
		_right_cooldown = shared_cd if right_weapon.weapon_type == "ranged" else _right_cooldown
	else:
		_apply_ranged_cooldown(slots[0])


func _apply_ranged_cooldown(slot: String) -> void:
	var speed_mult := 1.0
	if _upgrade_applier:
		speed_mult = _upgrade_applier.get_multiplier("attack_speed")
	match slot:
		"left":
			_left_cooldown = left_weapon.attack_cooldown * speed_mult
		"right":
			_right_cooldown = right_weapon.attack_cooldown * speed_mult


func _spawn_bullet(weapon: WeaponData, direction: Vector2, damage: int) -> void:
	_spawn_muzzle_flash(direction)
	var bullet := _bullet_scene.instantiate() as Bullet
	bullet.global_position = player.global_position
	bullet.direction = direction
	bullet.damage = damage
	bullet.speed = weapon.bullet_speed
	bullet.max_range = weapon.max_range
	bullet.source = player
	bullet.damage_type = "ranged"
	bullet.knockback_value = GameConfig.MELEE_KNOCKBACK_DISTANCE * weapon.knockback_mult
	bullet.pierce_count = weapon.pierce_count
	bullet.explosive_radius = weapon.explosive_radius
	bullet.collision_mask = 2 + 128  # Enemies + Walls
	get_node("../../Arena/Effects").add_child(bullet)


func _flash_player_melee() -> void:
	if not player:
		return
	# Brief white flash on player sprite
	var ps := player.get_node_or_null("Sprite") as Sprite2D
	if ps:
		ps.self_modulate = Color(1.5, 1.5, 1.5)
		var tw := create_tween()
		tw.tween_property(ps, "self_modulate", player.sprite.self_modulate, 0.08)
	# Weapon swing flash
	var ws := player.get_node_or_null("WeaponSprite") as Sprite2D
	if ws:
		var orig_color := ws.self_modulate
		ws.self_modulate = Color(1.5, 1.5, 1.5)
		var tw := create_tween()
		tw.tween_property(ws, "self_modulate", orig_color, 0.08)


func _spawn_slash_effect(direction: Vector2, radius: float, angle_deg: float) -> void:
	var fx := Sprite2D.new()
	fx.texture = PA.generate_sprite(int(radius), int(radius), ST.slash_arc_sprite, [PA.MATERIAL_ENERGY])
	fx.self_modulate = Color(1.0, 1.0, 1.0, 0.6)
	fx.rotation = direction.angle() - deg_to_rad(angle_deg / 2.0)
	fx.global_position = player.global_position
	_effects_container.add_child(fx)
	var tw := fx.create_tween()
	tw.tween_property(fx, "scale", Vector2(1.2, 1.2), 0.15)
	tw.parallel().tween_property(fx, "self_modulate", Color(1.0, 1.0, 1.0, 0.0), 0.15)
	tw.tween_callback(fx.queue_free)


func _spawn_muzzle_flash(direction: Vector2) -> void:
	var fx := Sprite2D.new()
	fx.texture = PA.generate_sprite(20, 20, ST.muzzle_flash_sprite, [PA.MATERIAL_ENERGY])
	fx.self_modulate = Color(1.0, 0.9, 0.2, 0.8)
	fx.rotation = direction.angle()
	fx.global_position = player.global_position + direction * 22.0
	_effects_container.add_child(fx)
	var tw := fx.create_tween()
	tw.tween_property(fx, "self_modulate", Color(1.0, 0.5, 0.0, 0.0), 0.08)
	tw.parallel().tween_property(fx, "scale", Vector2(1.5, 1.5), 0.08)
	tw.tween_callback(fx.queue_free)


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


# --- Upgrade-aware damage helpers ---

func _get_melee_damage_mult() -> float:
	if _upgrade_applier:
		return _upgrade_applier.get_multiplier("melee_damage_bonus")
	return 1.0


func _get_ranged_damage_mult() -> float:
	if _upgrade_applier:
		return _upgrade_applier.get_multiplier("ranged_damage_bonus")
	return 1.0


func _roll_crit() -> bool:
	if not _upgrade_applier:
		return false
	return randf() < _upgrade_applier.get_raw("crit_chance")


func _calc_melee_damage(base: int, dmg_mult: float, is_crit: bool) -> int:
	var dmg := float(base) * dmg_mult
	if is_crit:
		dmg *= 2.0
	return maxi(1, int(dmg))
