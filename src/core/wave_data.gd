extends Resource
class_name WaveData

## Master wave progression data: tuning knobs + wave sequence.
## If .tres data fails to load typed WaveConfig, use create_default() fallback.

@export var post_wave_delay: float = 2.0
@export var upgrade_interval: int = 2
@export var upgrade_timeout: float = 30.0
@export var infinite_melee_increment: int = 2
@export var infinite_ranged_increment: int = 1
@export var waves: Array = []  # Array[WaveConfig] at runtime; may load as Resource


## Build MVP 5-wave config programmatically. Used as fallback when .tres
## sub-resources fail to deserialize as typed WaveConfig.
static func create_default() -> WaveData:
	var data := WaveData.new()
	data.post_wave_delay = 2.0
	data.upgrade_interval = 2
	data.upgrade_timeout = 30.0
	data.infinite_melee_increment = 2
	data.infinite_ranged_increment = 1

	data.waves = [
		_make_wave(1, 3, 0, 0.5, false),
		_make_wave(2, 4, 1, 0.5, false),
		_make_wave(3, 4, 2, 0.4, true),
		_make_wave(4, 5, 3, 0.4, false),
		_make_wave(5, 6, 4, 0.3, true),
	]
	return data


static func _make_wave(num: int, melee: int, ranged: int, delay: float, upgrade: bool) -> WaveConfig:
	var w := WaveConfig.new()
	w.wave_number = num
	w.melee_count = melee
	w.ranged_count = ranged
	w.spawn_delay = delay
	w.has_upgrade_window = upgrade
	return w


func validate() -> void:
	assert(waves.size() >= 1, "WaveData: at least one wave config required")
	assert(post_wave_delay >= 0.0, "WaveData: post_wave_delay must be >= 0")
	assert(upgrade_interval >= 1, "WaveData: upgrade_interval must be >= 1")
	assert(upgrade_timeout >= 1.0, "WaveData: upgrade_timeout must be >= 1")
	for wave in waves:
		var w := wave as WaveConfig
		if w:
			assert(w.wave_number >= 1, "WaveData: wave_number must be >= 1")
			assert(w.melee_count >= 0, "WaveData: melee_count must be >= 0")
			assert(w.ranged_count >= 0, "WaveData: ranged_count must be >= 0")
