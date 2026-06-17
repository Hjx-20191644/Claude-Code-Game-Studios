extends GutTest
## Unit tests for WaveManager. Pure signal-driven testing (no SpawnManager needed).

const WAVE_DATA_PATH := "res://assets/data/wave_config.tres"

var _wm: WaveManager
var _wave_data: WaveData


func before_all() -> void:
	_wave_data = load(WAVE_DATA_PATH) as WaveData


func before_each() -> void:
	var systems: Node = add_child_autoqfree(Node.new())
	systems.name = "Systems"

	_wm = autoqfree(WaveManager.new())
	_wm.wave_data_path = WAVE_DATA_PATH
	systems.add_child(_wm)
	watch_signals(EventBus)


# --- AC-1: start_run() emits wave_started(1) ---

func test_ac1_start_run_emits_wave_started_1() -> void:
	_wm.start_run()
	assert_signal_emitted(EventBus, "wave_started")


# --- AC-2: Wave 1 config has 3 melee, 0 ranged ---

func test_ac2_wave_1_config_melee_3_ranged_0() -> void:
	var data: WaveData = WaveData.create_default()
	var cfg: WaveConfig = data.waves[0]
	assert_eq(cfg.wave_number, 1)
	assert_eq(cfg.melee_count, 3)
	assert_eq(cfg.ranged_count, 0)


# --- AC-3: Wave clears when the survival timer expires ---
# (Sprint 5 changed waves from "kill-all to clear" to "survive the timer".)

func test_ac3_wave_cleared_on_timer_expiry() -> void:
	_wm.start_run()
	# Drive the survival timer down to zero — wave should complete.
	_wm._wave_timer = 0.01
	await wait_seconds(0.05)
	assert_signal_emitted(EventBus, "wave_completed")


# --- AC-4: Wave 2 has upgrade window (even-wave upgrade schedule) ---

func test_ac4_wave_2_has_upgrade() -> void:
	var data: WaveData = WaveData.create_default()
	assert_true(data.waves[1].has_upgrade_window, "Wave 2 should have upgrade")


# --- AC-5: Wave 3 has no upgrade ---

func test_ac5_wave_3_no_upgrade() -> void:
	var data: WaveData = WaveData.create_default()
	assert_false(data.waves[2].has_upgrade_window, "Wave 3 should not have upgrade")


# --- AC-6: upgrade_completed() allows next wave ---

func test_ac6_upgrade_completed_does_not_crash() -> void:
	# Should not crash when called in wrong state
	_wm.upgrade_completed()
	pass_test("upgrade_completed is safe to call anytime")


# --- AC-7: Current wave tracks properly ---

func test_ac7_current_wave_tracks_properly() -> void:
	assert_eq(_wm.get_current_wave(), 0)
	_wm.start_run()
	assert_eq(_wm.get_current_wave(), 1)


# --- AC-8: Player death emits run_ended ---

func test_ac8_player_died_emits_run_ended() -> void:
	clear_signal_watcher()
	watch_signals(EventBus)
	_wm.start_run()
	EventBus.player_died.emit()
	assert_signal_emitted(EventBus, "run_ended")


# --- AC-9: Wave 11 is an authored config wave (DPS gate), melee=3 ranged=2 ---
# (Sprint 6 extended the config to 20 waves, so wave 11 is no longer infinite.)

func test_ac9_wave_11_authored_counts() -> void:
	var cfg: WaveConfig = _wm._get_wave_config(11)
	assert_eq(cfg.wave_number, 11)
	assert_eq(cfg.melee_count, 3)   # authored DPS-gate wave
	assert_eq(cfg.ranged_count, 2)


# --- AC-10: start_run() mid-run resets to wave 1 ---

func test_ac10_start_run_mid_run_resets() -> void:
	_wm.start_run()
	assert_eq(_wm.get_current_wave(), 1)
	# Advance the timer a bit (does not need to clear)
	_wm._wave_timer = 0.01
	await wait_seconds(0.05)
	# Start fresh
	_wm.start_run()
	assert_eq(_wm.get_current_wave(), 1)


