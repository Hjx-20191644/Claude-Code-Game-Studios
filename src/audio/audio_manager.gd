extends Node
class_name AudioManager

## Procedural audio system: pooling, layered synthesis, and random variation.
## All sounds are synthesized at runtime — no external audio files needed.
##
## Architecture:
##   _gen_*() → pure generators returning PackedByteArray
##   _emit()  → pooled playback with volume variation
##   _play_layered() → mix multiple generators for rich sounds
##   _play_*() → convenience wrappers (backward compatible)

const RATE := 44100.0
const TAU := 6.283185
const POOL_SIZE := 16
const VOL_VAR_DB := 1.5   ## ±1.5 dB random volume variation per play

var _pool: Array[AudioStreamPlayer] = []
var _pool_idx: int = 0


# ── Initialization ────────────────────────────────────────────────────

func _ready() -> void:
	for _i in POOL_SIZE:
		var p := AudioStreamPlayer.new()
		p.bus = "SFX"
		add_child(p)
		_pool.append(p)

	EventBus.damage_dealt.connect(_on_damage_dealt)
	EventBus.damage_taken.connect(_on_damage_taken)
	EventBus.enemy_killed.connect(_on_enemy_killed)
	EventBus.wave_started.connect(_on_wave_started)
	EventBus.upgrade_window_requested.connect(_on_upgrade_window)
	EventBus.dodge_started.connect(_on_dodge)
	EventBus.shard_collected.connect(_on_shard_collected)
	EventBus.item_unlocked.connect(_on_item_unlocked)
	EventBus.item_purchase_failed.connect(_on_item_purchase_failed)
	EventBus.run_completed.connect(_on_run_completed)
	EventBus.boss_spawned.connect(_on_boss_spawned)
	EventBus.boss_phase_changed.connect(_on_boss_phase_changed)
	EventBus.boss_killed.connect(_on_boss_killed)
	EventBus.player_died.connect(_on_player_died)
	EventBus.wave_completed.connect(_on_wave_completed)
	EventBus.upgrade_applied.connect(_on_upgrade_applied)
	EventBus.vfx_requested.connect(_on_vfx_requested)
	EventBus.upgrade_selected.connect(_on_upgrade_selected)
	EventBus.boss_damaged.connect(_on_boss_damaged)
	EventBus.weapon_changed.connect(_on_weapon_changed)


# ── Pool ───────────────────────────────────────────────────────────────

func _acquire_player() -> AudioStreamPlayer:
	var p := _pool[_pool_idx]
	_pool_idx = (_pool_idx + 1) % POOL_SIZE
	return p


# ── Emit ───────────────────────────────────────────────────────────────

func _emit(data: PackedByteArray) -> void:
	if data.size() == 0:
		return

	# Volume variation: scale samples by random dB adjustment
	var vol_scale := db_to_linear(randf_range(-VOL_VAR_DB, VOL_VAR_DB))
	if vol_scale != 1.0:
		data = _scale_amplitude(data, vol_scale)

	var player := _acquire_player()
	var wav := AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = int(RATE)
	wav.stereo = false
	wav.data = data
	player.stream = wav
	player.volume_db = SettingsManager.effective_sfx_db(
		SettingsManager.get_master_volume(),
		SettingsManager.get_sfx_volume()
	)
	player.play()


func _scale_amplitude(data: PackedByteArray, scale: float) -> PackedByteArray:
	var out := PackedByteArray()
	out.resize(data.size())
	for i in range(0, data.size(), 2):
		var v := data.decode_s16(i)
		out.encode_s16(i, clampi(int(float(v) * scale), -32768, 32767))
	return out


# ── Mix ────────────────────────────────────────────────────────────────

func _mix(layers: Array[PackedByteArray]) -> PackedByteArray:
	var max_len := 0
	for data in layers:
		if data.size() > max_len:
			max_len = data.size()
	if max_len == 0:
		return PackedByteArray()

	var out := PackedByteArray()
	out.resize(max_len)
	for i in range(0, max_len, 2):
		out.encode_s16(i, 0)

	for data in layers:
		var n := data.size()
		for i in range(0, n, 2):
			var s := out.decode_s16(i) + data.decode_s16(i)
			out.encode_s16(i, clampi(s, -32768, 32767))

	return out


