extends Resource
class_name EnemyData

## Enemy data resource — pure data layer.
## All parameters are @export for editor tuning. Read-only at runtime.

@export var enemy_name: String = "未命名敌人"
@export var enemy_type: String = "melee"
@export var max_hp: int = 30
@export var move_speed: float = 150.0
@export var contact_damage: int = 15
@export var contact_damage_interval: float = 0.5
@export var knockback_speed: float = 400.0
@export var contact_radius: float = 24.0


func validate() -> void:
	assert(enemy_type in ["melee", "ranged"], "EnemyData: enemy_type must be 'melee' or 'ranged'")
	assert(max_hp >= 1, "EnemyData: max_hp must be >= 1")
	assert(move_speed >= 50.0, "EnemyData: move_speed must be >= 50")
	assert(contact_damage >= 1, "EnemyData: contact_damage must be >= 1")
	assert(contact_damage_interval >= 0.1, "EnemyData: contact_damage_interval must be >= 0.1")


func get_display_name() -> String:
	if enemy_name.is_empty():
		return "未命名敌人"
	return enemy_name
