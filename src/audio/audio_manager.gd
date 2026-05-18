extends Node
class_name AudioManager

## Procedural audio: generates short synthesized sound effects via AudioStreamWAV.
## No external audio files needed — all sounds are generated from PCM data.

const RATE := 44100.0
const TAU := 6.283185


func _ready() -> void:
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


func _on_damage_dealt(_amount: float, _pos: Vector2, attack_type: String) -> void:
	if attack_type == "melee":
		_play_tone(150.0, 0.06, "square")
	else:
		_play_tone(600.0, 0.04, "sine")


func _on_damage_taken(_amount: float, _pos: Vector2) -> void:
	_play_noise(0.08)


func _on_enemy_killed(kill_type: String, _pos: Vector2, _color: Color, _is_elite: bool = false) -> void:
	match kill_type:
		"charger":
			_play_sweep(200.0, 50.0, 0.18)
		"exploder":
			_play_burst(0.2)
		"tank":
			_play_sweep(80.0, 30.0, 0.3)
		_:
			_play_sweep(400.0, 100.0, 0.15)


func _on_wave_started(wave_number: int) -> void:
	if wave_number <= 1:
		return
	_play_sweep(300.0, 600.0, 0.2)


func _on_upgrade_window() -> void:
	_play_two_tone(500.0, 800.0, 0.06, 0.08)


func _on_dodge() -> void:
	_play_sweep(200.0, 400.0, 0.06)


func _on_shard_collected(_amount: int, _total: int) -> void:
	_play_ping(1200.0, 0.04)


func _on_item_unlocked(_unlock_id: String) -> void:
	_play_two_tone(600.0, 1000.0, 0.07, 0.1)


func _on_item_purchase_failed(_unlock_id: String, _reason: String) -> void:
	_play_buzz(0.08)


func _on_run_completed(_stats: RunStats, _shards_earned: int) -> void:
	_play_two_tone(400.0, 200.0, 0.15, 0.2)


# --- Generators ---

func _play_tone(freq: float, duration: float, shape: String) -> void:
	var count := int(RATE * duration)
	var data := PackedByteArray()
	data.resize(count * 2)
	for i in count:
		var t := float(i) / RATE
		var env := 1.0 - (float(i) / float(count))
		var v: float
		if shape == "square":
			v = -0.3 if sin(TAU * freq * t) >= 0.0 else 0.3
		else:
			v = sin(TAU * freq * t) * 0.3
		v *= env * env
		var sample := int(clampf(v * 32767.0, -32768, 32767))
		data.encode_s16(i * 2, sample)
	_emit(data, count)


func _play_sweep(start_freq: float, end_freq: float, duration: float) -> void:
	var count := int(RATE * duration)
	var data := PackedByteArray()
	data.resize(count * 2)
	for i in count:
		var t := float(i) / RATE
		var ratio := float(i) / float(count)
		var freq := start_freq + (end_freq - start_freq) * ratio
		var env := sin(TAU * 0.5 * ratio)
		var v := sin(TAU * freq * t) * 0.25 * env
		var sample := int(clampf(v * 32767.0, -32768, 32767))
		data.encode_s16(i * 2, sample)
	_emit(data, count)


func _play_two_tone(f1: float, f2: float, gap: float, tail: float) -> void:
	var total := gap + tail
	var count := int(RATE * total)
	var data := PackedByteArray()
	data.resize(count * 2)
	for i in count:
		var t := float(i) / RATE
		var freq := f1 if t < gap else f2
		var env := 1.0 - (float(i) / float(count))
		var v := sin(TAU * freq * t) * 0.25 * env * env
		var sample := int(clampf(v * 32767.0, -32768, 32767))
		data.encode_s16(i * 2, sample)
	_emit(data, count)


func _play_noise(duration: float) -> void:
	var count := int(RATE * duration)
	var data := PackedByteArray()
	data.resize(count * 2)
	for i in count:
		var env := 1.0 - (float(i) / float(count))
		var v := (randf() * 2.0 - 1.0) * 0.15 * env * env
		var sample := int(clampf(v * 32767.0, -32768, 32767))
		data.encode_s16(i * 2, sample)
	_emit(data, count)


func _play_ping(freq: float, duration: float) -> void:
	var count := int(RATE * duration)
	var data := PackedByteArray()
	data.resize(count * 2)
	for i in count:
		var ratio := float(i) / float(count)
		var env := 1.0 - ratio
		var v := sin(TAU * freq * ratio) * 0.2 * env * env
		var sample := int(clampf(v * 32767.0, -32768, 32767))
		data.encode_s16(i * 2, sample)
	_emit(data, count)


func _play_burst(duration: float) -> void:
	var count := int(RATE * duration)
	var data := PackedByteArray()
	data.resize(count * 2)
	for i in count:
		var ratio := float(i) / float(count)
		var env := 1.0 - ratio
		var v := (randf() * 2.0 - 1.0) * 0.35 * env * env
		var sample := int(clampf(v * 32767.0, -32768, 32767))
		data.encode_s16(i * 2, sample)
	_emit(data, count)


func _play_buzz(duration: float) -> void:
	var count := int(RATE * duration)
	var data := PackedByteArray()
	data.resize(count * 2)
	for i in count:
		var t := float(i) / RATE
		var env := 1.0 - (float(i) / float(count))
		var v := sin(TAU * 80.0 * t) * 0.2 * env * env
		var sample := int(clampf(v * 32767.0, -32768, 32767))
		data.encode_s16(i * 2, sample)
	_emit(data, count)


func _emit(data: PackedByteArray, frame_count: int) -> void:
	var wav := AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = int(RATE)
	wav.stereo = false
	wav.data = data

	var player := AudioStreamPlayer.new()
	player.stream = wav
	player.volume_db = SettingsManager.effective_sfx_db(
		SettingsManager.get_master_volume(),
		SettingsManager.get_sfx_volume()
	)
	add_child(player)
	player.play()
	player.finished.connect(player.queue_free)