# ── Layered playback ───────────────────────────────────────────────────

## Play multiple generators mixed together. Each entry is [name, params_array].
func _play_layered(layers: Array) -> void:
	var data_array: Array[PackedByteArray] = []
	for entry in layers:
		var gen_name := "_gen_" + entry[0]
		var params: Array = entry[1]
		var data: PackedByteArray = callv(gen_name, params)
		if data.size() > 0:
			data_array.append(data)
	if data_array.size() > 0:
		_emit(_mix(data_array))


# ── Pure generators (return PackedByteArray) ──────────────────────────

func _gen_tone(freq: float, duration: float, shape: String, amp: float = 0.25) -> PackedByteArray:
	var count := int(RATE * duration)
	var data := PackedByteArray()
	data.resize(count * 2)
	for i in count:
		var t := float(i) / RATE
		var env := 1.0 - (float(i) / float(count))
		var v: float
		if shape == "square":
			v = 1.0 if sin(TAU * freq * t) >= 0.0 else -1.0
		else:
			v = sin(TAU * freq * t)
		v *= amp * env * env
		data.encode_s16(i * 2, int(clampf(v * 32767.0, -32768, 32767)))
	return data


func _gen_sweep(start_freq: float, end_freq: float, duration: float, amp: float = 0.25) -> PackedByteArray:
	var count := int(RATE * duration)
	var data := PackedByteArray()
	data.resize(count * 2)
	for i in count:
		var t := float(i) / RATE
		var ratio := float(i) / float(count)
		var freq := start_freq + (end_freq - start_freq) * ratio
		var env := sin(TAU * 0.5 * ratio)
		var v := sin(TAU * freq * t) * amp * env
		data.encode_s16(i * 2, int(clampf(v * 32767.0, -32768, 32767)))
	return data


func _gen_two_tone(f1: float, f2: float, gap: float, tail: float, amp: float = 0.25) -> PackedByteArray:
	var total := gap + tail
	var count := int(RATE * total)
	var data := PackedByteArray()
	data.resize(count * 2)
	for i in count:
		var t := float(i) / RATE
		var freq := f1 if t < gap else f2
		var env := 1.0 - (float(i) / float(count))
		var v := sin(TAU * freq * t) * amp * env * env
		data.encode_s16(i * 2, int(clampf(v * 32767.0, -32768, 32767)))
	return data


func _gen_noise(duration: float, amp: float = 0.15) -> PackedByteArray:
	var count := int(RATE * duration)
	var data := PackedByteArray()
	data.resize(count * 2)
	for i in count:
		var env := 1.0 - (float(i) / float(count))
		var v := (randf() * 2.0 - 1.0) * amp * env * env
		data.encode_s16(i * 2, int(clampf(v * 32767.0, -32768, 32767)))
	return data


func _gen_ping(freq: float, duration: float, amp: float = 0.2) -> PackedByteArray:
	var count := int(RATE * duration)
	var data := PackedByteArray()
	data.resize(count * 2)
	for i in count:
		var ratio := float(i) / float(count)
		var env := 1.0 - ratio
		var v := sin(TAU * freq * ratio) * amp * env * env
		data.encode_s16(i * 2, int(clampf(v * 32767.0, -32768, 32767)))
	return data


func _gen_burst(duration: float, amp: float = 0.35) -> PackedByteArray:
	var count := int(RATE * duration)
	var data := PackedByteArray()
	data.resize(count * 2)
	for i in count:
		var ratio := float(i) / float(count)
		var env := 1.0 - ratio
		var v := (randf() * 2.0 - 1.0) * amp * env * env
		data.encode_s16(i * 2, int(clampf(v * 32767.0, -32768, 32767)))
	return data


func _gen_buzz(duration: float, amp: float = 0.2) -> PackedByteArray:
	var count := int(RATE * duration)
	var data := PackedByteArray()
	data.resize(count * 2)
	for i in count:
		var t := float(i) / RATE
		var env := 1.0 - (float(i) / float(count))
		var v := sin(TAU * 80.0 * t) * amp * env * env
		data.encode_s16(i * 2, int(clampf(v * 32767.0, -32768, 32767)))
	return data


