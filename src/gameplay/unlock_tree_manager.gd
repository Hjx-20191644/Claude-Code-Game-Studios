extends Node
class_name UnlockTreeManager
## Loads unlock data, validates prerequisites, processes purchases via MetaProgress.

const UNLOCKS_DIR := "res://assets/data/unlocks/"

var _all_unlocks: Array = []
var _by_id: Dictionary = {}


func _ready() -> void:
	_load_all_unlocks()


func get_all_unlocks() -> Array:
	return _all_unlocks


func get_unlock(id: String) -> Resource:
	return _by_id.get(id, null)


## Returns unlocks the player can afford and whose prerequisites are met.
func get_available_unlocks() -> Array:
	var available: Array = []
	for ul in _all_unlocks:
		if can_purchase(ul.id):
			available.append(ul)
	return available


func can_purchase(id: String) -> bool:
	var ul = _by_id.get(id, null)
	if not ul:
		return false
	if MetaProgress.is_unlocked(id):
		return false
	for prereq in ul.prerequisites:
		if not MetaProgress.is_unlocked(prereq):
			return false
	return MetaProgress.get_shards() >= ul.cost


func purchase(id: String) -> bool:
	var ul = _by_id.get(id, null)
	if not ul:
		return false
	return MetaProgress.purchase(id, ul.cost)


func get_purchase_block_reason(id: String) -> String:
	var ul = _by_id.get(id, null)
	if not ul:
		return "not_found"
	if MetaProgress.is_unlocked(id):
		return "already_unlocked"
	for prereq in ul.prerequisites:
		if not MetaProgress.is_unlocked(prereq):
			return "prerequisite_missing: %s" % prereq
	if MetaProgress.get_shards() < ul.cost:
		return "insufficient_shards"
	return ""


func _load_all_unlocks() -> void:
	_all_unlocks.clear()
	_by_id.clear()

	var dir := DirAccess.open(UNLOCKS_DIR)
	if not dir:
		push_warning("UnlockTreeManager: cannot open %s" % UNLOCKS_DIR)
		return

	dir.list_dir_begin()
	var file_name := dir.get_next()
	while file_name != "":
		if not dir.current_is_dir() and file_name.ends_with(".tres"):
			var full_path := UNLOCKS_DIR + file_name
			var res = load(full_path)
			if res and not res.id.is_empty():
				_all_unlocks.append(res)
				assert(not _by_id.has(res.id), "Duplicate unlock id: %s" % res.id)
				_by_id[res.id] = res
		file_name = dir.get_next()
	dir.list_dir_end()
