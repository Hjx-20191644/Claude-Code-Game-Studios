extends RefCounted
class_name LeaderboardManager

## Leaderboard persistence: saves/loads top 10 runs to user://leaderboard.json.
## Static methods — callable from any scene without node reference.

const SAVE_PATH := "user://leaderboard.json"
const MAX_ENTRIES := 10


static func save_entry(stats: Dictionary) -> void:
	var entries := load_entries()
	entries.append(stats)
	entries.sort_custom(func(a, b): return a.score > b.score)
	if entries.size() > MAX_ENTRIES:
		entries = entries.slice(0, MAX_ENTRIES)
	_write_json(entries)


static func load_entries() -> Array:
	if not FileAccess.file_exists(SAVE_PATH):
		return []
	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if not file:
		return []
	var text := file.get_as_text()
	file.close()
	if text.is_empty():
		return []
	var parsed = JSON.parse_string(text)
	if parsed == null or not parsed is Array:
		return []
	var entries: Array = []
	for entry in parsed:
		if entry is Dictionary:
			entries.append(entry)
	return entries


static func _write_json(entries: Array) -> void:
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if not file:
		push_warning("Leaderboard: cannot write to %s" % SAVE_PATH)
		return
	file.store_string(JSON.stringify(entries, "\t"))
	file.close()
