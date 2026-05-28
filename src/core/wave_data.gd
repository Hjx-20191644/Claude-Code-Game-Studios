extends Resource
class_name WaveData

## Master wave progression data: tuning knobs + wave sequence.
## If .tres data fails to load typed WaveConfig, use create_default() fallback.

@export var post_wave_delay: float = 2.0
@export var upgrade_interval: int = 2
@export var upgrade_timeout: float = 30.0
@export var infinite_melee_increment: int = 3
@export var infinite_ranged_increment: int = 2
@export var waves: Array = []  # Array[WaveConfig] at runtime; may load as Resource


## Build default 20-wave config with Brotato-inspired wave rhythm:
## gradual introduction → gate checks → relief → escalation → final boss.
## Used as fallback when .tres sub-resources fail to deserialize.
static func create_default() -> WaveData:
	var data := WaveData.new()
	data.post_wave_delay = 2.0
	data.upgrade_interval = 2
	data.upgrade_timeout = 30.0
	data.infinite_melee_increment = 3
	data.infinite_ranged_increment = 2

	data.waves = [
		# === Phase 1: Introduction (waves 1-6) ===
		_make_wave(1, 3, 0, 0, 0, 0, 0.5, false),
		_make_wave(2, 4, 0, 0, 0, 0, 0.5, true),
		_make_wave(3, 5, 0, 0, 0, 0, 0.45, false),
		_make_wave(4, 4, 2, 0, 0, 0, 0.45, true),
		_make_wave(5, 5, 1, 1, 0, 0, 0.4, true),
		_make_wave(6, 5, 3, 2, 0, 0, 0.4, true),

		# === Phase 2: New mechanics (waves 7-8) ===
		_make_wave(7, 4, 2, 0, 0, 0, 0.4, false, 0, 2),
		_make_wave(8, 3, 0, 2, 0, 1, 0.35, true),

		# === Phase 3: Gate 1 — AoE clear check (wave 9) ===
		_make_wave(9, 10, 0, 0, 0, 0, 0.2, false),

		# === Phase 4: Recovery + Boss (wave 10) ===
		_make_wave(10, 5, 2, 1, 0, 1, 0.35, true, 1),

		# === Phase 5: DPS gate — high-HP enemies (waves 11-13) ===
		_make_wave(11, 3, 2, 0, 0, 0, 0.3, false),
		_make_wave(12, 3, 2, 1, 0, 0, 0.3, true),
		_make_wave(13, 2, 2, 0, 0, 0, 0.25, false),

		# === Phase 6: Relief + E-class intro (wave 14) ===
		_make_wave(14, 4, 0, 0, 0, 0, 0.4, true, 0, 0, 0, 1),

		# === Phase 7: Combined challenge (wave 15) ===
		_make_wave(15, 5, 3, 1, 0, 0, 0.3, false, 0, 0, 1),

		# === Phase 8: Final escalation (waves 16-19) ===
		_make_wave(16, 6, 3, 2, 0, 1, 0.25, true, 0, 0, 1),
		_make_wave(17, 5, 4, 2, 1, 1, 0.25, false, 0, 0, 1),
		_make_wave(18, 6, 4, 2, 0, 1, 0.2, true, 0, 1, 0, 1),
		_make_wave(19, 5, 3, 3, 1, 2, 0.2, false, 1, 0, 1),

		# === Phase 9: Final Boss (wave 20) ===
		_make_wave(20, 4, 2, 2, 0, 1, 0.2, true, 1, 0, 0, 0, 1),
	]
	return data


static func _make_wave(num: int, melee: int, ranged: int, charger: int, exploder: int, tank: int, delay: float, upgrade: bool, boss: int = 0, egg: int = 0, spawner: int = 0, buffer: int = 0, reward: int = 0) -> WaveConfig:
	var w := WaveConfig.new()
	w.wave_number = num
	w.melee_count = melee
	w.ranged_count = ranged
	w.charger_count = charger
	w.exploder_count = exploder
	w.tank_count = tank
	w.boss_count = boss
	w.egg_count = egg
	w.spawner_count = spawner
	w.buffer_count = buffer
	w.reward_count = reward
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
			assert(w.charger_count >= 0, "WaveData: charger_count must be >= 0")
			assert(w.exploder_count >= 0, "WaveData: exploder_count must be >= 0")
			assert(w.tank_count >= 0, "WaveData: tank_count must be >= 0")
			assert(w.boss_count >= 0, "WaveData: boss_count must be >= 0")
			assert(w.boss_count <= 1, "WaveData: boss_count must be 0 or 1")
