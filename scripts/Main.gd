extends Node

const EnemyScene: PackedScene = preload("res://scenes/entities/Enemy.tscn")
const PlayerScene: PackedScene = preload("res://scenes/entities/Player.tscn")
const ShopUIScene: PackedScene = preload("res://scenes/ui/ShopUI.tscn")
const ExplosionScene: PackedScene = preload("res://scenes/effects/Explosion.tscn")
const EnemyScript: Script = preload("res://scripts/entities/Enemy.gd")
const SnakeBodyScript: Script = preload("res://scripts/entities/SnakeBody.gd")
const BossScene: PackedScene = preload("res://scenes/entities/Boss.tscn")

@export var spawn_interval: float = 1.0
@export var spawn_padding: float = 20.0

var current_wave: int = 1
var gold: int = 0
var enemies_to_spawn: int = 10
var enemies_alive: int = 0

var _spawn_timer: Timer
var _player: Node2D
var _shop_ui: CanvasLayer
var _active_boss: Area2D = null
@onready var _camera: Camera2D = $Camera2D
@onready var _wave_label: Label = $CanvasLayer/WaveLabel
@onready var _gold_label: Label = $CanvasLayer/GoldLabel
@onready var _hp_bar: ProgressBar = $CanvasLayer/HPBar
@onready var _boss_hp_bar: ProgressBar = $CanvasLayer/BossHPBar
@onready var balance: GameBalance = get_node("/root/GameBalance") as GameBalance

var shake_strength: float = 0.0
var shake_decay: float = 5.0

func _ready() -> void:
    spawn_interval = balance.spawn_interval
    spawn_padding = balance.spawn_padding
    enemies_to_spawn = balance.wave_base_enemies
    shake_decay = balance.shake_decay

    if PlayerScene != null:
        _player = PlayerScene.instantiate() as Node2D
        if _player != null:
            add_child(_player)
            _player.position = Vector2(180.0, 550.0)

    if ShopUIScene != null:
        _shop_ui = ShopUIScene.instantiate() as CanvasLayer
        if _shop_ui != null:
            add_child(_shop_ui)
            if _shop_ui.has_signal("upgrade_selected"):
                _shop_ui.connect("upgrade_selected", _on_upgrade_selected)

    _spawn_timer = Timer.new()
    _spawn_timer.wait_time = spawn_interval
    _spawn_timer.one_shot = false
    _spawn_timer.autostart = false
    add_child(_spawn_timer)
    _spawn_timer.timeout.connect(_on_spawn_timeout)

    start_wave()

func _process(delta: float) -> void:
    if shake_strength > 0.0 and _camera != null:
        var strength := shake_strength
        _camera.offset = Vector2(
            randf_range(-strength, strength),
            randf_range(-strength, strength)
        )
        shake_strength = lerp(shake_strength, 0.0, shake_decay * delta)
        if shake_strength < 0.05:
            shake_strength = 0.0
            _camera.offset = Vector2.ZERO
    _update_hp_bar()
    _update_boss_hp_bar()

func _update_boss_hp_bar() -> void:
    if _boss_hp_bar == null: return

    if is_instance_valid(_active_boss):
        _boss_hp_bar.visible = true
        _boss_hp_bar.max_value = float(_active_boss.max_hp)
        _boss_hp_bar.value = float(_active_boss.current_hp)
    else:
        _boss_hp_bar.visible = false

func _on_spawn_timeout() -> void:
    if enemies_to_spawn <= 0:
        _spawn_timer.stop()
        return
    if EnemyScene == null:
        return
    var enemy := EnemyScene.instantiate() as Area2D
    if enemy == null:
        return
    if enemy.has_signal("enemy_died"):
        enemy.connect("enemy_died", _on_enemy_killed)

    var hp_scaling = pow(balance.enemy_hp_scaling_factor, current_wave - 1)
    var damage_scaling = pow(balance.enemy_damage_scaling_factor, current_wave - 1)

    enemy.set("max_hp", int(balance.enemy_base_hp * hp_scaling))
    enemy.set("damage_mult", damage_scaling)
    enemy.set("speed", balance.enemy_base_speed + (current_wave * balance.enemy_speed_per_wave))
    enemy.set("enemy_type", _pick_enemy_type())
    var viewport_rect := get_viewport().get_visible_rect()
    var x := randf_range(viewport_rect.position.x + spawn_padding,
        viewport_rect.position.x + viewport_rect.size.x - spawn_padding)
    var y := viewport_rect.position.y - spawn_padding
    enemy.global_position = Vector2(x, y)
    get_tree().current_scene.add_child(enemy)
    enemies_to_spawn -= 1
    enemies_alive += 1
    if enemies_to_spawn == 0:
        _spawn_timer.stop()

