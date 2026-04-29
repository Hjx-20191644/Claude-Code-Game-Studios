extends Node2D
class_name HealthComponent

## Manages HP, damage, healing, invincibility, and death for any entity.
## Attach to player or enemy nodes. Communicates via EventBus.

@export var max_hp: int = 100

var current_hp: int = 0
var is_invincible: bool = false
var invincible_timer: float = 0.0

## Damage modifiers (populated by upgrade system).
var additive_modifiers: Array[int] = []
var multiplicative_modifiers: Array[float] = []

enum State { ALIVE, DYING, DEAD }
var state: State = State.ALIVE

## DYING duration differs by entity type. Set by owner.
@export var death_linger: float = 0.3

signal died


func _ready() -> void:
	current_hp = max_hp


func _physics_process(delta: float) -> void:
	if is_invincible:
		invincible_timer -= delta
		if invincible_timer <= 0.0:
			is_invincible = false

	if state == State.DYING:
		death_linger -= delta
		if death_linger <= 0.0:
			state = State.DEAD
			died.emit()


func take_damage(amount: int, damage_type: String, source: Node, knockback_value: float = 0.0) -> int:
	if state != State.ALIVE or is_invincible:
		return 0

	var final_amount := _calculate_damage(amount)
	current_hp = maxi(0, current_hp - final_amount)

	# Hit invincibility
	is_invincible = true
	invincible_timer = GameConfig.PLAYER_HIT_INVINCIBILITY if _is_player() else 0.2

	# Emit signals via EventBus
	EventBus.damage_taken.emit(float(final_amount), global_position)
	EventBus.damage_dealt.emit(float(final_amount), global_position, damage_type)

	if current_hp <= 0:
		_enter_dying(damage_type)

	return final_amount


func heal(amount: int) -> void:
	if amount <= 0 or state != State.ALIVE:
		return
	current_hp = mini(max_hp, current_hp + amount)
	EventBus.health_changed.emit(float(current_hp), float(max_hp))


## Set invincibility externally (e.g., by dodge system).
func set_invincible(duration: float) -> void:
	is_invincible = true
	invincible_timer = maxf(invincible_timer, duration)


func reset() -> void:
	current_hp = max_hp
	state = State.ALIVE
	is_invincible = false
	invincible_timer = 0.0
	additive_modifiers.clear()
	multiplicative_modifiers.clear()


func is_alive() -> bool:
	return state == State.ALIVE


func is_dying() -> bool:
	return state == State.DYING


func get_hp_ratio() -> float:
	if max_hp <= 0:
		return 0.0
	return float(current_hp) / float(max_hp)


func add_additive_modifier(value: int) -> void:
	additive_modifiers.append(value)


func add_multiplicative_modifier(value: float) -> void:
	multiplicative_modifiers.append(value)


func _calculate_damage(base: int) -> int:
	var sum_additive := 0
	for mod in additive_modifiers:
		sum_additive += mod

	var product_multiplicative := 1.0
	for mod in multiplicative_modifiers:
		product_multiplicative *= mod

	var final_dmg := (base + sum_additive) * product_multiplicative
	return maxi(1, ceili(final_dmg))


func _enter_dying(damage_type: String) -> void:
	state = State.DYING

	if _is_player():
		death_linger = GameConfig.PLAYER_DEATH_LINGER
		EventBus.player_died.emit()
	else:
		death_linger = GameConfig.ENEMY_DEATH_LINGER
		var color := Color.WHITE
		var sprite_node := get_parent().get_node_or_null("Sprite")
		if sprite_node and sprite_node is ColorRect:
			color = sprite_node.color
		EventBus.enemy_killed.emit(damage_type, global_position, color)


func _is_player() -> bool:
	return get_parent().is_in_group("players")
