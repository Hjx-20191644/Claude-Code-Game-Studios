extends Resource
class_name RunStats

## Per-run statistics snapshot. Owned and mutated by ScoreManager.
## get_stats() returns a frozen copy for display/settlement screens.

@export var score: int = 0
@export var wave_reached: int = 0
@export var total_kills: int = 0
@export var melee_kills: int = 0
@export var ranged_kills: int = 0
@export var total_damage_dealt: float = 0.0
@export var total_damage_taken: float = 0.0
@export var survival_time: float = 0.0
@export var upgrades_acquired: int = 0


func duplicate_snapshot() -> RunStats:
	var snap := RunStats.new()
	snap.score = score
	snap.wave_reached = wave_reached
	snap.total_kills = total_kills
	snap.melee_kills = melee_kills
	snap.ranged_kills = ranged_kills
	snap.total_damage_dealt = total_damage_dealt
	snap.total_damage_taken = total_damage_taken
	snap.survival_time = survival_time
	snap.upgrades_acquired = upgrades_acquired
	return snap
