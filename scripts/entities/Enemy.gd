extends Area2D

signal enemy_died(amount: int, pos: Vector2)

enum EnemyType { DASHER, SHOOTER, BASIC }

@export var speed: float = 100.0
@export var max_hp: int = 60
@export var enemy_type: EnemyType = EnemyType.BASIC : set = _set_enemy_type

var current_hp: int
var _base_modulate: Color
var _did_emit: bool = false
@onready var balance: GameBalance = get_node("/root/GameBalance") as GameBalance
const SnakeBodyScript: Script = preload("res://scripts/entities/SnakeBody.gd")
const BulletScene: PackedScene = preload("res://scenes/entities/Bullet.tscn")

var _shoot_timer: Timer

func _ready() -> void:
    speed = balance.enemy_base_speed
    max_hp = balance.enemy_base_hp
    add_to_group("enemy")
    add_to_group("enemy_team")
    monitoring = true
    current_hp = max_hp
    _base_modulate = modulate
    _shoot_timer = Timer.new()
    _shoot_timer.wait_time = balance.shooter_fire_interval
    _shoot_timer.one_shot = false
    _shoot_timer.autostart = false
    add_child(_shoot_timer)
    _shoot_timer.timeout.connect(_on_shoot_timer_timeout)
    _apply_enemy_type()
    var notifier := get_node_or_null("VisibleOnScreenNotifier2D") as VisibleOnScreenNotifier2D
    if notifier == null:
        notifier = VisibleOnScreenNotifier2D.new()
        add_child(notifier)
    notifier.screen_exited.connect(_on_screen_exited)
    body_entered.connect(_on_body_entered)
    area_entered.connect(_on_area_entered)

func _process(delta: float) -> void:
    var player := get_tree().get_first_node_in_group("player_team") as Node2D
    match enemy_type:
        EnemyType.BASIC:
            global_position += Vector2.DOWN * speed * delta
        EnemyType.DASHER:
            if player != null:
                global_position = global_position.move_toward(player.global_position, speed * delta)
            else:
                global_position += Vector2.DOWN * speed * delta
        EnemyType.SHOOTER:
            var slow_speed := speed * 0.35
            if player != null:
                global_position = global_position.move_toward(player.global_position, slow_speed * delta)
            else:
                global_position += Vector2.DOWN * slow_speed * delta

func _draw() -> void:
    match enemy_type:
        EnemyType.BASIC:
            var half := 10.0
            var rect := Rect2(Vector2(-half, -half), Vector2(half * 2.0, half * 2.0))
            draw_rect(rect, Color.RED, false, 2.0)
        EnemyType.DASHER:
            var p1 := Vector2(0.0, 12.0)
            var p2 := Vector2(-10.0, -8.0)
            var p3 := Vector2(10.0, -8.0)
            var points: PackedVector2Array = [p1, p2, p3, p1]
            draw_polyline(points, Color.RED, 2.0)
        EnemyType.SHOOTER:
            var p1 := Vector2(0.0, -12.0)
            var p2 := Vector2(10.0, 0.0)
            var p3 := Vector2(0.0, 12.0)
            var p4 := Vector2(-10.0, 0.0)
            var points: PackedVector2Array = [p1, p2, p3, p4, p1]
            draw_polyline(points, Color.PURPLE, 2.0)

func _on_screen_exited() -> void:
    _emit_enemy_died(0, global_position)
    queue_free()

func _on_body_entered(body: Node) -> void:
    if body is CharacterBody2D and body.has_method("die"):
        body.call("die")
        _emit_enemy_died(0, global_position)
        queue_free()

func _on_area_entered(area: Area2D) -> void:
    if area != null and area.get_script() == SnakeBodyScript:
        area.queue_free()
        _emit_enemy_died(0, global_position)
        queue_free()

func take_damage(amount: int) -> void:
    current_hp -= amount
    modulate = Color.RED
    var tween := create_tween()
    tween.tween_property(self, "modulate", _base_modulate, 0.1)
    if current_hp <= 0:
        die()

func die() -> void:
    print("Enemy destroyed")
    _emit_enemy_died(5, global_position)
    queue_free()

func _emit_enemy_died(amount: int, pos: Vector2) -> void:
    if _did_emit:
        return
    _did_emit = true
    emit_signal("enemy_died", amount, pos)

func _on_shoot_timer_timeout() -> void:
    if enemy_type != EnemyType.SHOOTER:
        return
    var player := get_tree().get_first_node_in_group("player_team") as Node2D
    if player == null or BulletScene == null:
        return
    var bullet := BulletScene.instantiate() as Area2D
    if bullet == null:
        return
    var dir := (player.global_position - global_position).normalized()
    if dir == Vector2.ZERO:
        dir = Vector2.DOWN
    bullet.set("is_enemy_bullet", true)
    bullet.set("color", Color.ORANGE)
    bullet.set("damage", balance.enemy_bullet_damage)
    bullet.global_position = global_position
    bullet.rotation = dir.angle() + PI / 2.0
    get_tree().current_scene.add_child(bullet)

func _set_enemy_type(value: EnemyType) -> void:
    enemy_type = value
    _apply_enemy_type()
    queue_redraw()

func _apply_enemy_type() -> void:
    if _shoot_timer == null:
        return
    if enemy_type == EnemyType.SHOOTER:
        _shoot_timer.wait_time = balance.shooter_fire_interval
        _shoot_timer.start()
    else:
        _shoot_timer.stop()
