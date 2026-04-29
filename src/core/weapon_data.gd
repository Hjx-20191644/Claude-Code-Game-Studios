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

# Ranged-only
@export var bullet_speed: float = 0.0
@export var max_range: float = 0.0
@export var scatter_degrees: float = 0.0
@export var max_ammo: int = 0

@export var icon: Texture2D


## Validate weapon data after loading from .tres.
## Called by GameConfig.get_weapon_data() after ResourceLoader.load().
func validate() -> void:
	assert(weapon_type in ["melee", "ranged"], "WeaponData: weapon_type must be 'melee' or 'ranged', got: %s" % weapon_type)
	assert(base_damage >= 1, "WeaponData: base_damage must be >= 1, got: %d" % base_damage)
	assert(attack_cooldown >= 0.1, "WeaponData: attack_cooldown must be >= 0.1, got: %f" % attack_cooldown)

	if weapon_type == "melee":
		assert(melee_angle >= 60.0 and melee_angle <= 180.0, "WeaponData: melee_angle must be 60-180, got: %f" % melee_angle)
		assert(melee_radius >= 30.0 and melee_radius <= 100.0, "WeaponData: melee_radius must be 30-100, got: %f" % melee_radius)
		assert(bullet_speed == 0.0, "WeaponData: melee bullet_speed must be 0, got: %f" % bullet_speed)
		assert(max_range == 0.0, "WeaponData: melee max_range must be 0, got: %f" % max_range)
		assert(scatter_degrees == 0.0, "WeaponData: melee scatter_degrees must be 0, got: %f" % scatter_degrees)
		assert(max_ammo == 0, "WeaponData: melee max_ammo must be 0, got: %d" % max_ammo)

	if weapon_type == "ranged":
		assert(melee_angle == 0.0, "WeaponData: ranged melee_angle must be 0, got: %f" % melee_angle)
		assert(melee_radius == 0.0, "WeaponData: ranged melee_radius must be 0, got: %f" % melee_radius)
		assert(bullet_speed >= 300.0 and bullet_speed <= 1000.0, "WeaponData: bullet_speed must be 300-1000, got: %f" % bullet_speed)
		assert(max_range >= 200.0 and max_range <= 800.0, "WeaponData: max_range must be 200-800, got: %f" % max_range)
		assert(scatter_degrees >= 0.0 and scatter_degrees <= 15.0, "WeaponData: scatter_degrees must be 0-15, got: %f" % scatter_degrees)
		assert(max_ammo >= 5 and max_ammo <= 30, "WeaponData: max_ammo must be 5-30, got: %d" % max_ammo)


func get_display_name() -> String:
	if weapon_name.is_empty():
		return "未命名武器"
	return weapon_name
