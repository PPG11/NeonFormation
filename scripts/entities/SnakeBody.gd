extends Area2D

enum ClassType { STRIKER, HEAVY, SPREAD }

@export var target: Node2D
@export var speed: float = 450.0
@export var keep_distance: float = 20.0
@export var follow_offset: Vector2 = Vector2(-24.0, 12.0)
@export var unit_type: ClassType = ClassType.STRIKER : set = _set_unit_type
@export var level: int = 1

const BulletScene: PackedScene = preload("res://scenes/entities/Bullet.tscn")

var _shoot_timer: Timer
var _attack_speed: float = 1.0
var _damage_mult: float = 1.0
var _size_mult: float = 1.0
var max_hp: int = 10
var current_hp: int = 10
var _hp_bar: TextureProgressBar
@onready var balance: GameBalance = get_node("/root/GameBalance") as GameBalance

func _ready() -> void:
    speed = balance.snake_speed
    keep_distance = balance.snake_keep_distance
    add_to_group("player_team")
    area_entered.connect(_on_area_entered)

    max_hp = 10 * level
    current_hp = max_hp
    _setup_hp_bar()

    _shoot_timer = Timer.new()
    _shoot_timer.wait_time = _get_shoot_interval()
    _shoot_timer.one_shot = false
    _shoot_timer.autostart = true
    add_child(_shoot_timer)
    _shoot_timer.timeout.connect(_on_shoot_timer_timeout)
    update_stats({
        "attack_speed": 1.0,
        "damage_mult": 1.0,
        "size_mult": 1.0
    })

func _setup_hp_bar() -> void:
    _hp_bar = TextureProgressBar.new()

    var tex_under = GradientTexture2D.new()
    tex_under.width = 24
    tex_under.height = 4
    tex_under.fill_from = Vector2(0, 0)
    tex_under.fill_to = Vector2(0, 1)
    var grad_under = Gradient.new()
    grad_under.add_point(0.0, Color(0.2, 0.2, 0.2))
    tex_under.gradient = grad_under

    var tex_prog = GradientTexture2D.new()
    tex_prog.width = 24
    tex_prog.height = 4
    tex_prog.fill_from = Vector2(0, 0)
    tex_prog.fill_to = Vector2(0, 1)
    var grad_prog = Gradient.new()
    grad_prog.add_point(0.0, Color.YELLOW)
    tex_prog.gradient = grad_prog

    _hp_bar.texture_under = tex_under
    _hp_bar.texture_progress = tex_prog
    _hp_bar.position = Vector2(-12, -20)
    _hp_bar.max_value = max_hp
    _hp_bar.value = current_hp
    _hp_bar.visible = true
    add_child(_hp_bar)

func _physics_process(delta: float) -> void:
    if target == null:
        return
    var to_target := target.global_position - global_position
    var dist := to_target.length()
    if dist > keep_distance:
        var desired_pos := target.global_position - to_target.normalized() * keep_distance
        global_position = global_position.move_toward(desired_pos, speed * delta)
    queue_redraw()

func _draw() -> void:
    match unit_type:
        ClassType.STRIKER:
            draw_arc(Vector2.ZERO, 8.0, 0.0, TAU, 24, Color.CYAN, 2.0)
        ClassType.HEAVY:
            var half := 8.0
            var rect := Rect2(Vector2(-half, -half), Vector2(half * 2.0, half * 2.0))
            draw_rect(rect, Color.YELLOW, false, 2.0)
        ClassType.SPREAD:
            var p1 := Vector2(0.0, -10.0)
            var p2 := Vector2(-9.0, 8.0)
            var p3 := Vector2(9.0, 8.0)
            var points: PackedVector2Array = [p1, p2, p3, p1]
            draw_polyline(points, Color.PURPLE, 2.0)

func _on_shoot_timer_timeout() -> void:
    if BulletScene == null:
        return
    match unit_type:
        ClassType.STRIKER:
            _spawn_bullet(Color.CYAN, balance.striker_damage, 1.0, 0.0)
        ClassType.HEAVY:
            _spawn_bullet(Color.YELLOW, balance.heavy_damage, balance.heavy_scale, 0.0)
        ClassType.SPREAD:
            _spawn_bullet(Color.PURPLE, balance.spread_damage, 1.0, -15.0)
            _spawn_bullet(Color.PURPLE, balance.spread_damage, 1.0, 0.0)
            _spawn_bullet(Color.PURPLE, balance.spread_damage, 1.0, 15.0)

func _spawn_bullet(bullet_color: Color, damage: int, scale_factor: float, angle_deg: float) -> void:
    var bullet := BulletScene.instantiate() as Area2D
    if bullet == null:
        return

    var final_damage = damage * _damage_mult
    var final_color = bullet_color

    if unit_type == ClassType.STRIKER:
        if randf() < balance.striker_crit_chance:
            final_damage *= balance.striker_crit_multiplier
            final_color = Color(0.8, 1.0, 1.0) # Bright cyan/white

    bullet.set("color", final_color)
    bullet.set("damage", int(final_damage))
    bullet.set("is_enemy_bullet", false)
    bullet.global_position = global_position
    bullet.rotation = deg_to_rad(angle_deg)
    bullet.scale = Vector2.ONE * scale_factor * _size_mult
    get_tree().current_scene.add_child(bullet)

func _get_shoot_interval() -> float:
    match unit_type:
        ClassType.STRIKER:
            return balance.striker_interval
        ClassType.HEAVY:
            return balance.heavy_interval
        ClassType.SPREAD:
            return balance.spread_interval
    return 0.3

func _set_unit_type(value: ClassType) -> void:
    unit_type = value
    if _shoot_timer != null:
        _shoot_timer.wait_time = _get_shoot_interval() / _attack_speed
    queue_redraw()

func _on_area_entered(area: Area2D) -> void:
    if area.is_in_group("enemy_team"):
        take_damage(10)

func take_damage(amount: int) -> void:
    current_hp -= amount
    if _hp_bar:
        _hp_bar.value = current_hp

    modulate = Color.RED
    var tween := create_tween()
    tween.tween_callback(func():
        if level > 1:
            modulate = Color(1.5, 1.5, 1.5)
        else:
            modulate = Color.WHITE
    ).set_delay(0.1)

    if current_hp <= 0:
        queue_free()

func update_stats(bonuses: Dictionary) -> void:
    _attack_speed = float(bonuses.get("attack_speed", 1.0))
    _damage_mult = float(bonuses.get("damage_mult", 1.0))
    _size_mult = float(bonuses.get("size_mult", 1.0))

    var level_mult = pow(2.0, level - 1)
    _damage_mult *= level_mult

    scale = Vector2.ONE * (1.0 + (level - 1) * 0.3)
    if level > 1:
        modulate = Color(1.5, 1.5, 1.5)
    else:
        modulate = Color.WHITE

    if _shoot_timer != null:
        _shoot_timer.wait_time = _get_shoot_interval() / _attack_speed
