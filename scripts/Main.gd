extends Node

const EnemyScene: PackedScene = preload("res://scenes/entities/Enemy.tscn")
const PlayerScene: PackedScene = preload("res://scenes/entities/Player.tscn")
const ShopUIScene: PackedScene = preload("res://scenes/ui/ShopUI.tscn")
const ExplosionScene: PackedScene = preload("res://scenes/effects/Explosion.tscn")
const EnemyScript: Script = preload("res://scripts/entities/Enemy.gd")

@export var spawn_interval: float = 1.0
@export var spawn_padding: float = 20.0

var current_wave: int = 1
var gold: int = 0
var enemies_to_spawn: int = 10
var enemies_alive: int = 0

var _spawn_timer: Timer
var _player: Node2D
var _shop_ui: CanvasLayer
@onready var _camera: Camera2D = $Camera2D
@onready var _wave_label: Label = $CanvasLayer/WaveLabel
@onready var _gold_label: Label = $CanvasLayer/GoldLabel

var shake_strength: float = 0.0
var shake_decay: float = 5.0

func _ready() -> void:
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
    enemy.set("max_hp", 30 + (current_wave * 10))
    enemy.set("speed", 100 + (current_wave * 5))
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
    enemies_to_spawn = 10 + (current_wave * 5)
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
            _shop_ui.call("show_shop")

func next_wave() -> void:
    current_wave += 1
    start_wave()

func _on_upgrade_selected(unit_type: int) -> void:
    if _player != null and _player.has_method("add_body"):
        _player.call("add_body", unit_type)
    next_wave()

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
