extends Area2D
## Single shard pickup: floats toward the player and auto-collects.

var value: int = 1
var _player: Node2D
var _attract_radius: float = 100.0
var _attract_speed: float = 300.0
var _collect_radius: float = 16.0


func _ready() -> void:
	collision_layer = 0
	collision_mask = 1  # detect Player layer
	body_entered.connect(_on_body_entered)

	var shape := CollisionShape2D.new()
	shape.shape = CircleShape2D.new()
	shape.shape.radius = _collect_radius
	add_child(shape)

	var sprite := ColorRect.new()
	sprite.size = Vector2(6, 6)
	sprite.position = Vector2(-3, -3)
	sprite.color = Color(0.2, 0.9, 1.0)  # cyan
	add_child(sprite)


func setup(pos: Vector2, val: int, player: Node2D, attract_radius: float = 100.0) -> void:
	global_position = pos
	value = val
	_player = player
	_attract_radius = attract_radius


func _physics_process(delta: float) -> void:
	if not _player or not is_instance_valid(_player):
		queue_free()
		return

	var to_player := _player.global_position - global_position
	var dist := to_player.length()

	if dist <= _attract_radius:
		var dir := to_player.normalized()
		global_position += dir * _attract_speed * delta


func _on_body_entered(_body: Node2D) -> void:
	EventBus.shard_collected.emit(value, 0)  # total filled by ShardManager
	queue_free()
