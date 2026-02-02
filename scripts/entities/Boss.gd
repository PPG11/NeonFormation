extends Area2D

signal boss_died(amount: int, pos: Vector2)

enum State { HOVER, ATTACK_SPREAD, ATTACK_LASER, ATTACK_DASH }

@export var speed: float = 100.0
@export var max_hp: int = 500
var current_hp: int

var _state: State = State.HOVER
var _target_pos: Vector2
var _move_direction: int = 1
var _attack_timer: Timer
var _state_timer: Timer
var _base_modulate: Color

@onready var balance: GameBalance = get_node("/root/GameBalance") as GameBalance
const BulletScene: PackedScene = preload("res://scenes/entities/Bullet.tscn")

func _ready() -> void:
    max_hp = balance.boss_base_hp
    current_hp = max_hp
    add_to_group("enemy")
    add_to_group("enemy_team")
    monitoring = true
    _base_modulate = modulate

    _attack_timer = Timer.new()
    _attack_timer.one_shot = true
    add_child(_attack_timer)

    _state_timer = Timer.new()
    _state_timer.one_shot = true
    add_child(_state_timer)
    _state_timer.timeout.connect(_on_state_timeout)

    _change_state(State.HOVER)

    body_entered.connect(_on_body_entered)
    area_entered.connect(_on_area_entered)

    global_position = Vector2(180, -100) # Start off screen

func _process(delta: float) -> void:
    match _state:
        State.HOVER:
            # Hover at y=100 and strafe
            var target_y = 100.0
            var move_speed = speed

            # Strafe logic
            global_position.x += _move_direction * move_speed * delta
            if global_position.x > 310: _move_direction = -1
            if global_position.x < 50: _move_direction = 1

            # Move to Y
            global_position.y = move_toward(global_position.y, target_y, move_speed * delta)

        State.ATTACK_DASH:
             # Dash downwards or towards player
             global_position = global_position.move_toward(_target_pos, speed * 3.0 * delta)
             if global_position.distance_to(_target_pos) < 10.0:
                 _change_state(State.HOVER)

func _change_state(new_state: State) -> void:
    _state = new_state
    match _state:
        State.HOVER:
            _state_timer.start(3.0)
        State.ATTACK_SPREAD:
            _fire_spread()
            _state_timer.start(1.0)
        State.ATTACK_LASER:
            _fire_laser()
            _state_timer.start(2.0)
        State.ATTACK_DASH:
            var player = get_tree().get_first_node_in_group("player_team")
            if player:
                _target_pos = player.global_position
            else:
                _target_pos = Vector2(180, 600)
            # Extrapolate slightly? No, just dash
            _target_pos = _target_pos + (_target_pos - global_position).normalized() * 100.0
            _state_timer.start(2.0)

func _on_state_timeout() -> void:
    # Pick next state
    var states = [State.ATTACK_SPREAD, State.ATTACK_LASER, State.ATTACK_DASH]
    if _state != State.HOVER:
        _change_state(State.HOVER)
    else:
        _change_state(states.pick_random())

func _fire_spread() -> void:
    if BulletScene == null: return
    for i in range(-2, 3): # -2, -1, 0, 1, 2
        var bullet = BulletScene.instantiate()
        bullet.set("is_enemy_bullet", true)
        bullet.set("color", Color.RED)
        bullet.set("damage", balance.enemy_bullet_damage)
        bullet.global_position = global_position
        bullet.rotation = deg_to_rad(90 + i * 15)
        get_tree().current_scene.add_child(bullet)

func _fire_laser() -> void:
    # Burst of bullets
    if BulletScene == null: return
    for i in range(5):
        var bullet = BulletScene.instantiate()
        bullet.set("is_enemy_bullet", true)
        bullet.set("color", Color.ORANGE)
        bullet.set("damage", balance.enemy_bullet_damage)
        bullet.global_position = global_position
        var player = get_tree().get_first_node_in_group("player_team")
        var angle = PI/2
        if player:
            angle = (player.global_position - global_position).angle()
        bullet.rotation = angle
        get_tree().current_scene.add_child(bullet)
        await get_tree().create_timer(0.1).timeout

func take_damage(amount: int) -> void:
    current_hp -= amount
    modulate = Color.RED
    var tween := create_tween()
    tween.tween_property(self, "modulate", _base_modulate, 0.1)
    if current_hp <= 0:
        die()

func die() -> void:
    emit_signal("boss_died", 100, global_position)
    queue_free()

func _on_body_entered(body: Node) -> void:
    if body is CharacterBody2D and body.has_method("die"):
        body.call("die")

func _on_area_entered(area: Area2D) -> void:
    # SnakeBody hits boss
    if area.get_script() and area.get_script().resource_path.contains("SnakeBody.gd"):
         area.queue_free()
         take_damage(5)

func _draw() -> void:
    draw_circle(Vector2.ZERO, 30.0, Color.DARK_RED)
    draw_line(Vector2(-20, -10), Vector2(-10, 5), Color.BLACK, 3.0)
    draw_line(Vector2(20, -10), Vector2(10, 5), Color.BLACK, 3.0)
