extends CharacterBody2D
class_name Player

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

@onready var sprite: ColorRect = $Sprite


func _ready() -> void:
	add_to_group("players")


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
		velocity = move_direction * base_speed

	move_and_slide()


func take_damage(amount: int, damage_type: String, source: Node, knockback_value: float = 0.0) -> int:
	return health.take_damage(amount, damage_type, source, knockback_value)


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