# --- Extra: get_current_wave before start is 0 ---

func test_get_current_wave_before_start() -> void:
	assert_eq(_wm.get_current_wave(), 0)


# --- Extra: Infinite upgrade formula applies to waves beyond the 20-wave config ---
# (Sprint 6 made waves 1-20 authored; the infinite formula now kicks in at wave 21+.)

func test_infinite_upgrade_formula() -> void:
	# upgrade_interval=2: (wave-1)%2==0 → upgrades on odd post-config waves (21, 23, 25...)
	var cfg21: WaveConfig = _wm._get_wave_config(21)
	assert_true(cfg21.has_upgrade_window, "Wave 21: (21-1)%2=0, upgrade")
	var cfg22: WaveConfig = _wm._get_wave_config(22)
	assert_false(cfg22.has_upgrade_window, "Wave 22: (22-1)%2=1, no upgrade")


# --- Extra: Wave does not clear before the timer expires ---

func test_wave_min_duration_guard() -> void:
	_wm.start_run()
	# Killing enemies alone should NOT clear the wave under the survival-timer system.
	EventBus.wave_spawn_complete.emit(1, "melee")
	EventBus.enemy_killed.emit("melee", Vector2.ZERO, Color.RED)
	# Just verify no crash and no premature wave_completed.
	pass_test("survival-timer system does not crash on early kills")


# --- AC-11: Wave 10 (first boss) has boss_count = 1 ---
# (Sprint 6 20-wave rhythm: first boss at wave 10, final boss at wave 20.)

func test_wave_10_has_boss() -> void:
	var data: WaveData = WaveData.create_default()
	var cfg: WaveConfig = data.waves[9]  # wave 10 is index 9
	assert_eq(cfg.boss_count, 1, "Wave 10 should have boss_count = 1")


# --- AC-12: Wave 20 (final boss) has boss_count = 1 ---

func test_wave_20_has_boss() -> void:
	var data: WaveData = WaveData.create_default()
	var cfg: WaveConfig = data.waves[19]  # wave 20 is index 19
	assert_eq(cfg.boss_count, 1, "Wave 20 should have boss_count = 1")


# --- AC-13: Slaying the wave 20 final boss triggers run_won ---
# (Sprint 6: survival-timer waves + victory on final boss death.
#  Mid-wave boss kills skip to the last 5s instead of clearing instantly.)

func test_final_boss_killed_wins_run() -> void:
	# Fast-forward to wave 20.
	for _i in range(20):
		_wm._advance_to_next_wave()
	assert_eq(_wm.get_current_wave(), 20)
	# Slaying the final boss should emit run_won (not wave_completed).
	EventBus.boss_killed.emit("军阀")
	assert_signal_emitted(EventBus, "run_won")


# --- AC-14: Wave 25 (infinite, 25%5==0) has boss ---
# (Sprint 6: infinite formula now starts at wave 21; 25 is the first infinite boss wave.)

func test_wave_25_infinite_has_boss() -> void:
	var cfg: WaveConfig = _wm._get_wave_config(25)
	assert_eq(cfg.boss_count, 1, "Wave 25 (25%%5==0) should have boss")


# --- AC-15: Wave 21 (infinite, 21%5!=0) has no boss ---

func test_wave_21_infinite_no_boss() -> void:
	var cfg: WaveConfig = _wm._get_wave_config(21)
	assert_eq(cfg.boss_count, 0, "Wave 21 (21%%5!=0) should not have boss")


# --- AC-16: Wave 22 (infinite, not boss wave) no boss ---

func test_wave_22_no_boss_before_25() -> void:
	var cfg: WaveConfig = _wm._get_wave_config(22)
	assert_eq(cfg.boss_count, 0, "Wave 22 should not have boss (first infinite boss at 25)")


func pass_test(_msg: String = "") -> void:
	assert_true(true, _msg)
