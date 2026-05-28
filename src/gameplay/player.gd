extends CharacterBody2D
class_name Player
const PA = preload("res://src/visuals/pixel_art.gd")
const ST = preload("res://src/visuals/sprite_templates.gd")

## Player character: movement + aim direction.
## Combat and dodge are separate systems that read from / override this node.

@onready var health: HealthComponent = $HealthComponent
@onready var input_buffer: Node = get_node("/root/Main/Systems/InputBuffer")

var move_direction: Vector2 = Vector2.ZERO
var facing_direction: Vector2 = Vector2.RIGHT
var aim_direction: Vector2 = Vector2.RIGHT
var base_speed: float = GameConfig.PLAYER_BASE_SPEED
var is_dodging: bool = false
var dodge_override_velocity: Vector2 = Vector2.ZERO

@onready var sprite: Sprite2D = $Sprite
@onready var weapon_sprite: Sprite2D = $WeaponSprite
@onready var left_arm: Sprite2D = $LeftArm
@onready var right_arm: Sprite2D = $RightArm
@onready var left_leg: Sprite2D = $LeftLeg
@onready var right_leg: Sprite2D = $RightLeg
var _upgrade_applier: UpgradeApplier

# Animation state
var _player_frames: Array[ImageTexture] = []
var _anim_frame: int = 0
var _anim_timer: float = 0.0
const ANIM_INTERVAL: float = 0.4


func _ready() -> void:
	add_to_group("players")
	_upgrade_applier = get_node("/root/Main/Systems/UpgradeApplier") as UpgradeApplier
	EventBus.player_dealt_damage.connect(_on_player_dealt_damage)

	sprite.texture = PA.generate_sprite(48, 48, ST.player_sprite, [PA.MATERIAL_FLESH])
	sprite.self_modulate = Color(0.3, 0.7, 1.0)
	sprite.scale = Vector2(GameConfig.ENTITY_SCALE, GameConfig.ENTITY_SCALE)

	weapon_sprite.texture = PA.generate_sprite(24, 16, ST.gun_sprite, [PA.MATERIAL_METAL])
	weapon_sprite.self_modulate = Color(0.8, 0.6, 0.3)
	weapon_sprite.scale = Vector2(GameConfig.ENTITY_SCALE, GameConfig.ENTITY_SCALE)

	# Limbs
	var limb_tex := PA.generate_sprite(4, 16, ST.arm_stick_sprite, [PA.MATERIAL_FLESH])
	var leg_tex := PA.generate_sprite(4, 16, ST.leg_stick_sprite, [PA.MATERIAL_FLESH])
	for limb in [left_arm, right_arm]:
		limb.texture = limb_tex
		limb.self_modulate = Color(0.2, 0.6, 0.9)
	for limb in [left_leg, right_leg]:
		limb.texture = leg_tex
		limb.self_modulate = Color(0.2, 0.5, 0.8)

	# Animation: 3-frame breathing cycle
	_player_frames = PA.generate_animated_frames(
		[ST.player_sprite, ST.player_sprite_idle_breath_in, ST.player_sprite_idle_breath_out],
		48, 48,
		[PA.MATERIAL_FLESH]
	)


var _walk_cycle: float = 0.0
var _aura_timer: float = 0.0
var _regen_timer: float = 0.0


