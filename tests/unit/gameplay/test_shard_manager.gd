extends GutTest

const SM_SCRIPT := preload("res://src/gameplay/shard_manager.gd")

var _sm: Node
var _enemies: Node2D


func before_each() -> void:
	var systems: Node = add_child_autoqfree(Node.new())
	systems.name = "Systems"

	var arena: Node2D = add_child_autoqfree(Node2D.new())
	arena.name = "Arena"
	_enemies = autoqfree(Node2D.new())
	_enemies.name = "Enemies"
	arena.add_child(_enemies)

	_sm = autoqfree(SM_SCRIPT.new())
	systems.add_child(_sm)
	_sm._pickup_parent = _enemies
	watch_signals(EventBus)


# --- AC-1: shard_collected increments run shards ---

func test_ac1_collected_increments_run_shards() -> void:
	EventBus.shard_collected.emit(3, 3)
	assert_eq(_sm.get_run_shards(), 3)
	EventBus.shard_collected.emit(4, 7)
	assert_eq(_sm.get_run_shards(), 7)


# --- AC-2: clear_run_shards() resets to 0 ---

func test_ac2_clear_run_shards_resets() -> void:
	EventBus.shard_collected.emit(10, 10)
	assert_eq(_sm.get_run_shards(), 10)
	_sm.clear_run_shards()
	assert_eq(_sm.get_run_shards(), 0)


# --- AC-3: run_shards starts at 0 ---

func test_ac3_run_shards_starts_at_zero() -> void:
	assert_eq(_sm.get_run_shards(), 0)


# --- AC-4: multiple kills accumulate ---

func test_ac4_multiple_kills_accumulate() -> void:
	EventBus.shard_collected.emit(3, 3)
	EventBus.shard_collected.emit(4, 7)
	EventBus.shard_collected.emit(5, 12)
	assert_eq(_sm.get_run_shards(), 12)


# --- AC-5: enemy_killed with known type spawns shard ---

func test_ac5_known_type_spawns_shard() -> void:
	var before: int = _enemies.get_child_count()
	EventBus.enemy_killed.emit("melee", Vector2(100, 100), Color.RED, false)
	assert_eq(_enemies.get_child_count(), before + 1)


# --- AC-6: unknown kill_type spawns nothing ---

func test_ac6_unknown_type_no_spawn() -> void:
	var before: int = _enemies.get_child_count()
	EventBus.enemy_killed.emit("boss", Vector2.ZERO, Color.RED, false)
	assert_eq(_enemies.get_child_count(), before)


# --- AC-7: elite enemy (is_elite=true) spawns 2x value shard ---

func test_ac7_elite_spawns_2x_shard() -> void:
	EventBus.enemy_killed.emit("melee", Vector2(100, 100), Color.RED, true)
	assert_eq(_enemies.get_child_count(), 1)
	var shard: Area2D = _enemies.get_child(0) as Area2D
	assert_eq(shard.value, 6)


# --- AC-8: no crash when player node missing ---

func test_ac8_no_crash_no_player() -> void:
	EventBus.enemy_killed.emit("melee", Vector2.ZERO, Color.RED, false)
	pass_test("No crash when player is missing")


# --- AC-9: get/set pickup radius ---

func test_ac9_pickup_radius_get_set() -> void:
	assert_eq(_sm.get_pickup_radius(), 100.0)
	_sm.set_pickup_radius(150.0)
	assert_eq(_sm.get_pickup_radius(), 150.0)


# --- AC-10: run_ended does not crash ---

func test_ac10_run_ended_no_crash() -> void:
	EventBus.run_ended.emit()
	pass_test("run_ended does not crash")