func start_wave() -> void:
    _update_ui()

    if current_wave % 5 == 0:
        # Boss Wave
        enemies_to_spawn = 0
        enemies_alive = 1
        var boss = BossScene.instantiate() as Area2D
        if boss.has_signal("boss_died"):
            boss.connect("boss_died", _on_enemy_killed)

        var hp = balance.boss_base_hp + (balance.boss_hp_per_wave * (current_wave / 5 - 1))
        boss.set("max_hp", hp)
        get_tree().current_scene.add_child(boss)
        _active_boss = boss
        boss.tree_exiting.connect(func(): _active_boss = null)

        _spawn_timer.stop()
    else:
        enemies_to_spawn = balance.wave_base_enemies + (current_wave * balance.wave_enemies_per_wave)
        enemies_alive = 0
        _spawn_timer.start()

func _on_enemy_killed(reward_gold: int, pos: Vector2) -> void:
    gold += reward_gold
    enemies_alive = max(enemies_alive - 1, 0)
    _update_ui()
    apply_shake(5.0)
    _spawn_explosion(pos)
    if enemies_alive == 0 and enemies_to_spawn == 0:
        print("Wave Complete")
        if _shop_ui != null and _shop_ui.has_method("show_shop"):
            _shop_ui.call("show_shop", gold)

func next_wave() -> void:
    current_wave += 1
    start_wave()

func _on_upgrade_selected(unit_type: int) -> void:
    var cost = _get_unit_cost(unit_type)
    if gold >= cost:
        gold -= cost
        _update_ui()
        if _player != null and _player.has_method("add_body"):
            _player.call("add_body", unit_type)
        next_wave()

func _get_unit_cost(t: int) -> int:
    match t:
        SnakeBodyScript.ClassType.STRIKER:
            return balance.unit_cost_striker
        SnakeBodyScript.ClassType.HEAVY:
            return balance.unit_cost_heavy
        SnakeBodyScript.ClassType.SPREAD:
            return balance.unit_cost_spread
    return 0

func apply_shake(strength: float) -> void:
    shake_strength = max(shake_strength, strength)

func _spawn_explosion(pos: Vector2) -> void:
    if ExplosionScene == null:
        return
    var explosion := ExplosionScene.instantiate() as CPUParticles2D
    if explosion == null:
        return
    explosion.global_position = pos
    add_child(explosion)

func _update_ui() -> void:
    if _wave_label != null:
        _wave_label.text = "Wave: %d" % current_wave
    if _gold_label != null:
        _gold_label.text = "Gold: %d" % gold

func _update_hp_bar() -> void:
    if _hp_bar == null or _player == null:
        return
    var max_hp = _player.get("max_hp")
    var current_hp = _player.get("current_hp")
    if typeof(max_hp) == TYPE_INT or typeof(max_hp) == TYPE_FLOAT:
        _hp_bar.max_value = float(max_hp)
    if typeof(current_hp) == TYPE_INT or typeof(current_hp) == TYPE_FLOAT:
        _hp_bar.value = float(current_hp)

func _pick_enemy_type() -> int:
    if current_wave <= 1:
        return EnemyScript.EnemyType.BASIC
    if current_wave == 2:
        return EnemyScript.EnemyType.BASIC if randi_range(0, 1) == 0 else EnemyScript.EnemyType.DASHER
    var roll := randi_range(0, 2)
    if roll == 0:
        return EnemyScript.EnemyType.BASIC
    if roll == 1:
        return EnemyScript.EnemyType.DASHER
    return EnemyScript.EnemyType.SHOOTER
