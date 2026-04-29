extends GutTest
## Unit tests for ScoreManager. Covers all 10 acceptance criteria.

var _sm: ScoreManager


func before_each() -> void:
	var systems: Node = add_child_autoqfree(Node.new())
	systems.name = "Systems"
	_sm = autoqfree(ScoreManager.new())
	systems.add_child(_sm)
	watch_signals(EventBus)


# --- AC-1: melee kill → total_kills +1, melee_kills +1, score +100 ---

func test_ac1_melee_kill_updates_stats() -> void:
	EventBus.enemy_killed.emit("melee", Vector2.ZERO, Color.RED)
	assert_eq(_sm.get_total_kills(), 1)
	assert_eq(_sm.get_stats().melee_kills, 1)
	assert_eq(_sm.get_stats().ranged_kills, 0)
	assert_eq(_sm.get_score(), _sm.score_melee_kill)
	assert_signal_emitted(EventBus, "score_changed")


# --- AC-2: ranged kill → ranged_kills +1, score +150 ---

func test_ac2_ranged_kill_updates_stats() -> void:
	EventBus.enemy_killed.emit("ranged", Vector2.ZERO, Color.BLUE)
	assert_eq(_sm.get_total_kills(), 1)
	assert_eq(_sm.get_stats().ranged_kills, 1)
	assert_eq(_sm.get_stats().melee_kills, 0)
	assert_eq(_sm.get_score(), _sm.score_ranged_kill)


# --- AC-3: total_kills = melee_kills + ranged_kills ---

func test_ac3_total_kills_equals_sum() -> void:
	EventBus.enemy_killed.emit("melee", Vector2.ZERO, Color.RED)
	EventBus.enemy_killed.emit("ranged", Vector2.ZERO, Color.BLUE)
	EventBus.enemy_killed.emit("melee", Vector2.ZERO, Color.RED)

	var stats: RunStats = _sm.get_stats()
	assert_eq(stats.total_kills, 3)
	assert_eq(stats.total_kills, stats.melee_kills + stats.ranged_kills)


# --- AC-4: damage_dealt accumulates total_damage_dealt ---

func test_ac4_damage_dealt_accumulates() -> void:
	EventBus.damage_dealt.emit(25.0, Vector2.ZERO, "melee")
	EventBus.damage_dealt.emit(10.0, Vector2.ZERO, "ranged")
	assert_eq(_sm.get_stats().total_damage_dealt, 35.0)


# --- AC-5: damage_taken accumulates total_damage_taken ---

func test_ac5_damage_taken_accumulates() -> void:
	EventBus.damage_taken.emit(15.0, Vector2.ZERO)
	EventBus.damage_taken.emit(30.0, Vector2.ZERO)
	assert_eq(_sm.get_stats().total_damage_taken, 45.0)


# --- AC-6: wave_started updates wave_reached to max ---

func test_ac6_wave_started_records_max() -> void:
	EventBus.wave_started.emit(3)
	assert_eq(_sm.get_wave_reached(), 3)
	EventBus.wave_started.emit(2)
	assert_eq(_sm.get_wave_reached(), 3)
	EventBus.wave_started.emit(5)
	assert_eq(_sm.get_wave_reached(), 5)


# --- AC-7: upgrade_applied increments upgrades_acquired ---

func test_ac7_upgrade_acquired_increments() -> void:
	EventBus.upgrade_applied.emit({"upgrade_id": "test", "display_name": "Test"})
	EventBus.upgrade_applied.emit({"upgrade_id": "test2", "display_name": "Test2"})
	assert_eq(_sm.get_stats().upgrades_acquired, 2)


# --- AC-8: reset() zeros all stats and restarts timer ---

func test_ac8_reset_zeros_all_stats() -> void:
	EventBus.enemy_killed.emit("melee", Vector2.ZERO, Color.RED)
	EventBus.damage_dealt.emit(10.0, Vector2.ZERO, "melee")
	EventBus.damage_taken.emit(5.0, Vector2.ZERO)
	EventBus.wave_started.emit(3)
	EventBus.upgrade_applied.emit({"upgrade_id": "x"})

	assert_ne(_sm.get_score(), 0)

	_sm.reset()
	assert_eq(_sm.get_score(), 0)
	assert_eq(_sm.get_wave_reached(), 0)
	assert_eq(_sm.get_total_kills(), 0)
	assert_eq(_sm.get_stats().melee_kills, 0)
	assert_eq(_sm.get_stats().ranged_kills, 0)
	assert_eq(_sm.get_stats().total_damage_dealt, 0.0)
	assert_eq(_sm.get_stats().total_damage_taken, 0.0)
	assert_eq(_sm.get_stats().upgrades_acquired, 0)


# --- AC-9: score_changed emitted on score change ---

func test_ac9_score_changed_emitted() -> void:
	clear_signal_watcher()
	watch_signals(EventBus)
	EventBus.enemy_killed.emit("melee", Vector2.ZERO, Color.RED)
	assert_signal_emitted(EventBus, "score_changed")
	var args: Array = get_signal_parameters(EventBus, "score_changed")
	assert_eq(args[0], _sm.score_melee_kill)


# --- AC-10: get_stats() returns consistent snapshot ---

func test_ac10_get_stats_snapshot_consistent() -> void:
	EventBus.enemy_killed.emit("melee", Vector2.ZERO, Color.RED)
	EventBus.enemy_killed.emit("ranged", Vector2.ZERO, Color.BLUE)
	EventBus.wave_started.emit(2)

	var snap: RunStats = _sm.get_stats()
	assert_eq(snap.score, _sm.get_score())
	assert_eq(snap.total_kills, _sm.get_total_kills())
	assert_eq(snap.wave_reached, _sm.get_wave_reached())

	EventBus.enemy_killed.emit("melee", Vector2.ZERO, Color.RED)
	assert_ne(snap.score, _sm.get_score(), "Snapshot should be frozen at capture time")


# --- Extra: unknown kill_type is ignored ---

func test_unknown_kill_type_ignored() -> void:
	EventBus.enemy_killed.emit("magic", Vector2.ZERO, Color.WHITE)
	assert_eq(_sm.get_total_kills(), 0)
	assert_eq(_sm.get_score(), 0)


# --- Extra: player_died freezes survival_time ---

func test_player_died_freezes_survival_time() -> void:
	_sm.reset()
	var before: float = _sm.get_stats().survival_time
	EventBus.player_died.emit()
	await wait_seconds(0.05)
	var after: float = _sm.get_stats().survival_time
	assert_eq(before, after, "Survival time should be frozen after player death")


# --- Extra: survival time increases over real time ---

func test_survival_time_increases() -> void:
	_sm.reset()
	var t1: float = _sm.get_stats().survival_time
	await wait_seconds(0.1)
	var t2: float = _sm.get_stats().survival_time
	assert_gt(t2, t1, "Survival time should increase as real time passes")
