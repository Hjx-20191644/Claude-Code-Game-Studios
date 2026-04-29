extends Node2D
class_name VfxParticle

## Minimal geometric particle: draws a small rectangle, animates outward, fades and frees.
## Modulate color controls the visible color (draw_rect uses WHITE for tinting).

var _size: float = 4.0


func _ready() -> void:
	queue_redraw()


func _draw() -> void:
	var half := _size / 2.0
	draw_rect(Rect2(-half, -half, _size, _size), Color.WHITE)


func set_draw_size(s: float) -> void:
	_size = s
	queue_redraw()


func play(lifetime: float, velocity: Vector2, size: float = 4.0) -> void:
	_size = size
	queue_redraw()
	var tw := create_tween().set_parallel(true)
	tw.tween_property(self, "position", position + velocity * lifetime, lifetime).set_ease(Tween.EASE_OUT)
	tw.tween_property(self, "modulate:a", 0.0, lifetime)
	# Shrink by scaling
	tw.tween_property(self, "scale", Vector2(0.3, 0.3), lifetime)
	await tw.finished
	queue_free()