func _physics_process(delta: float) -> void:
	if not health.is_alive():
		for limb in [left_arm, right_arm, left_leg, right_leg]:
			limb.visible = false
		return

	# Idle breathing animation
	if _player_frames.size() > 0:
		_anim_timer += delta
		if _anim_timer >= ANIM_INTERVAL:
			_anim_timer -= ANIM_INTERVAL
			_anim_frame = (_anim_frame + 1) % _player_frames.size()
			sprite.texture = _player_frames[_anim_frame]

	# aim_direction is set by CombatSystem (auto-aim).
	weapon_sprite.rotation = aim_direction.angle()
	weapon_sprite.position = aim_direction * 18.0

	# Limb animation
	_animate_limbs(delta)

	# Movement
	if is_dodging:
		velocity = dodge_override_velocity
	else:
		if input_buffer:
			move_direction = input_buffer.move_vector.normalized() if input_buffer.move_vector.length() > 0.1 else Vector2.ZERO
		var speed_mult := 1.0
		var speed_flat := 0.0
		if _upgrade_applier:
			speed_mult = _upgrade_applier.get_multiplier("move_speed_bonus")
			speed_flat = _upgrade_applier.get_absolute("move_speed_flat")
		velocity = move_direction * (base_speed + speed_flat) * speed_mult

	move_and_slide()

	# Upgrade: damage aura
	if _upgrade_applier:
		var aura_dmg := _upgrade_applier.get_absolute("damage_aura")
		if aura_dmg > 0.0:
			_aura_timer += delta
			if _aura_timer >= 1.0:
				_aura_timer -= 1.0
				_apply_damage_aura(aura_dmg)

	# Upgrade: hp regen
	if _upgrade_applier:
		var regen := _upgrade_applier.get_absolute("hp_regen")
		if regen > 0.0:
			_regen_timer += delta
			if _regen_timer >= 1.0:
				_regen_timer -= 1.0
				heal(int(regen))


func take_damage(amount: int, damage_type: String, source: Node, knockback_value: float = 0.0) -> int:
	var result := health.take_damage(amount, damage_type, source, knockback_value)
	# Thorn reflect
	if _upgrade_applier and source and is_instance_valid(source) and source.has_method("take_damage"):
		var reflect_ratio := _upgrade_applier.get_multiplier("thorn_reflect") - 1.0
		if reflect_ratio > 0.0:
			var reflect_dmg := maxi(1, int(float(amount) * reflect_ratio))
			source.take_damage(reflect_dmg, "reflect", self, 0.0)
	return result


## Update weapon sprite to match the given weapon type.
func update_weapon_visual(weapon_type: String) -> void:
	if weapon_type == "melee":
		weapon_sprite.texture = PA.generate_sprite(16, 32, ST.sword_sprite, [PA.MATERIAL_METAL])
		weapon_sprite.self_modulate = Color(0.8, 0.7, 0.5)
	else:
		weapon_sprite.texture = PA.generate_sprite(24, 16, ST.gun_sprite, [PA.MATERIAL_METAL])
		weapon_sprite.self_modulate = Color(0.8, 0.6, 0.3)


func heal(amount: int) -> void:
	health.heal(amount)


func _on_player_dealt_damage(amount: int) -> void:
	if _upgrade_applier:
		var ratio := _upgrade_applier.get_raw("lifesteal_ratio")
		if ratio > 0.0:
			heal(maxi(1, int(float(amount) * ratio)))


## Called by dodge system to take over movement.
func start_dodge_override(direction: Vector2, speed: float) -> void:
	is_dodging = true
	dodge_override_velocity = direction * speed


## Called by dodge system when dodge ends.
func end_dodge_override() -> void:
	is_dodging = false
	dodge_override_velocity = Vector2.ZERO


func _animate_limbs(delta: float) -> void:
	const LEG_SWING := 0.45
	const LEG_SPEED := 10.0

	# Legs — pendulum swing based on movement speed
	var speed := velocity.length()
	if speed > 5.0 and not is_dodging:
		_walk_cycle += delta * speed / base_speed * LEG_SPEED
	else:
		_walk_cycle = move_toward(_walk_cycle, 0.0, delta * 8.0)

	left_leg.rotation = sin(_walk_cycle) * LEG_SWING
	right_leg.rotation = sin(_walk_cycle + PI) * LEG_SWING

	# Arms — follow aim direction from shoulder pivot
	# arm at rotation 0 points down; convert to standard angle
	var arm_angle := aim_direction.angle() - PI / 2.0
	left_arm.rotation = arm_angle
	right_arm.rotation = arm_angle


func _apply_damage_aura(damage: float) -> void:
	var dmg := int(damage)
	var enemies := get_tree().get_nodes_in_group("enemies")
	for e in enemies:
		if not is_instance_valid(e):
			continue
		var enemy := e as Node2D
		if enemy and enemy.global_position.distance_to(global_position) <= 90.0:
			if enemy.has_method("take_damage"):
				enemy.take_damage(dmg, "aura", self, 0.0)
				EventBus.player_dealt_damage.emit(dmg)
