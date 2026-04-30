extends RefCounted
class_name WeaponSelection

## Static storage for player's weapon picks before a run.
## CombatSystem reads from here instead of hardcoded defaults.

static var left_weapon_id: String = "dual_daggers"
static var right_weapon_id: String = "shotgun"


static func get_available_weapons() -> Array[WeaponData]:
	var result: Array[WeaponData] = []
	var dir := DirAccess.open("res://assets/data/weapons")
	if not dir:
		return result
	dir.list_dir_begin()
	var file_name := dir.get_next()
	while file_name != "":
		if file_name.ends_with(".tres"):
			var w := load("res://assets/data/weapons/" + file_name) as WeaponData
			if w:
				result.append(w)
		file_name = dir.get_next()
	dir.list_dir_end()
	result.sort_custom(func(a, b): return a.weapon_name < b.weapon_name)
	return result
