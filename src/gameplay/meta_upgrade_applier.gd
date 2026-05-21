extends Node
## Applies unlocked meta-upgrades at the start of each run.

var _applied: bool = false


func _ready() -> void:
	EventBus.wave_started.connect(_on_wave_started)


func _on_wave_started(wave_number: int) -> void:
	if wave_number != 1 or _applied:
		return
	_applied = true
	_apply_all()


func reset_for_new_run() -> void:
	_applied = false


func _apply_all() -> void:
	var unlocks: Array = MetaProgress.unlocked_items
	if unlocks.is_empty():
		return

	for id in unlocks:
		var ul: Resource = _load_unlock(id)
		if not ul:
			continue
		_apply_single(ul)


func _apply_single(ul: Resource) -> void:
	match ul.target_stat:
		"max_hp":
			var player := get_tree().get_first_node_in_group("players")
			if player and player.has_node("HealthComponent"):
				var hc := player.get_node("HealthComponent")
				hc.max_hp += int(ul.value)
				EventBus.health_changed.emit(hc.current_hp, hc.max_hp)


		"dodge_cooldown":
			var ds := _find_node_in_systems("DodgeSystem")
			if ds and ds.has_method("add_meta_cooldown_reduction"):
				ds.add_meta_cooldown_reduction(abs(ul.value))

		"starting_shards":
			var sm := _find_node_in_systems("ShardManager")
			if sm and sm.has_method("add_starting_shards"):
				sm.add_starting_shards(int(ul.value))

		"extra_weapon_choice":
			pass  # Handled by WeaponSelectUI reading MetaProgress

		_:
			if ul.target_stat.begins_with("weapon_"):
				pass  # Handled by WeaponSelectUI
			elif ul.target_stat in ["hp_regen", "lifesteal_ratio"]:
				var ua := _find_node_in_systems("UpgradeApplier")
				if ua and ua.has_method("add_meta_bonus"):
					ua.add_meta_bonus(ul.target_stat, ul.value)


func _load_unlock(id: String) -> Resource:
	var path := "res://assets/data/unlocks/%s.tres" % id
	if ResourceLoader.exists(path):
		return load(path)
	return null


func _find_node_in_systems(name: String) -> Node:
	var parent_systems := get_parent()
	if not parent_systems:
		return null
	if name.is_empty():
		return null
	return parent_systems.get_node_or_null(name)
