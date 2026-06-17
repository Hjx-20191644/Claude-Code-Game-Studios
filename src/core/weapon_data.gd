extends Resource
class_name WeaponData

## Weapon data resource — pure data layer.
## All parameters are @export for editor tuning. Read-only at runtime.

@export var weapon_name: String = "未命名武器"
@export var weapon_type: String = "melee"
@export var base_damage: int = 25
@export var attack_cooldown: float = 0.5

# Melee-only
@export var melee_angle: float = 105.0
@export var melee_radius: float = 60.0
@export var knockback_mult: float = 1.0

# Ranged-only
@export var bullet_speed: float = 0.0
@export var max_range: float = 0.0
@export var scatter_degrees: float = 0.0
@export var bullet_count: int = 1
@export var pierce_count: int = 0
@export var explosive_radius: float = 0.0

@export var icon: Texture2D


func validate() -> void:
	assert(weapon_type in ["melee", "ranged"], "WeaponData: weapon_type must be 'melee' or 'ranged', got: %s" % weapon_type)
	assert(base_damage >= 1, "WeaponData: base_damage must be >= 1, got: %d" % base_damage)
	assert(attack_cooldown >= 0.05, "WeaponData: attack_cooldown must be >= 0.05, got: %f" % attack_cooldown)
	assert(knockback_mult >= 0.0 and knockback_mult <= 5.0, "WeaponData: knockback_mult must be 0-5, got: %f" % knockback_mult)

	if weapon_type == "melee":
		assert(melee_angle >= 30.0 and melee_angle <= 180.0, "WeaponData: melee_angle must be 30-180, got: %f" % melee_angle)
		assert(melee_radius >= 30.0 and melee_radius <= 120.0, "WeaponData: melee_radius must be 30-120, got: %f" % melee_radius)
		assert(bullet_speed == 0.0, "WeaponData: melee bullet_speed must be 0, got: %f" % bullet_speed)
		assert(max_range == 0.0, "WeaponData: melee max_range must be 0, got: %f" % max_range)
		assert(scatter_degrees == 0.0, "WeaponData: melee scatter_degrees must be 0, got: %f" % scatter_degrees)
		assert(pierce_count == 0, "WeaponData: melee pierce_count must be 0, got: %d" % pierce_count)
		assert(explosive_radius == 0.0, "WeaponData: melee explosive_radius must be 0, got: %f" % explosive_radius)

	if weapon_type == "ranged":
		assert(melee_angle == 0.0, "WeaponData: ranged melee_angle must be 0, got: %f" % melee_angle)
		assert(melee_radius == 0.0, "WeaponData: ranged melee_radius must be 0, got: %f" % melee_radius)
		assert(bullet_speed >= 150.0 and bullet_speed <= 1200.0, "WeaponData: bullet_speed must be 150-1200, got: %f" % bullet_speed)
		assert(max_range >= 150.0 and max_range <= 800.0, "WeaponData: max_range must be 150-800, got: %f" % max_range)
		assert(scatter_degrees >= 0.0 and scatter_degrees <= 20.0, "WeaponData: scatter_degrees must be 0-20, got: %f" % scatter_degrees)
		assert(bullet_count >= 1 and bullet_count <= 8, "WeaponData: bullet_count must be 1-8, got: %d" % bullet_count)
		assert(pierce_count >= 0 and pierce_count <= 10, "WeaponData: pierce_count must be 0-10, got: %d" % pierce_count)
		assert(explosive_radius >= 0.0 and explosive_radius <= 120.0, "WeaponData: explosive_radius must be 0-120, got: %f" % explosive_radius)


func get_display_name() -> String:
	if weapon_name.is_empty():
		return "未命名武器"
	return weapon_name
