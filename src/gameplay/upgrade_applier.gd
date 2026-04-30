extends Node
class_name UpgradeApplier

## Applies upgrade effects to gameplay stats.
## Listens to upgrade_applied, accumulates modifiers, exposes query API.
## Other systems call get_multiplier() / get_absolute() to read their stats.

var _modifiers: Dictionary = {}  # stat_name -> accumulated value


func _ready() -> void:
	EventBus.upgrade_applied.connect(_on_upgrade_applied)
	EventBus.wave_started.connect(_on_wave_started)


func _on_wave_started(wave_number: int) -> void:
	if wave_number == 1:
		_modifiers.clear()


func _on_upgrade_applied(data: Dictionary) -> void:
	var stat: String = data["target_stat"]
	var value: float = data["value"]
	var current: float = _modifiers.get(stat, 0.0)
	_modifiers[stat] = current + value


## Get accumulated absolute modifier (e.g., flat speed, cooldown reduction).
func get_absolute(stat_name: String) -> float:
	return _modifiers.get(stat_name, 0.0)


## Get multiplier from accumulated percent modifiers: 1.0 + sum of all ADD_PERCENT values.
func get_multiplier(stat_name: String) -> float:
	return 1.0 + _modifiers.get(stat_name, 0.0)


## Get raw accumulated value for a stat. Useful for additive chances (e.g., crit_chance).
func get_raw(stat_name: String) -> float:
	return _modifiers.get(stat_name, 0.0)


func reset() -> void:
	_modifiers.clear()
