extends GutTest

const MP_SCRIPT := preload("res://src/core/meta_progress.gd")

var _mp: Node
var _save_path := "user://profile.json"


func before_each() -> void:
	_mp = autoqfree(MP_SCRIPT.new())
	_mp.add_child(autoqfree(Node.new()))
	if FileAccess.file_exists(_save_path):
		DirAccess.remove_absolute(_save_path)
	watch_signals(EventBus)


func after_each() -> void:
	if FileAccess.file_exists(_save_path):
		DirAccess.remove_absolute(_save_path)


# --- AC-1: add_shards increases and persists ---

func test_ac1_add_shards_increases_total() -> void:
	_mp.add_shards(50)
	assert_eq(_mp.get_shards(), 50)
	assert_eq(_mp.lifetime_stats.total_shards_earned, 50)
	assert_signal_emitted(EventBus, "shards_changed")


func test_ac1b_shards_persist_across_reload() -> void:
	_mp.add_shards(100)
	_mp._save_profile()

	var mp2: Node = MP_SCRIPT.new()
	mp2._load_profile()
	assert_eq(mp2.get_shards(), 100)
	mp2.free()


# --- AC-2: purchase() with sufficient shards succeeds ---

func test_ac2_purchase_success() -> void:
	_mp.add_shards(200)
	var ok: bool = _mp.purchase("max_hp_bonus", 100)
	assert_true(ok, "Purchase should succeed")
	assert_eq(_mp.get_shards(), 100)
	assert_true(_mp.is_unlocked("max_hp_bonus"))
	assert_signal_emitted(EventBus, "item_unlocked")


# --- AC-3: purchase() with insufficient shards fails ---

func test_ac3_purchase_insufficient_shards_fails() -> void:
	_mp.add_shards(50)
	var ok: bool = _mp.purchase("max_hp_bonus", 100)
	assert_false(ok, "Purchase should fail with insufficient shards")
	assert_eq(_mp.get_shards(), 50)
	assert_false(_mp.is_unlocked("max_hp_bonus"))
	assert_signal_emitted(EventBus, "item_purchase_failed")


# --- AC-4: purchase() already unlocked item fails ---

func test_ac4_purchase_already_unlocked_fails() -> void:
	_mp.add_shards(500)
	_mp.purchase("weapon_longsword", 200)
	var ok: bool = _mp.purchase("weapon_longsword", 200)
	assert_false(ok, "Duplicate purchase should fail")
	assert_signal_emitted(EventBus, "item_purchase_failed")


# --- AC-5: is_unlocked() query ---

func test_ac5_is_unlocked_queries_correctly() -> void:
	assert_false(_mp.is_unlocked("anything"))
	_mp.unlocked_items.append("anything")
	assert_true(_mp.is_unlocked("anything"))


# --- AC-6: record_run() updates lifetime stats ---

func test_ac6_record_run_updates_stats() -> void:
	var stats := RunStats.new()
	stats.total_kills = 15
	stats.wave_reached = 5

	_mp.record_run(stats, 30)
	assert_eq(_mp.lifetime_stats.total_deaths, 1)
	assert_eq(_mp.lifetime_stats.total_kills, 15)
	assert_eq(_mp.lifetime_stats.highest_wave, 5)
	assert_eq(_mp.lifetime_stats.total_shards_earned, 30)


# --- AC-7: record_run() tracks highest wave ---

func test_ac7_record_run_highest_wave_tracks_max() -> void:
	var s1 := RunStats.new(); s1.wave_reached = 3
	var s2 := RunStats.new(); s2.wave_reached = 7
	var s3 := RunStats.new(); s3.wave_reached = 5

	_mp.record_run(s1, 0)
	_mp.record_run(s2, 0)
	_mp.record_run(s3, 0)
	assert_eq(_mp.lifetime_stats.highest_wave, 7)
	assert_eq(_mp.lifetime_stats.total_deaths, 3)


# --- AC-8: purchase emits correct signals ---

func test_ac8_purchase_signal_parameters() -> void:
	_mp.add_shards(500)
	_mp.purchase("test_item", 100)
	var args: Array = get_signal_parameters(EventBus, "item_unlocked")
	assert_eq(args[0], "test_item")


# --- AC-9: add_shards(0) or negative does nothing ---

func test_ac9_add_zero_or_negative_shards_noop() -> void:
	_mp.add_shards(0)
	assert_eq(_mp.get_shards(), 0)
	_mp.add_shards(-5)
	assert_eq(_mp.get_shards(), 0)
	assert_signal_not_emitted(EventBus, "shards_changed")


# --- AC-10: profile loaded signal emitted when profile exists ---

func test_ac10_profile_loaded_signal() -> void:
	_mp.add_shards(10)  # creates + saves profile
	var mp2: Node = MP_SCRIPT.new()
	mp2._load_profile()
	assert_signal_emitted(EventBus, "profile_loaded")
	mp2.free()


# --- Extra: shards accumulate across multiple add_shards ---

func test_shards_accumulate() -> void:
	_mp.add_shards(10)
	_mp.add_shards(20)
	_mp.add_shards(30)
	assert_eq(_mp.get_shards(), 60)
