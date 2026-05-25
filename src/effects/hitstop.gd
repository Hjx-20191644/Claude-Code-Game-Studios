extends Node

## Hitstop / freeze-frame system. Brief time slowdown on impactful hits.
## Attach as child of Systems node. Access via get_node("/root/Main/Systems/Hitstop").

var _active_tween: Tween


func trigger(duration: float = 0.05, time_scale: float = 0.1) -> void:
	if _active_tween and _active_tween.is_valid():
		_active_tween.kill()
	Engine.time_scale = time_scale
	_active_tween = create_tween()
	_active_tween.tween_property(Engine, "time_scale", 1.0, duration).set_ease(Tween.EASE_OUT)
