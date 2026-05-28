extends Node
class_name WaveManager

## Survival wave system: 60s per wave, continuous enemy spawning.
## Survive until the timer expires to clear the wave.

enum State { IDLE, WAVE_ACTIVE, WAVE_CLEARED, UPGRADE_WINDOW }

@export var wave_data_path: String = "res://assets/data/wave_config.tres"
@export var wave_duration: float = 60.0
@export var spawn_window: float = 52.0
@export var enemy_multiplier: float = 3.0

var _state: State = State.IDLE
var _current_wave: int = 0
var _wave_timer: float = 0.0
var _wave_start_ticks: int = 0

var _spawn_pool: Array = []
var _spawn_interval: float = 0.0
var _spawn_timer: float = 0.0
var _total_enemies_this_wave: int = 0
var _boss_killed_this_wave: bool = false

var _upgrade_timeout_timer: float = 0.0

var _wave_data: WaveData
var _spawn_manager: Node

const SPAWN_TYPES := ["melee", "ranged", "charger", "exploder", "tank", "boss", "egg", "spawner", "buffer", "reward"]


func _ready() -> void:
	_wave_data = load(wave_data_path) as WaveData
	assert(_wave_data, "WaveManager: failed to load wave data from %s" % wave_data_path)
	_fixup_wave_data()
	_wave_data.validate()

	_spawn_manager = _find_spawn_manager()
	if not _spawn_manager:
		push_warning("WaveManager: no spawn node found, spawn calls will be skipped")

	EventBus.enemy_killed.connect(_on_enemy_killed)
	EventBus.player_died.connect(_on_player_died)
	EventBus.boss_killed.connect(_on_boss_killed)


func _process(delta: float) -> void:
	if _state == State.WAVE_ACTIVE:
		_wave_timer -= delta
		EventBus.wave_timer_updated.emit(_wave_timer)
		_process_spawning(delta)
		if _wave_timer <= 0.0:
			_wave_timer = 0.0
			_on_wave_cleared()
	elif _state == State.UPGRADE_WINDOW:
		_upgrade_timeout_timer -= delta
		if _upgrade_timeout_timer <= 0.0:
			_schedule_next_wave()


func start_run() -> void:
	_current_wave = 0
	_state = State.IDLE
	_boss_killed_this_wave = false
	_advance_to_next_wave()


func upgrade_completed() -> void:
	if _state == State.UPGRADE_WINDOW:
		_schedule_next_wave()


func get_current_wave() -> int:
	return _current_wave


# --- State transitions ---

func _advance_to_next_wave() -> void:
	_state = State.IDLE
	_current_wave += 1
	_wave_timer = wave_duration
	_spawn_timer = 0.0
	_boss_killed_this_wave = false
	_wave_start_ticks = Time.get_ticks_msec()

	var config := _get_wave_config(_current_wave)
	_build_spawn_pool(config)

	_state = State.WAVE_ACTIVE
	_heal_player_to_full()
	EventBus.wave_started.emit(_current_wave)
	EventBus.wave_timer_updated.emit(_wave_timer)

	if config.boss_count > 0:
		await get_tree().create_timer(1.0).timeout
		if _spawn_manager:
			_spawn_manager.spawn_enemies("boss", config.boss_count, _current_wave)


func _on_wave_cleared() -> void:
	_state = State.WAVE_CLEARED
	EventBus.wave_completed.emit(_current_wave)

	if _should_show_upgrade():
		_state = State.UPGRADE_WINDOW
		_upgrade_timeout_timer = _wave_data.upgrade_timeout
		EventBus.upgrade_window_requested.emit()
	else:
		await _delay(_wave_data.post_wave_delay)
		if _state == State.WAVE_CLEARED:
			_advance_to_next_wave()


func _schedule_next_wave() -> void:
	_state = State.IDLE
	await _delay(_wave_data.post_wave_delay)
	if _state == State.IDLE:
		_advance_to_next_wave()


# --- Continuous spawning ---

