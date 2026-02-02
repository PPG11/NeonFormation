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
@export var striker_interval: float = 0.1
@export var heavy_damage: int = 25
@export var heavy_interval: float = 1.0
@export var heavy_scale: float = 2.0
@export var spread_damage: int = 12
@export var spread_interval: float = 0.5
@export var burst_damage: int = 10
@export var burst_shot_interval: float = 0.05
@export var burst_cooldown: float = 0.8
@export var laser_tick_damage: int = 2
@export var laser_fire_interval: float = 0.6
@export var laser_duration: float = 0.3
@export var ricochet_damage: int = 10
@export var ricochet_interval: float = 0.4
@export var ricochet_max_bounces: int = 2
@export var ricochet_range: float = 150.0
@export var ricochet_damage_decay: float = 0.7
@export var charge_normal_damage: int = 5
@export var charge_charged_damage: int = 50
@export var charge_normal_interval: float = 0.3
@export var charge_shots_to_charge: int = 3
@export var shield_damage: int = 8
@export var shield_interval: float = 0.6
@export var shield_gen_interval: float = 5.0
@export var shield_absorption: int = 30
@export var support_buff_interval: float = 2.0
@export var support_buff_duration: float = 3.0
@export var support_attack_speed_buff: float = 0.30
@export var support_buff_targets: int = 3

# Synergy buff
@export var synergy_striker_threshold: int = 2
@export var synergy_striker_attack_speed_low: float = 1.5
@export var synergy_striker_attack_speed_high: float = 2.0
@export var synergy_heavy_threshold: int = 2
@export var synergy_heavy_damage_mult: float = 1.5
@export var synergy_spread_threshold: int = 2
@export var synergy_spread_size_mult: float = 1.5
@export var synergy_burst_threshold: int = 2
@export var synergy_burst_shots_bonus: int = 1
@export var synergy_burst_cooldown_reduction: float = 0.3
@export var synergy_laser_threshold: int = 2
@export var synergy_laser_duration_bonus: float = 0.2
@export var synergy_laser_damage_mult: float = 1.5
@export var synergy_ricochet_threshold: int = 2
@export var synergy_ricochet_bounce_bonus: int = 1
@export var synergy_ricochet_range_mult: float = 1.5
@export var synergy_charge_threshold: int = 2
@export var synergy_charge_shots_reduction: int = 1
@export var synergy_charge_damage_mult: float = 1.5
@export var synergy_shield_threshold: int = 2
@export var synergy_shield_absorption_mult: float = 1.5
@export var synergy_shield_gen_reduction: float = 0.3
@export var synergy_support_threshold: int = 2
@export var synergy_support_buff_mult: float = 1.67
@export var synergy_support_damage_bonus: float = 0.15

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
