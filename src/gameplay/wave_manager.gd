extends Node
class_name WaveManager

## Wave state machine: orchestrates the "fight → clear → upgrade" rhythm.
## Communicates entirely through EventBus signals.

enum State { IDLE, WAVE_ACTIVE, WAVE_CLEARED, UPGRADE_WINDOW }

@export var wave_data_path: String = "res://assets/data/wave_config.tres"

var _state: State = State.IDLE
var _current_wave: int = 0

# Per-wave tracking
var _enemies_spawned: int = 0
var _enemies_killed: int = 0
var _all_spawned: bool = false
var _pending_spawn_batches: int = 0
var _wave_start_ticks: int = 0

# Upgrade timeout
var _upgrade_timeout_timer: float = 0.0

var _wave_data: WaveData
var _spawn_manager: Node


func _ready() -> void:
	_wave_data = load(wave_data_path) as WaveData
	assert(_wave_data, "WaveManager: failed to load wave data from %s" % wave_data_path)
	_fixup_wave_data()
	_wave_data.validate()

	_spawn_manager = _find_spawn_manager()
	if not _spawn_manager:
		push_warning("WaveManager: no spawn node found, spawn calls will be skipped")

	EventBus.enemy_killed.connect(_on_enemy_killed)
	EventBus.wave_spawn_complete.connect(_on_wave_spawn_complete)
	EventBus.player_died.connect(_on_player_died)


func _physics_process(delta: float) -> void:
	if _state == State.UPGRADE_WINDOW:
		_upgrade_timeout_timer -= delta
		if _upgrade_timeout_timer <= 0.0:
			_schedule_next_wave()


## Start a new run: reset everything, begin wave 1.
func start_run() -> void:
	_current_wave = 0
	_state = State.IDLE
	_advance_to_next_wave()


## Called by in-run upgrade UI when player confirms their choice.
func upgrade_completed() -> void:
	if _state == State.UPGRADE_WINDOW:
		_schedule_next_wave()


## Returns current wave number (1-based, 0 before start_run).
func get_current_wave() -> int:
	return _current_wave


# --- State transitions ---

func _advance_to_next_wave() -> void:
	_state = State.IDLE
	_current_wave += 1
	_reset_wave_tracking()

	var config := _get_wave_config(_current_wave)

	# Count how many spawn batches we expect
	_pending_spawn_batches = 0
	if config.melee_count > 0:
		_pending_spawn_batches += 1
	if config.ranged_count > 0:
		_pending_spawn_batches += 1

	_state = State.WAVE_ACTIVE
	_wave_start_ticks = Time.get_ticks_msec()
	EventBus.wave_started.emit(_current_wave)

	if _spawn_manager:
		_spawn_manager.spawn_enemies("melee", config.melee_count, _current_wave)
		_spawn_manager.spawn_enemies("ranged", config.ranged_count, _current_wave)
	else:
		_all_spawned = true
		_check_wave_complete()

	# If no enemies this wave, auto-complete
	if _pending_spawn_batches == 0:
		_all_spawned = true
		_on_wave_cleared()


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


# --- Signal handlers ---

func _on_wave_spawn_complete(count: int, _enemy_type: String) -> void:
	if _state != State.WAVE_ACTIVE:
		return
	_enemies_spawned += count
	_pending_spawn_batches -= 1
	if _pending_spawn_batches <= 0:
		_all_spawned = true
		_check_wave_complete()


func _on_enemy_killed(_kill_type: String, _position: Vector2, _color: Color) -> void:
	if _state != State.WAVE_ACTIVE:
		return
	_enemies_killed += 1
	_check_wave_complete()


func _on_player_died() -> void:
	_state = State.IDLE
	EventBus.run_ended.emit()


# --- Helpers ---

const MIN_WAVE_DURATION_MSEC: int = 50

func _check_wave_complete() -> void:
	if not _all_spawned:
		return
	if _enemies_killed < _enemies_spawned:
		return
	if Time.get_ticks_msec() - _wave_start_ticks < MIN_WAVE_DURATION_MSEC:
		return
	_on_wave_cleared()


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
	config.spawn_delay = last.spawn_delay
	config.has_upgrade_window = (wave - 1) % _wave_data.upgrade_interval == 0
	return config


func _fixup_wave_data() -> void:
	for i in _wave_data.waves.size():
		if not _wave_data.waves[i] is WaveConfig:
			push_warning("WaveManager: .tres sub-resources are untyped, rebuilding defaults")
			_wave_data.waves = WaveData.create_default().waves
			return


func _reset_wave_tracking() -> void:
	_enemies_spawned = 0
	_enemies_killed = 0
	_all_spawned = false
	_pending_spawn_batches = 0


func _delay(seconds: float) -> void:
	if seconds > 0.0:
		await get_tree().create_timer(seconds).timeout


func _find_spawn_manager() -> Node:
	var siblings := get_parent().get_children() if get_parent() else []
	for child in siblings:
		if child.has_method("spawn_enemies"):
			return child
	return null
