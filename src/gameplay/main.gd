extends Node2D
class_name Main

## Game entry point: starts the run, provides restart_run() for GameOverUI.

@onready var _wave_manager: WaveManager = $Systems/WaveManager
@onready var _upgrade_pool: UpgradePool = $Systems/UpgradePool
@onready var _combat_system: CombatSystem = $Systems/CombatSystem
@onready var _player: Player = $Arena/Player
@onready var _enemies_container: Node2D = $Arena/Enemies
@onready var _effects_container: Node2D = $Arena/Effects
@onready var _player_spawn: Marker2D = $Arena/PlayerSpawn


func _ready() -> void:
	assert(_wave_manager, "Main: WaveManager not found")
	assert(_upgrade_pool, "Main: UpgradePool not found")
	assert(_player, "Main: Player not found")

	EventBus.run_ended.connect(_on_run_ended)

	await get_tree().process_frame
	_start_run()


func restart_run() -> void:
	_start_run()


func _start_run() -> void:
	Engine.time_scale = 1.0

	# Clear leftover enemies and projectiles from previous run
	for child in _enemies_container.get_children():
		child.queue_free()
	for child in _effects_container.get_children():
		child.queue_free()

	_player.global_position = _player_spawn.global_position
	_player.health.reset()
	_player.health.set_invincible(1.0)  # 1s spawn protection
	_upgrade_pool.reset()
	if _combat_system:
		_combat_system.reset_ammo()
	_wave_manager.start_run()


func _on_run_ended() -> void:
	pass  # GameOverUI handles display and restart
