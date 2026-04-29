extends Node

# --- Health/Damage ---
signal damage_dealt(amount: float, hit_position: Vector2, attack_type: String)
signal damage_taken(amount: float, position: Vector2)
signal enemy_killed(kill_type: String, position: Vector2, enemy_color: Color)
signal player_died

# --- Wave ---
signal wave_started(wave_number: int)
signal wave_completed(wave_number: int)
signal wave_enemy_count_changed(remaining: int)
signal wave_spawn_complete(count: int, enemy_type: String)
signal upgrade_window_requested
signal run_ended

# --- Upgrade ---
signal upgrade_offered(upgrades: Array)
signal upgrade_selected(upgrade: Dictionary)
signal upgrade_applied(upgrade: Dictionary)

# --- Dodge ---
signal dodge_started
signal dodge_cooldown_changed(remaining: float)

# --- Score ---
signal score_changed(new_score: int)
signal stats_updated

# --- Player Status ---
signal health_changed(new_health: float, max_health: float)
signal weapon_changed(weapon_data: Dictionary)
