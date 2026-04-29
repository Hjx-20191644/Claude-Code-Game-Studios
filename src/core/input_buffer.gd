extends Node

## Input system with buffering to prevent missed inputs.
## Provides standardized move_vector and action states for other systems.

signal melee_attack_pressed
signal ranged_attack_pressed
signal dodge_pressed

## Movement vector (-1 to 1 on each axis), updated every frame.
var move_vector: Vector2 = Vector2.ZERO

## Input deadzone for movement.
const MOVE_DEADZONE: float = 0.1

## Buffered action states — set by _input, consumed by _physics_process.
var _melee_buffered: bool = false
var _ranged_buffered: bool = false
var _dodge_buffered: bool = false


func _input(event: InputEvent) -> void:
	if event.is_action_pressed("melee_attack"):
		_melee_buffered = true
	if event.is_action_pressed("ranged_attack"):
		_ranged_buffered = true
	if event.is_action_pressed("dodge"):
		_dodge_buffered = true


func _physics_process(_delta: float) -> void:
	# Update move vector from axis inputs.
	move_vector = Vector2(
		Input.get_axis("move_left", "move_right"),
		Input.get_axis("move_up", "move_down")
	)
	if move_vector.length() < MOVE_DEADZONE:
		move_vector = Vector2.ZERO

	# Emit buffered actions and clear flags.
	if _melee_buffered:
		melee_attack_pressed.emit()
		_melee_buffered = false
	if _ranged_buffered:
		ranged_attack_pressed.emit()
		_ranged_buffered = false
	if _dodge_buffered:
		dodge_pressed.emit()
		_dodge_buffered = false


## Check if a melee attack is held (for continuous fire while button held).
func is_melee_held() -> bool:
	return Input.is_action_pressed("melee_attack")


## Check if a ranged attack is held (for continuous fire while button held).
func is_ranged_held() -> bool:
	return Input.is_action_pressed("ranged_attack")


## Get normalized 8-direction from current move_vector.
func get_8_direction() -> Vector2:
	if move_vector.length() < MOVE_DEADZONE:
		return Vector2.ZERO
	return move_vector.normalized().snapped(Vector2(1, 1).normalized()).normalized()