func _gen_whoosh(duration: float, amp: float = 0.2) -> PackedByteArray:
	var count := int(RATE * duration)
	var data := PackedByteArray()
	data.resize(count * 2)
	for i in count:
		var ratio := float(i) / float(count)
		var freq := 800.0 + (200.0 - 800.0) * ratio
		var env := 1.0 - ratio
		var v := (randf() * 2.0 - 1.0) * 0.6 * amp * env * env
		v += sin(TAU * freq * ratio) * 0.4 * amp * env
		data.encode_s16(i * 2, int(clampf(v * 32767.0, -32768, 32767)))
	return data


func _gen_boom(duration: float, amp: float = 0.4) -> PackedByteArray:
	var count := int(RATE * duration)
	var data := PackedByteArray()
	data.resize(count * 2)
	for i in count:
		var ratio := float(i) / float(count)
		var env := 1.0 - ratio
		var v := sin(TAU * 50.0 * ratio) * 0.55 * amp * env * env
		v += (randf() * 2.0 - 1.0) * 0.45 * amp * env * env * env
		data.encode_s16(i * 2, int(clampf(v * 32767.0, -32768, 32767)))
	return data


func _gen_click(duration: float = 0.02, amp: float = 0.15) -> PackedByteArray:
	var count := int(RATE * duration)
	var data := PackedByteArray()
	data.resize(count * 2)
	for i in count:
		var ratio := float(i) / float(count)
		var env := 1.0 - ratio
		var v := sin(TAU * 1200.0 * ratio) * amp * env * env * env
		data.encode_s16(i * 2, int(clampf(v * 32767.0, -32768, 32767)))
	return data


# ── Convenience wrappers (backward compatible) ─────────────────────────

func _play_tone(freq: float, duration: float, shape: String) -> void:
	_emit(_gen_tone(freq, duration, shape))


func _play_sweep(start_freq: float, end_freq: float, duration: float) -> void:
	_emit(_gen_sweep(start_freq, end_freq, duration))


func _play_two_tone(f1: float, f2: float, gap: float, tail: float) -> void:
	_emit(_gen_two_tone(f1, f2, gap, tail))


func _play_noise(duration: float) -> void:
	_emit(_gen_noise(duration))


func _play_ping(freq: float, duration: float) -> void:
	_emit(_gen_ping(freq, duration))


func _play_burst(duration: float) -> void:
	_emit(_gen_burst(duration))


func _play_buzz(duration: float) -> void:
	_emit(_gen_buzz(duration))


func _play_whoosh(duration: float) -> void:
	_emit(_gen_whoosh(duration))


func _play_boom(duration: float) -> void:
	_emit(_gen_boom(duration))


func _play_click() -> void:
	_emit(_gen_click())


# ── Signal handlers ────────────────────────────────────────────────────

func _on_damage_dealt(_amount: float, _pos: Vector2, attack_type: String) -> void:
	if attack_type == "melee":
		_play_layered([
			["tone", [120.0, 0.06, "square", 0.30]],
			["noise", [0.04, 0.12]],
		])
	else:
		_play_layered([
			["tone", [600.0, 0.04, "sine", 0.20]],
			["click", [0.02, 0.10]],
		])


func _on_damage_taken(_amount: float, _pos: Vector2) -> void:
	_play_layered([
		["noise", [0.08, 0.18]],
		["tone", [80.0, 0.10, "square", 0.12]],
	])


func _on_enemy_killed(kill_type: String, _pos: Vector2, _color: Color, _is_elite: bool = false) -> void:
	match kill_type:
		"charger":
			_play_layered([
				["sweep", [200.0, 50.0, 0.18, 0.25]],
				["noise", [0.08, 0.10]],
			])
		"exploder":
			_play_layered([
				["burst", [0.25, 0.40]],
				["boom", [0.15, 0.30]],
			])
		"tank":
			_play_layered([
				["sweep", [80.0, 30.0, 0.30, 0.28]],
				["buzz", [0.12, 0.12]],
			])
		_:
			_play_layered([
				["sweep", [400.0, 100.0, 0.15, 0.20]],
				["ping", [800.0, 0.06, 0.12]],
			])


