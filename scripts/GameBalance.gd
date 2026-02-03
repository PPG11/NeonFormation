extends Node

# ==================== Player ====================
@export_group("Player")
@export var player_max_hp: int = 10
@export var player_main_damage: int = 8
@export var player_shoot_interval: float = 0.2

# ==================== Snake Body ====================
@export_group("SnakeBody")
@export var unit_price: int = 100
@export var striker_damage: int = 8
@export var striker_interval: float = 0.05
@export var striker_crit_chance: float = 0.15
@export var heavy_damage: int = 25
@export var heavy_interval: float = 1.0
@export var heavy_scale: float = 2.0
@export var spread_damage: int = 12
@export var spread_interval: float = 0.5

# Synergy buff
@export var synergy_striker_threshold: int = 2
@export var synergy_striker_attack_speed_low: float = 1.5
@export var synergy_striker_attack_speed_high: float = 2.0
@export var synergy_heavy_threshold: int = 2
@export var synergy_heavy_damage_mult: float = 1.5
@export var synergy_spread_threshold: int = 2
@export var synergy_spread_size_mult: float = 1.5

# Movement
@export var snake_speed: float = 450.0
@export var snake_keep_distance: float = 20.0

# ==================== Enemy ====================
@export_group("Enemy")
@export var enemy_base_hp: int = 60
@export var enemy_hp_per_wave: int = 15
@export var enemy_hp_exponent: float = 1.15
@export var enemy_base_speed: float = 100.0
@export var enemy_speed_per_wave: float = 5.0
@export var enemy_speed_exponent: float = 1.02
@export var enemy_base_damage: int = 10
@export var enemy_damage_per_wave: int = 2
@export var enemy_damage_exponent: float = 1.1
@export var enemy_bullet_damage: int = 15
@export var shooter_fire_interval: float = 1.2

# ==================== Boss ====================
@export_group("Boss")
@export var boss_base_hp: int = 2000
@export var boss_hp_per_wave: int = 500

# ==================== Wave ====================
@export_group("Wave")
@export var wave_base_enemies: int = 10
@export var wave_enemies_per_wave: int = 5
@export var spawn_interval: float = 1.0
@export var spawn_padding: float = 20.0
@export var gold_per_kill: int = 5

# ==================== Invincibility ====================
@export var invincibility_duration: float = 1.0

# ==================== Screen Shake ====================
@export var shake_decay: float = 5.0
