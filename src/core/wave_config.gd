extends Resource
class_name WaveConfig

## Single wave configuration: what enemies spawn and when.
## Used as sub-resources inside WaveData.waves array.

@export var wave_number: int = 1
@export var melee_count: int = 0
@export var ranged_count: int = 0
@export var spawn_delay: float = 0.5
@export var has_upgrade_window: bool = false
