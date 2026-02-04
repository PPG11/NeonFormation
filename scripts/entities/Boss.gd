extends Area2D

signal boss_died(pos: Vector2)

enum State { ENTERING, HOVER_STRAFE, ATTACK_SPREAD, ATTACK_RAPID, DASH }

@export var max_hp: int = 2000
var current_hp: int

@onready var balance: GameBalance = get_node("/root/GameBalance") as GameBalance
const BulletScene: PackedScene = preload("res://scenes/entities/Bullet.tscn")

var _state_timer: Timer
var _shoot_timer: Timer
var _strafe_dir: int = 1
var target_y: float = 100.0
var strafe_speed: float = 200.0
var dash_speed: float = 800.0
var current_state: State = State.ENTERING
var _did_emit: bool = false
var _base_modulate: Color

func _ready() -> void:
    current_hp = max_hp
    _base_modulate = modulate
    add_to_group("enemy")
    add_to_group("enemy_team")
    monitoring = true

    _state_timer = Timer.new()
    _state_timer.one_shot = true
    add_child(_state_timer)
    _state_timer.timeout.connect(_on_state_timer_timeout)

    _shoot_timer = Timer.new()
    _shoot_timer.one_shot = false
    add_child(_shoot_timer)
    _shoot_timer.timeout.connect(_on_shoot_timer_timeout)

    _change_state(State.ENTERING)

    # Add simple collision shape programmatically if not present (though Scene usually handles this)
    if not has_node("CollisionShape2D"):
        var shape = CollisionShape2D.new()
        var rect = RectangleShape2D.new()
        rect.size = Vector2(80, 80)
        shape.shape = rect
        shape.name = "CollisionShape2D"
        add_child(shape)

func _process(delta: float) -> void:
    var viewport_rect := get_viewport_rect()

    match current_state:
        State.ENTERING:
            global_position.y = move_toward(global_position.y, target_y, 100.0 * delta)
            if abs(global_position.y - target_y) < 5.0:
                _change_state(State.HOVER_STRAFE)

        State.HOVER_STRAFE:
            global_position.x += _strafe_dir * strafe_speed * delta
            if global_position.x < 50.0:
                _strafe_dir = 1
            elif global_position.x > viewport_rect.size.x - 50.0:
                _strafe_dir = -1

        State.DASH:
             global_position.x += _strafe_dir * dash_speed * delta
             if global_position.x < 50.0:
                _strafe_dir = 1
             elif global_position.x > viewport_rect.size.x - 50.0:
                _strafe_dir = -1

    if current_state != State.ENTERING:
        global_position.y = move_toward(global_position.y, target_y, 50.0 * delta)

func _change_state(new_state: State) -> void:
    current_state = new_state
    _shoot_timer.stop()

    match new_state:
        State.HOVER_STRAFE:
            _state_timer.start(randf_range(2.0, 4.0))

        State.ATTACK_SPREAD:
            _fire_spread()
            _state_timer.start(1.0)

        State.ATTACK_RAPID:
            _shoot_timer.wait_time = 0.2
            _shoot_timer.start()
            _state_timer.start(2.0)

        State.DASH:
             _state_timer.start(1.5)

func _on_state_timer_timeout() -> void:
    match current_state:
        State.ENTERING:
            _change_state(State.HOVER_STRAFE)
        State.HOVER_STRAFE:
            var roll = randi() % 3
            if roll == 0:
                _change_state(State.ATTACK_SPREAD)
            elif roll == 1:
                _change_state(State.ATTACK_RAPID)
            else:
                _change_state(State.DASH)
        State.ATTACK_SPREAD, State.ATTACK_RAPID, State.DASH:
            _change_state(State.HOVER_STRAFE)

func _fire_spread() -> void:
    # 180 is DOWN for Bullet with UP vector
    for i in range(-2, 3):
        var angle = 180.0 + (i * 15.0)
        _spawn_bullet(angle)

func _on_shoot_timer_timeout() -> void:
    if current_state == State.ATTACK_RAPID:
        var player = get_tree().get_first_node_in_group("player_team") as Node2D
        var angle = 180.0
        if player != null:
            var dir = (player.global_position - global_position).normalized()
            # R = phi + 90
            angle = rad_to_deg(dir.angle()) + 90.0
        _spawn_bullet(angle)

func _spawn_bullet(angle_deg: float) -> void:
    if BulletScene == null: return
    var bullet = BulletScene.instantiate() as Area2D
    if bullet == null: return
    bullet.global_position = global_position
    bullet.rotation_degrees = angle_deg
    bullet.set("is_enemy_bullet", true)
    bullet.set("color", Color.RED)
    bullet.set("damage", 20)
    get_tree().current_scene.add_child(bullet)

func take_damage(amount: int) -> void:
    current_hp -= amount
    modulate = Color.RED
    var tween := create_tween()
    tween.tween_property(self, "modulate", _base_modulate, 0.1)
    if current_hp <= 0:
        die()

func die() -> void:
    if _did_emit: return
    _did_emit = true
    emit_signal("boss_died", global_position)
    queue_free()

func _draw() -> void:
    var size = 40.0
    var rect = Rect2(-size, -size, size*2, size*2)
    draw_rect(rect, Color.DARK_RED, true)
    draw_rect(rect, Color.WHITE, false, 4.0)
