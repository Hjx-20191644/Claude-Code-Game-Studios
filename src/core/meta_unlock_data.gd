extends Resource
class_name MetaUnlockData

@export var id: String = ""
@export var display_name: String = ""
@export var description: String = ""
@export var cost: int = 0
@export var prerequisites: Array[String] = []
@export var unlock_type: String = ""  # "weapon", "stat_bonus", "starting_bonus"
@export var target_stat: String = ""
@export var value: float = 0.0
