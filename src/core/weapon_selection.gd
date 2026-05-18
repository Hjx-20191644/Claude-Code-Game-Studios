extends RefCounted
class_name WeaponSelection

## Static storage for player's weapon picks before a run.
## CombatSystem reads from here instead of hardcoded defaults.

static var left_weapon_id: String = "dual_daggers"
static var right_weapon_id: String = "shotgun"

## Weapons always available regardless of unlocks.
static var FREE_WEAPONS: PackedStringArray = [
	"dual_daggers", "great_sword", "pistol", "shotgun",
	"fists", "spear", "warhammer", "smg", "grenade",
]

## Map of weapon unlock IDs to their file names.
static var WEAPON_UNLOCKS: Dictionary = {
	"unlock_longsword": "longsword",
	"unlock_crossbow": "crossbow",
	"unlock_rifle": "rifle",
}


static func get_available_weapons() -> Array[WeaponData]:
	var result: Array[WeaponData] = []
	var dir := DirAccess.open("res://assets/data/weapons")
	if not dir:
		return result
	dir.list_dir_begin()
	var file_name := dir.get_next()
	while file_name != "":
		if file_name.ends_with(".tres"):
			var base_name := file_name.trim_suffix(".tres")
			if _is_weapon_available(base_name):
				var w := load("res://assets/data/weapons/" + file_name) as WeaponData
				if w:
					result.append(w)
		file_name = dir.get_next()
	dir.list_dir_end()
	result.sort_custom(func(a, b): return a.weapon_name < b.weapon_name)
	return result


static func _is_weapon_available(base_name: String) -> bool:
	if base_name in FREE_WEAPONS:
		return true
	for unlock_id in WEAPON_UNLOCKS:
		if WEAPON_UNLOCKS[unlock_id] == base_name:
			return MetaProgress.is_unlocked(unlock_id)
	return true  # unknown weapons default to available

