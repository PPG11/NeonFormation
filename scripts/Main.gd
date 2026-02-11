extends Node

const EnemyScene: PackedScene = preload("res://scenes/entities/Enemy.tscn")
const PlayerScene: PackedScene = preload("res://scenes/entities/Player.tscn")
const ShopUIScene: PackedScene = preload("res://scenes/ui/ShopUI.tscn")
const ExplosionScene: PackedScene = preload("res://scenes/effects/Explosion.tscn")
const BossScene: PackedScene = preload("res://scenes/entities/Boss.tscn")
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
var _boss_hp_bar: ProgressBar
@onready var _camera: Camera2D = $Camera2D
@onready var _wave_label: Label = $CanvasLayer/WaveLabel
@onready var _gold_label: Label = $CanvasLayer/GoldLabel
@onready var _hp_bar: ProgressBar = $CanvasLayer/HPBar
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
            if _shop_ui.has_signal("item_purchased"):
                _shop_ui.item_purchased.connect(_on_item_purchased)
            if _shop_ui.has_signal("shop_closed"):
                _shop_ui.shop_closed.connect(_on_shop_closed)

    _boss_hp_bar = ProgressBar.new()
    _boss_hp_bar.visible = false
    _boss_hp_bar.size = Vector2(240, 20)
    _boss_hp_bar.position = Vector2(60, 80)
    _boss_hp_bar.modulate = Color.RED
    $CanvasLayer.add_child(_boss_hp_bar)

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

    if _boss_hp_bar.visible:
        var bosses = get_tree().get_nodes_in_group("enemy")
        if bosses.size() > 0:
            var b = bosses[0]
            if "current_hp" in b:
                _boss_hp_bar.value = b.current_hp

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

    var hp_val = (balance.enemy_base_hp + (current_wave * balance.enemy_hp_per_wave)) * pow(balance.enemy_hp_exponent, max(0, current_wave - 1))
    enemy.set("max_hp", int(hp_val))

    var speed_val = (balance.enemy_base_speed + (current_wave * balance.enemy_speed_per_wave)) * pow(balance.enemy_speed_exponent, max(0, current_wave - 1))
    enemy.set("speed", speed_val)

    var damage_val = balance.enemy_bullet_damage * pow(balance.enemy_damage_exponent, max(0, current_wave - 1))
    enemy.set("damage", int(damage_val))

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
        _spawn_boss_wave()
        return

    enemies_to_spawn = balance.wave_base_enemies + (current_wave * balance.wave_enemies_per_wave)
    enemies_alive = 0
    _spawn_timer.start()

func _spawn_boss_wave() -> void:
    if BossScene == null: return
    var boss = BossScene.instantiate()
    var hp = balance.boss_base_hp + ((current_wave / 5) * balance.boss_hp_per_wave)
    boss.max_hp = hp
    boss.current_hp = hp
    boss.global_position = Vector2(180, -50)
    get_tree().current_scene.add_child(boss)
    boss.boss_died.connect(_on_boss_killed)

    _boss_hp_bar.max_value = hp
    _boss_hp_bar.value = hp
    _boss_hp_bar.visible = true

    enemies_to_spawn = 0
    enemies_alive = 1

func _on_boss_killed(pos: Vector2) -> void:
    _boss_hp_bar.visible = false
    _on_enemy_killed(500, pos)

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

func _on_item_purchased(unit_type: int, cost: int) -> void:
    # 商店已经扣除了金币，这里只需要同步并添加单位
    gold -= cost
    _update_ui()
    if _player != null and _player.has_method("add_body"):
        _player.call("add_body", unit_type)

func _on_shop_closed() -> void:
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
