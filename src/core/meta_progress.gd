extends Node
## Persistent meta-progression: shards, unlocks, lifetime stats.
## Autoload — survives scene transitions.

const SAVE_PATH := "user://profile.json"

var shards: int = 0
var unlocked_items: Array[String] = []
var lifetime_stats: Dictionary = {
	total_kills = 0,
	total_deaths = 0,
	highest_wave = 0,
	total_shards_earned = 0,
}


func _ready() -> void:
	_load_profile()


## Add shards earned during a run. Persists immediately.
func add_shards(amount: int) -> void:
	if amount <= 0:
		return
	shards += amount
	lifetime_stats.total_shards_earned += amount
	_save_profile()
	EventBus.shards_changed.emit(shards)


func get_shards() -> int:
	return shards


## Spend shards on an unlock. Returns true on success.
func purchase(unlock_id: String, cost: int) -> bool:
	if is_unlocked(unlock_id):
		EventBus.item_purchase_failed.emit(unlock_id, "already_unlocked")
		return false
	if shards < cost:
		EventBus.item_purchase_failed.emit(unlock_id, "insufficient_shards")
		return false
	shards -= cost
	unlocked_items.append(unlock_id)
	_save_profile()
	EventBus.shards_changed.emit(shards)
	EventBus.item_unlocked.emit(unlock_id)
	return true


func is_unlocked(id: String) -> bool:
	return id in unlocked_items


## Record a run completion. Updates lifetime stats.
func record_run(stats: RunStats, shards_earned: int) -> void:
	lifetime_stats.total_deaths += 1
	lifetime_stats.total_kills += stats.total_kills
	if stats.wave_reached > lifetime_stats.highest_wave:
		lifetime_stats.highest_wave = stats.wave_reached
	add_shards(shards_earned)
	# save again for stats update (add_shards already saves, but this is explicit)
	_save_profile()


func _save_profile() -> void:
	var data := {
		shards = shards,
		unlocked_items = unlocked_items,
		lifetime_stats = lifetime_stats,
	}
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(data, "\t"))
		file.close()
	else:
		push_warning("MetaProgress: failed to write profile to %s" % SAVE_PATH)


func _load_profile() -> void:
	if not FileAccess.file_exists(SAVE_PATH):
		return

	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if not file:
		return

	var text := file.get_as_text()
	file.close()

	var json := JSON.new()
	if json.parse(text) != OK:
		push_warning("MetaProgress: corrupted profile, starting fresh")
		return

	var data: Dictionary = json.get_data()
	shards = data.get("shards", 0)
	unlocked_items.clear()
	for item in data.get("unlocked_items", []):
		unlocked_items.append(item)
	var saved_stats: Dictionary = data.get("lifetime_stats", {})
	if not saved_stats.is_empty():
		for key in lifetime_stats.keys():
			lifetime_stats[key] = saved_stats.get(key, lifetime_stats[key])

	EventBus.profile_loaded.emit()
