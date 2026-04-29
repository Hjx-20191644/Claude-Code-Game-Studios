extends Resource
class_name UpgradeData

## Upgrade data resource — defines one upgrade option.
## MVP uses a single effect per upgrade (flat fields); get_effects()
## wraps it in array form for forward compatibility.

enum Rarity { COMMON, UNCOMMON, RARE }
enum ModifierType { ADD_ABSOLUTE, ADD_PERCENT }

const RARITY_WEIGHTS := {
	Rarity.COMMON: 60,
	Rarity.UNCOMMON: 30,
	Rarity.RARE: 10,
}

@export var id: String = ""
@export var display_name: String = ""
@export var description: String = ""
@export var rarity: Rarity = Rarity.COMMON
@export var tags: Array[String] = []
@export var max_stacks: int = 5

@export var target_stat: String = ""
@export var modifier_type: ModifierType = ModifierType.ADD_PERCENT
@export var value: float = 0.0

@export var icon: Texture2D


func get_effects() -> Array[Dictionary]:
	return [{
		"target_stat": target_stat,
		"modifier_type": modifier_type,
		"value": value,
	}]


func get_rarity_weight() -> int:
	return RARITY_WEIGHTS.get(rarity, 60)


func validate() -> void:
	assert(not id.is_empty(), "UpgradeData: id must not be empty")
	assert(not display_name.is_empty(), "UpgradeData: display_name must not be empty")
	assert(rarity in RARITY_WEIGHTS, "UpgradeData: invalid rarity value")
	assert(not target_stat.is_empty(), "UpgradeData: target_stat must not be empty")
	assert(max_stacks >= 1 or max_stacks == -1, "UpgradeData: max_stacks must be >= 1 or -1")
