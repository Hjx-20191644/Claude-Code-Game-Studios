extends Area2D
class_name Bullet

## Projectile fired by ranged weapons. Moves in a straight line,
## hits enemies via body_entered, self-destructs at max_range.

var damage: int = 15
var speed: float = 600.0
var direction: Vector2 = Vector2.RIGHT
var max_range: float = 400.0
var source: Node
var damage_type: String = "ranged"
var knockback_value: float = 0.0

var _distance_traveled: float = 0.0


func _ready() -> void:
	body_entered.connect(_on_body_entered)


func _physics_process(delta: float) -> void:
	var move := direction * speed * delta
	global_position += move
	_distance_traveled += move.length()

	if _distance_traveled >= max_range:
		queue_free()


func _on_body_entered(body: Node) -> void:
	if not body.has_method("take_damage"):
		return

	body.take_damage(damage, damage_type, source, knockback_value)
	queue_free()
