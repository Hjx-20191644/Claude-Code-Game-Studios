extends Node
class_name UpgradePool

## Manages the upgrade pool: draws random upgrades, tracks acquired stacks,
## emits upgrade_acquired on EventBus for downstream systems.

@export var draw_count: int = 3

var _all_upgrades: Array[UpgradeData] = []
var _acquired: Dictionary = {}  # upgrade_id -> current_stacks


func _ready() -> void:
	_load_all_upgrades()


func _load_all_upgrades() -> void:
	var dir := DirAccess.open("res://assets/data/upgrades")
	if not dir:
		push_warning("UpgradePool: upgrades directory not found")
		return

	dir.list_dir_begin()
	var file_name := dir.get_next()
	while file_name != "":
		if file_name.ends_with(".tres"):
			var upgrade := load("res://assets/data/upgrades/" + file_name) as UpgradeData
			if upgrade:
				upgrade.validate()
				_all_upgrades.append(upgrade)
		file_name = dir.get_next()
	dir.list_dir_end()

	_all_upgrades.sort_custom(func(a, b): return a.id < b.id)


## Draw N upgrades from the available pool, weighted by rarity.
func draw_upgrades(count: int = -1) -> Array[UpgradeData]:
	if count < 0:
		count = draw_count

	var available := _get_available()
	if available.is_empty():
		return []

	var result: Array[UpgradeData] = []
	var pool := available.duplicate()

	for _i in mini(count, pool.size()):
		var chosen := _weighted_random(pool)
		if chosen:
			result.append(chosen)
			pool.erase(chosen)

	return result


## Acquire an upgrade. Returns the new stack count.
func acquire_upgrade(upgrade_id: String) -> int:
	var current: int = _acquired.get(upgrade_id, 0)
	var upgrade := _find_upgrade(upgrade_id)
	if not upgrade:
		push_warning("UpgradePool: unknown upgrade id: %s" % upgrade_id)
		return current

	current += 1
	_acquired[upgrade_id] = current
	EventBus.upgrade_applied.emit({
		"upgrade_id": upgrade_id,
		"display_name": upgrade.display_name,
		"target_stat": upgrade.target_stat,
		"modifier_type": upgrade.modifier_type,
		"value": upgrade.value,
		"current_stacks": current,
	})
	return current


func get_current_stacks(upgrade_id: String) -> int:
	return _acquired.get(upgrade_id, 0)


func get_all_acquired() -> Dictionary:
	return _acquired.duplicate()


func reset() -> void:
	_acquired.clear()


# --- Private ---

func _get_available() -> Array[UpgradeData]:
	var available: Array[UpgradeData] = []
	for upgrade in _all_upgrades:
		var stacks: int = _acquired.get(upgrade.id, 0)
		if upgrade.max_stacks == -1 or stacks < upgrade.max_stacks:
			available.append(upgrade)
	return available


func _weighted_random(pool: Array[UpgradeData]) -> UpgradeData:
	var total_weight := 0
	for upgrade in pool:
		total_weight += upgrade.get_rarity_weight()

	if total_weight <= 0:
		return pool[0] if pool.size() > 0 else null

	var roll := randi() % total_weight
	var cumulative := 0
	for upgrade in pool:
		cumulative += upgrade.get_rarity_weight()
		if roll < cumulative:
			return upgrade

	return pool.back()


func _find_upgrade(upgrade_id: String) -> UpgradeData:
	for upgrade in _all_upgrades:
		if upgrade.id == upgrade_id:
			return upgrade
	return null