func _on_wave_started(wave_number: int) -> void:
	if wave_number <= 1:
		return
	_play_layered([
		["sweep", [300.0, 600.0, 0.20, 0.22]],
		["tone", [450.0, 0.15, "sine", 0.10]],
	])


func _on_wave_completed(_wave_number: int) -> void:
	_play_layered([
		["two_tone", [400.0, 600.0, 0.06, 0.10, 0.15]],
		["ping", [800.0, 0.05, 0.08]],
	])


func _on_upgrade_window() -> void:
	_play_layered([
		["two_tone", [500.0, 800.0, 0.06, 0.08, 0.20]],
		["ping", [1200.0, 0.04, 0.08]],
	])


func _on_upgrade_selected(_upgrade: Dictionary) -> void:
	_play_layered([
		["two_tone", [600.0, 1000.0, 0.05, 0.07, 0.18]],
		["ping", [1500.0, 0.03, 0.06]],
	])


func _on_upgrade_applied(_upgrade: Dictionary) -> void:
	_play_layered([
		["two_tone", [500.0, 800.0, 0.05, 0.08, 0.15]],
		["ping", [1000.0, 0.04, 0.06]],
	])


func _on_dodge() -> void:
	_play_layered([
		["whoosh", [0.08, 0.20]],
		["tone", [300.0, 0.06, "sine", 0.08]],
	])


func _on_shard_collected(_amount: int, _total: int) -> void:
	_play_layered([
		["ping", [1200.0, 0.04, 0.18]],
		["ping", [1800.0, 0.03, 0.08]],
	])


func _on_item_unlocked(_unlock_id: String) -> void:
	_play_layered([
		["two_tone", [600.0, 1000.0, 0.07, 0.10, 0.20]],
		["ping", [1500.0, 0.04, 0.08]],
	])


func _on_item_purchase_failed(_unlock_id: String, _reason: String) -> void:
	_play_layered([
		["buzz", [0.08, 0.18]],
		["tone", [100.0, 0.10, "square", 0.10]],
	])


func _on_run_completed(_stats: RunStats, _shards_earned: int) -> void:
	_play_layered([
		["two_tone", [400.0, 200.0, 0.15, 0.20, 0.22]],
		["sweep", [600.0, 100.0, 0.30, 0.15]],
	])


func _on_boss_spawned(_boss_name: String, _max_hp: int) -> void:
	_play_layered([
		["sweep", [30.0, 80.0, 0.50, 0.35]],
		["boom", [0.20, 0.25]],
	])


func _on_boss_phase_changed(_phase: int) -> void:
	_play_layered([
		["sweep", [100.0, 300.0, 0.30, 0.25]],
		["buzz", [0.10, 0.10]],
	])


func _on_boss_damaged(_current_hp: int, _max_hp: int) -> void:
	_play_layered([
		["tone", [90.0, 0.08, "square", 0.20]],
		["noise", [0.03, 0.08]],
	])


func _on_boss_killed(_boss_name: String) -> void:
	_play_layered([
		["burst", [0.50, 0.50]],
		["sweep", [300.0, 30.0, 0.60, 0.40]],
		["boom", [0.30, 0.35]],
	])


func _on_player_died() -> void:
	_play_layered([
		["sweep", [600.0, 50.0, 0.40, 0.30]],
		["noise", [0.15, 0.15]],
		["tone", [80.0, 0.50, "square", 0.15]],
	])


func _on_vfx_requested(effect_name: String, _position: Vector2) -> void:
	if effect_name == "explosion":
		_play_layered([
			["boom", [0.30, 0.40]],
			["burst", [0.20, 0.25]],
		])


func _on_weapon_changed(_weapon_data: Dictionary) -> void:
	_play_layered([
		["whoosh", [0.06, 0.15]],
		["click", [0.02, 0.10]],
	])
