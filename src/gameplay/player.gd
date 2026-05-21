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
var _upgrade_applier: UpgradeApplier


func _ready() -> void:
	add_to_group("players")
	_upgrade_applier = get_node("/root/Main/Systems/UpgradeApplier") as UpgradeApplier
	sprite.texture = PA.generate_sprite(24, 24, ST.player_sprite)
	sprite.self_modulate = Color(0.3, 0.7, 1.0)


var _aura_timer: float = 0.0
var _regen_timer: float = 0.0


func _physics_process(delta: float) -> void:
	if not health.is_alive():
		return

	# Update aim direction from mouse.
	# facing_direction is controlled by CombatSystem.
	var mouse_pos := get_global_mouse_position()
	aim_direction = (mouse_pos - global_position)
	if aim_direction.length() < 1.0:
		aim_direction = facing_direction
	else:
		aim_direction = aim_direction.normalized()

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


func heal(amount: int) -> void:
	health.heal(amount)


## Called by dodge system to take over movement.
func start_dodge_override(direction: Vector2, speed: float) -> void:
	is_dodging = true
	dodge_override_velocity = direction * speed


## Called by dodge system when dodge ends.
func end_dodge_override() -> void:
	is_dodging = false
	dodge_override_velocity = Vector2.ZERO


func _apply_damage_aura(damage: float) -> void:
	var enemies := get_tree().get_nodes_in_group("enemies")
	for e in enemies:
		if not is_instance_valid(e):
			continue
		var enemy := e as Node2D
		if enemy and enemy.global_position.distance_to(global_position) <= 120.0:
			if enemy.has_method("take_damage"):
				enemy.take_damage(int(damage), "aura", self, 0.0)
