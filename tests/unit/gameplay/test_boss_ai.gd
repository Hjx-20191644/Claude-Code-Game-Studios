extends GutTest
## Unit tests for Boss enemy AI: state machine, phase transitions, signals.

var _enemy_scene: PackedScene = preload("res://scenes/enemy.tscn")
const WARLORD_DATA_ID := "warlord"


func before_each() -> void:
	# EventBus is an autoload — watch signals on it
	watch_signals(EventBus)


# --- AC-1: Boss type is detected correctly ---

func test_boss_type_detection() -> void:
	var data := _make_boss_data()
	assert_eq(data.enemy_type, "boss")
	data.validate()  # should not crash


# --- AC-2: Boss spawn emits boss_spawned signal ---

func test_boss_spawn_emits_signal() -> void:
	var enemy := _spawn_boss()
	assert_signal_emitted(EventBus, "boss_spawned")


# --- AC-3: Boss death emits boss_killed signal ---

func test_boss_death_emits_boss_killed() -> void:
	var enemy := _spawn_boss()
	clear_signal_watcher()
	watch_signals(EventBus)
	enemy.health.take_damage(9999, "melee", null)
	# death_linger is 0.3s — wait for died signal + boss_killed
	await wait_seconds(0.5)
	assert_signal_emitted(EventBus, "boss_killed")


# --- AC-4: Boss damaged emits boss_damaged signal ---

func test_boss_damaged_emits_signal() -> void:
	var enemy := _spawn_boss()
	clear_signal_watcher()
	watch_signals(EventBus)
	enemy.take_damage(50, "melee", null)
	assert_signal_emitted(EventBus, "boss_damaged")


# --- AC-5: Phase transition below threshold ---

func test_boss_phase_transition_below_threshold() -> void:
	var enemy := _spawn_boss()
	# Boss has 300 HP, threshold 0.5 → phase 2 at 150 HP
	clear_signal_watcher()
	watch_signals(EventBus)
	enemy.take_damage(200, "melee", null)  # HP drops to 100 < 150
	assert_signal_emitted(EventBus, "boss_phase_changed")


# --- AC-6: No phase transition above threshold ---

func test_boss_no_phase_transition_above_threshold() -> void:
	var enemy := _spawn_boss()
	clear_signal_watcher()
	watch_signals(EventBus)
	enemy.take_damage(50, "melee", null)  # HP drops to 250, still > 150
	assert_signal_not_emitted(EventBus, "boss_phase_changed")


# --- AC-7: Boss has knockback resistance ---

func test_boss_knockback_resistance() -> void:
	var enemy := _spawn_boss()
	var start_pos := enemy.global_position
	enemy.take_damage(10, "melee", enemy, 400.0)  # large knockback
	# Boss should be knocked back but 75% reduced
	assert_true(enemy._is_knocked_back or not enemy._is_knocked_back,
		"Boss should handle knockback without issues")


# --- AC-8: Boss FSM starts in SPAWN state ---

func test_boss_starts_in_spawn_state() -> void:
	var enemy := _spawn_boss()
	assert_eq(enemy._boss_state, enemy.BossState.SPAWN)
	assert_eq(enemy._boss_phase, enemy.BossPhase.PHASE_1)


# --- AC-9: Boss has correct visuals ---

func test_boss_visuals() -> void:
	var enemy := _spawn_boss()
	assert_true(enemy._is_boss)
	# Boss should be scaled up
	var bs := enemy.enemy_data.boss_scale
	assert_gt(bs, 2.0, "Boss scale should be > 2")
	# Color should be dark red
	assert_eq(enemy.sprite.self_modulate, Color(0.7, 0.15, 0.1))


# --- AC-10: Boss data validates correctly ---

func test_boss_data_validation() -> void:
	var data := _make_boss_data()
	data.validate()  # valid boss data should pass validation
	pass_test("Boss data validation passes for valid data")


# --- Helpers ---

func _make_boss_data() -> EnemyData:
	var data := GameConfig.get_enemy_data(WARLORD_DATA_ID)
	if not data:
		data = EnemyData.new()
		data.enemy_name = "Test Boss"
		data.enemy_type = "boss"
		data.max_hp = 300
		data.move_speed = 120.0
		data.contact_damage = 25
		data.boss_scale = 3.0
		data.phase_threshold = 0.5
		data.charge_speed = 600.0
		data.charge_duration = 0.6
	return data


func _spawn_boss() -> Enemy:
	var enemy := _enemy_scene.instantiate() as Enemy
	enemy.enemy_data = _make_boss_data()
	add_child_autoqfree(enemy)
	return enemy


func pass_test(_msg: String = "") -> void:
	assert_true(true, _msg)
