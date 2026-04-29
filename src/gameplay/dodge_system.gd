extends Node
class_name DodgeSystem

## Dodge system: quick dash with invincibility frames.
## Overrides player movement during dodge, allows attacking while dodging.

enum State { READY, DODGING, COOLDOWN }

var _state: State = State.READY
var _dodge_timer: float = 0.0
var _cooldown_timer: float = 0.0
var _dodge_direction: Vector2 = Vector2.ZERO

@onready var player: Player = _find_player()
@onready var input_buffer: Node = $"../InputBuffer"


func _ready() -> void:
	assert(GameConfig.DODGE_COOLDOWN >= 0.1, "DodgeSystem: DODGE_COOLDOWN must be >= 0.1")
	input_buffer.dodge_pressed.connect(_on_dodge_pressed)


func _physics_process(delta: float) -> void:
	match _state:
		State.DODGING:
			_dodge_timer += delta
			if _dodge_timer >= _dodge_duration():
				_end_dodge()
		State.COOLDOWN:
			_cooldown_timer += delta
			if _cooldown_timer >= GameConfig.DODGE_COOLDOWN:
				_state = State.READY


func _find_player() -> Player:
	var players := get_tree().get_nodes_in_group("players")
	if players.size() > 0:
		return players[0] as Player
	return null


func _on_dodge_pressed() -> void:
	if _state != State.READY:
		return
	if not player or not player.health.is_alive():
		return

	# Determine dodge direction
	if player.move_direction.length() > 0.1:
		_dodge_direction = player.move_direction
	else:
		_dodge_direction = player.aim_direction

	# Start dodge
	_state = State.DODGING
	_dodge_timer = 0.0
	player.start_dodge_override(_dodge_direction, GameConfig.DODGE_SPEED)
	player.health.set_invincible(GameConfig.DODGE_INVINCIBILITY)
	EventBus.dodge_started.emit()


func _end_dodge() -> void:
	player.end_dodge_override()
	_state = State.COOLDOWN
	_cooldown_timer = 0.0
	EventBus.dodge_cooldown_changed.emit(GameConfig.DODGE_COOLDOWN)


func _dodge_duration() -> float:
	return GameConfig.DODGE_DISTANCE / GameConfig.DODGE_SPEED


## Returns cooldown progress as 0.0 - 1.0 (1.0 = ready).
func get_cooldown_ratio() -> float:
	if _state == State.COOLDOWN and GameConfig.DODGE_COOLDOWN > 0.0:
		return _cooldown_timer / GameConfig.DODGE_COOLDOWN
	return 1.0


func is_dodging() -> bool:
	return _state == State.DODGING
