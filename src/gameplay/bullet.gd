extends Area2D
class_name Bullet
const PA = preload("res://src/visuals/pixel_art.gd")
const ST = preload("res://src/visuals/sprite_templates.gd")

## Projectile fired by ranged weapons. Moves in a straight line,
## hits enemies via body_entered, self-destructs at max_range.
## Supports piercing (pass through N enemies) and explosive (area on hit).

var damage: int = 15
var speed: float = 600.0
var direction: Vector2 = Vector2.RIGHT
var max_range: float = 400.0
var source: Node
var damage_type: String = "ranged"
var knockback_value: float = 0.0
var pierce_count: int = 0
var explosive_radius: float = 0.0

var _distance_traveled: float = 0.0
var _hit_bodies: Array[Node] = []  # Track pierced-through enemies


func _ready() -> void:
	body_entered.connect(_on_body_entered)
	var sprite: Sprite2D = $Sprite
	sprite.texture = PA.generate_sprite(8, 8, ST.bullet_sprite)
	sprite.self_modulate = Color(1.0, 0.8, 0.2)


func _physics_process(delta: float) -> void:
	var move := direction * speed * delta
	global_position += move
	_distance_traveled += move.length()

	if _distance_traveled >= max_range:
		queue_free()


func _on_body_entered(body: Node) -> void:
	if not body.has_method("take_damage"):
		# Hit a wall or other non-damageable
		queue_free()
		return
	if body in _hit_bodies:
		return  # Already pierced through this one

	_hit_bodies.append(body)
	body.take_damage(damage, damage_type, source, knockback_value)

	if explosive_radius > 0.0:
		_explode()

	if pierce_count > 0:
		pierce_count -= 1
	else:
		queue_free()


func _explode() -> void:
	# Find all damageable bodies within explosive_radius
	var space := get_world_2d().direct_space_state
	if not space:
		return
	var query := PhysicsShapeQueryParameters2D.new()
	var shape := CircleShape2D.new()
	shape.radius = explosive_radius
	query.shape = shape
	query.transform = Transform2D(0, global_position)
	query.collision_mask = 2  # Enemy layer
	var results := space.intersect_shape(query)
	for result in results:
		var body: Node = result.get("collider")
		if body and body.has_method("take_damage") and body not in _hit_bodies:
			_hit_bodies.append(body)
			body.take_damage(damage, damage_type, source, 0.0)
	queue_free()
