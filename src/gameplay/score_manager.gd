extends Node
class_name ScoreManager

## Tracks all per-run statistics by listening to EventBus signals.
## Pure data layer — no UI, no gameplay control.

@export var score_melee_kill: int = 100
@export var score_ranged_kill: int = 150

var _stats: RunStats = RunStats.new()
var _start_time: float = 0.0
var _is_timing: bool = false
var _frozen_survival_time: float = 0.0


func _ready() -> void:
	EventBus.enemy_killed.connect(_on_enemy_killed)
	EventBus.damage_dealt.connect(_on_damage_dealt)
	EventBus.damage_taken.connect(_on_damage_taken)
	EventBus.wave_started.connect(_on_wave_started)
	EventBus.upgrade_applied.connect(_on_upgrade_applied)
	EventBus.player_died.connect(_on_player_died)


func reset() -> void:
	_stats = RunStats.new()
	_start_time = Time.get_ticks_msec() / 1000.0
	_is_timing = true
	_frozen_survival_time = 0.0
	EventBus.stats_updated.emit()


# --- Public getters ---

func get_score() -> int:
	return _stats.score


func get_wave_reached() -> int:
	return _stats.wave_reached


func get_total_kills() -> int:
	return _stats.total_kills


func get_stats() -> RunStats:
	var snap := _stats.duplicate_snapshot()
	snap.survival_time = _get_survival_time()
	return snap


# --- Signal handlers ---

func _on_enemy_killed(kill_type: String, _position: Vector2, _color: Color) -> void:
	match kill_type:
		"melee":
			_stats.melee_kills += 1
			_stats.score += score_melee_kill
		"ranged":
			_stats.ranged_kills += 1
			_stats.score += score_ranged_kill
		_:
			push_warning("ScoreManager: unknown kill_type '%s', ignoring" % kill_type)
			return

	_stats.total_kills += 1
	EventBus.score_changed.emit(_stats.score)


func _on_damage_dealt(amount: float, _hit_position: Vector2, _attack_type: String) -> void:
	_stats.total_damage_dealt += amount
	EventBus.stats_updated.emit()


func _on_damage_taken(amount: float, _position: Vector2) -> void:
	_stats.total_damage_taken += amount
	EventBus.stats_updated.emit()


func _on_wave_started(wave_number: int) -> void:
	if wave_number == 1:
		reset()
		return
	if wave_number > _stats.wave_reached:
		_stats.wave_reached = wave_number
	EventBus.stats_updated.emit()


func _on_upgrade_applied(_data: Dictionary) -> void:
	_stats.upgrades_acquired += 1
	EventBus.stats_updated.emit()


func _on_player_died() -> void:
	_frozen_survival_time = _get_survival_time()
	_is_timing = false
	EventBus.stats_updated.emit()


# --- Private ---

func _get_survival_time() -> float:
	if _is_timing:
		return Time.get_ticks_msec() / 1000.0 - _start_time
	return _frozen_survival_time
