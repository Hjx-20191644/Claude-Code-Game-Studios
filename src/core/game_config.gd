extends Node

## Game configuration constants and data loading.
## All balance values are loaded from Resource files at runtime.

# --- Player Defaults ---
const PLAYER_MAX_HP: int = 100
const PLAYER_BASE_SPEED: float = 300.0
const PLAYER_HIT_INVINCIBILITY: float = 0.2
const PLAYER_DEATH_LINGER: float = 3.0

# --- Combat Defaults ---
const MELEE_ATTACK_DURATION: float = 0.2
const MELEE_KNOCKBACK_SPEED: float = 400.0
const MELEE_KNOCKBACK_DISTANCE: float = 40.0
const RANGED_AMMO_REGEN_RATE: float = 1.0
const DUAL_MELEE_ATTACK_INTERVAL: float = 0.1
const DUAL_MELEE_OVERLAP_BONUS: float = 1.2
const DUAL_RANGED_COOLDOWN_MULT: float = 1.5
const DUAL_RANGED_DAMAGE_MULT: float = 0.9

# --- Dodge Defaults ---
const DODGE_DISTANCE: float = 120.0
const DODGE_SPEED: float = 600.0
const DODGE_INVINCIBILITY: float = 0.2
const DODGE_COOLDOWN: float = 2.0

# --- Enemy Defaults ---
const ENEMY_DEATH_LINGER: float = 0.3
const CONTACT_DAMAGE_COOLDOWN: float = 0.5

# --- Arena ---
const ARENA_WIDTH: float = 1000.0
const ARENA_HEIGHT: float = 600.0

# --- Collision Layers ---
const LAYER_PLAYER: int = 1
const LAYER_ENEMIES: int = 2
const LAYER_PICKUPS: int = 3
const LAYER_PROJECTILES: int = 4
const LAYER_PLAYER_HITBOX: int = 5
const LAYER_ENEMY_HITBOX: int = 6
const LAYER_ENEMY_DETECTION: int = 7
const LAYER_WALLS: int = 8


func get_weapon_data(weapon_id: String) -> WeaponData:
	var path := "res://assets/data/weapons/%s.tres" % weapon_id
	if ResourceLoader.exists(path):
		var weapon := load(path) as WeaponData
		if weapon:
			weapon.validate()
		return weapon
	push_warning("GameConfig: Weapon data not found: %s" % weapon_id)
	return null


func get_enemy_data(enemy_id: String) -> EnemyData:
	var path := "res://assets/data/enemies/%s.tres" % enemy_id
	if ResourceLoader.exists(path):
		var enemy := load(path) as EnemyData
		if enemy:
			enemy.validate()
		return enemy
	push_warning("GameConfig: Enemy data not found: %s" % enemy_id)
	return null
