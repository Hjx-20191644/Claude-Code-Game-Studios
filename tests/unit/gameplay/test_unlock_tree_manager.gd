extends GutTest

const UTM_SCRIPT := preload("res://src/gameplay/unlock_tree_manager.gd")

var _utm: Node


func before_each() -> void:
	var systems: Node = add_child_autoqfree(Node.new())
	systems.name = "Systems"
	_utm = autoqfree(UTM_SCRIPT.new())
	systems.add_child(_utm)

	# Reset MetaProgress state between tests
	MetaProgress.shards = 0
	MetaProgress.unlocked_items.clear()
	watch_signals(EventBus)


# --- AC-1: All 8 unlocks loaded ---

func test_ac1_all_unlocks_loaded() -> void:
	var all: Array = _utm.get_all_unlocks()
	assert_eq(all.size(), 7)


# --- AC-2: can_purchase true when affordable and prereqs met ---

func test_ac2_can_purchase_affordable_no_prereq() -> void:
	MetaProgress.add_shards(200)
	assert_true(_utm.can_purchase("max_hp_bonus"), "Should be purchasable: no prereq, enough shards")


# --- AC-3: can_purchase false when insufficient shards ---

func test_ac3_cannot_purchase_without_shards() -> void:
	MetaProgress.add_shards(50)
	assert_false(_utm.can_purchase("max_hp_bonus"), "100-cost item with only 50 shards")


# --- AC-4: can_purchase false when prerequisite not met ---

func test_ac4_cannot_purchase_without_prereq() -> void:
	MetaProgress.add_shards(500)
	assert_false(_utm.can_purchase("dodge_cd_down"), "dodge_cd_down requires max_hp_bonus")


# --- AC-5: can_purchase false when already unlocked ---

func test_ac5_cannot_purchase_already_unlocked() -> void:
	MetaProgress.add_shards(500)
	_utm.purchase("max_hp_bonus")
	assert_false(_utm.can_purchase("max_hp_bonus"), "Already unlocked")


# --- AC-6: purchase() succeeds and persists ---

func test_ac6_purchase_succeeds_and_persists() -> void:
	MetaProgress.add_shards(200)
	var ok: bool = _utm.purchase("max_hp_bonus")
	assert_true(ok, "Purchase should succeed")
	assert_true(MetaProgress.is_unlocked("max_hp_bonus"))
	assert_eq(MetaProgress.get_shards(), 100)


# --- AC-7: get_available_unlocks() returns correct subset ---

func test_ac7_get_available_unlocks() -> void:
	MetaProgress.add_shards(200)
	var available: Array = _utm.get_available_unlocks()
	# max_hp_bonus (100) and extra_weapon_slot (250) — only max_hp_bonus is affordable
	assert_eq(available.size(), 1)
	assert_eq(available[0].id, "max_hp_bonus")


# --- AC-8: get_purchase_block_reason() ---

func test_ac8_block_reason_already_unlocked() -> void:
	MetaProgress.add_shards(500)
	_utm.purchase("max_hp_bonus")
	assert_eq(_utm.get_purchase_block_reason("max_hp_bonus"), "already_unlocked")


func test_ac8b_block_reason_insufficient_shards() -> void:
	assert_eq(_utm.get_purchase_block_reason("max_hp_bonus"), "insufficient_shards")


func test_ac8c_block_reason_prereq_missing() -> void:
	MetaProgress.add_shards(500)
	var reason: String = _utm.get_purchase_block_reason("dodge_cd_down")
	assert_true(reason.contains("prerequisite_missing"), "Expected prereq missing, got: %s" % reason)


# --- AC-9: get_unlock() returns correct data ---

func test_ac9_get_unlock_data() -> void:
	var ul: Resource = _utm.get_unlock("max_hp_bonus")
	assert_ne(ul, null)
	assert_eq(ul.display_name, "生命强化")
	assert_eq(ul.cost, 100)


# --- AC-10: Prerequisite chain 2-level deep ---

func test_ac10_two_level_prereq_chain() -> void:
	MetaProgress.add_shards(1000)
	# Level 1
	assert_true(_utm.purchase("max_hp_bonus"))
	# Level 2
	assert_true(_utm.can_purchase("dodge_cd_down"))
	assert_true(_utm.purchase("dodge_cd_down"))
	# Level 3 requires dodge_cd_down
	assert_true(_utm.can_purchase("unlock_crossbow"))
	assert_true(_utm.purchase("unlock_crossbow"))


# --- Extra: invalid id returns null ---

func test_invalid_id_returns_null() -> void:
	assert_eq(_utm.get_unlock("nonexistent"), null)
	assert_false(_utm.can_purchase("nonexistent"))
	assert_false(_utm.purchase("nonexistent"))


# --- Extra: purchase emits item_unlocked signal ---

func test_purchase_emits_item_unlocked() -> void:
	MetaProgress.add_shards(200)
	_utm.purchase("max_hp_bonus")
	assert_signal_emitted(EventBus, "item_unlocked")