func _build_spawn_pool(config: WaveConfig) -> void:
	_spawn_pool.clear()
	_total_enemies_this_wave = 0
	var mult := int(enemy_multiplier)

	for type in SPAWN_TYPES:
		var count: int = config.get(type + "_count") as int
		if count <= 0:
			continue
		count *= mult
		var data_id: String = _get_data_id(type)
		for _i in count:
			_spawn_pool.append({"type": type, "data_id": data_id})
		_total_enemies_this_wave += count

	if _total_enemies_this_wave > 0:
		_spawn_interval = spawn_window / float(_total_enemies_this_wave)
	else:
		_spawn_interval = INF

	_spawn_pool.shuffle()


func _process_spawning(delta: float) -> void:
	if _total_enemies_this_wave <= 0:
		return
	if _wave_timer <= (wave_duration - spawn_window):
		return
	if not _spawn_manager:
		return

	_spawn_timer += delta
	while _spawn_timer >= _spawn_interval and _spawn_pool.size() > 0:
		_spawn_timer -= _spawn_interval
		var entry: Dictionary = _spawn_pool.pop_back()
		var pos := _get_random_spawn_pos()
		var data := GameConfig.get_enemy_data(entry["data_id"])
		if data:
			_spawn_manager._spawn_one(pos, data, _current_wave, false, true)


# --- Signal handlers ---

func _on_enemy_killed(_kill_type: String, _position: Vector2, _color: Color, _is_elite: bool = false) -> void:
	pass  # Timer-based waves: kills don't complete the wave


func _on_player_died() -> void:
	_state = State.IDLE
	EventBus.run_ended.emit()


func _on_boss_killed(_boss_name: String) -> void:
	if _state != State.WAVE_ACTIVE:
		return
	_boss_killed_this_wave = true
	if _wave_timer > 5.0:
		_wave_timer = 5.0


# --- Helpers ---

func _should_show_upgrade() -> bool:
	return _get_wave_config(_current_wave).has_upgrade_window


func _get_wave_config(wave: int) -> WaveConfig:
	if wave <= _wave_data.waves.size():
		return _wave_data.waves[wave - 1] as WaveConfig

	var last: WaveConfig = _wave_data.waves.back() as WaveConfig
	var loop_count: int = wave - _wave_data.waves.size()
	var config := WaveConfig.new()
	config.wave_number = wave
	config.melee_count = last.melee_count + loop_count * _wave_data.infinite_melee_increment
	config.ranged_count = last.ranged_count + loop_count * _wave_data.infinite_ranged_increment
	config.charger_count = last.charger_count + loop_count
	config.exploder_count = last.exploder_count + loop_count
	config.tank_count = last.tank_count + maxi(0, loop_count - 2)
	config.egg_count = last.egg_count
	config.spawner_count = last.spawner_count + maxi(0, loop_count - 1)
	config.buffer_count = last.buffer_count
	config.reward_count = last.reward_count
	config.spawn_delay = last.spawn_delay
	config.has_upgrade_window = (wave - 1) % _wave_data.upgrade_interval == 0
	if wave > 20 and wave % 5 == 0:
		config.boss_count = 1
	return config


func _get_data_id(enemy_type: String) -> String:
	var map := {
		"melee": "melee_enemy", "ranged": "ranged_enemy",
		"charger": "charger", "exploder": "exploder",
		"tank": "tank", "boss": "warlord",
		"spawner": "spawner", "egg": "egg",
		"buffer": "buffer", "reward": "reward",
	}
	return map.get(enemy_type, "melee_enemy")


func _get_random_spawn_pos() -> Vector2:
	if not _spawn_manager:
		return Vector2.ZERO
	var base_angle := randf() * TAU
	return _spawn_manager._compute_spawn_position(base_angle, 0)


func _fixup_wave_data() -> void:
	for i in _wave_data.waves.size():
		if not _wave_data.waves[i] is WaveConfig:
			push_warning("WaveManager: .tres sub-resources are untyped, rebuilding defaults")
			_wave_data.waves = WaveData.create_default().waves
			return


func _heal_player_to_full() -> void:
	var player := get_tree().get_first_node_in_group("players")
	if player and player.has_node("HealthComponent"):
		var hc := player.get_node("HealthComponent")
		if hc.has_method("heal_full"):
			hc.heal_full()


func _delay(seconds: float) -> void:
	if seconds > 0.0:
		await get_tree().create_timer(seconds).timeout


func _find_spawn_manager() -> Node:
	var siblings := get_parent().get_children() if get_parent() else []
	for child in siblings:
		if child.has_method("spawn_enemies"):
			return child
	return null
