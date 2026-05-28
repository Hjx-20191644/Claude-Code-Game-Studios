extends Resource
class_name WaveConfig

## Single wave configuration: what enemies spawn and when.
## Used as sub-resources inside WaveData.waves array.

@export var wave_number: int = 1
@export var melee_count: int = 0
@export var ranged_count: int = 0
@export var charger_count: int = 0
@export var exploder_count: int = 0
@export var tank_count: int = 0
@export var boss_count: int = 0
@export var egg_count: int = 0
@export var spawner_count: int = 0
@export var buffer_count: int = 0
@export var reward_count: int = 0
@export var spawn_delay: float = 0.5
@export var has_upgrade_window: bool = false
