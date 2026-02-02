extends Area2D

enum ClassType { STRIKER, HEAVY, SPREAD }

@export var target: Node2D
@export var speed: float = 450.0
@export var keep_distance: float = 20.0
@export var follow_offset: Vector2 = Vector2(-24.0, 12.0)
@export var unit_type: ClassType = ClassType.STRIKER : set = _set_unit_type
@export var level: int = 1 : set = _set_level

const BulletScene: PackedScene = preload("res://scenes/entities/Bullet.tscn")

var _shoot_timer: Timer
var _attack_speed: float = 1.0
var _damage_mult: float = 1.0
var _size_mult: float = 1.0
var max_hp: int = 3
var current_hp: int = 3
var _hp_bar: TextureProgressBar
@onready var balance: GameBalance = get_node("/root/GameBalance") as GameBalance

func _ready() -> void:
    max_hp = balance.snake_body_hp
    current_hp = max_hp

    speed = balance.snake_speed
    keep_distance = balance.snake_keep_distance
    add_to_group("player_team")
    area_entered.connect(_on_area_entered)

    # Create HP Bar
    _hp_bar = TextureProgressBar.new()
    _hp_bar.fill_mode = TextureProgressBar.FILL_LEFT_TO_RIGHT
    _hp_bar.value = 100
    # Create simple textures
    var width = 20
    var height = 3
    var bg_image = Image.create(width, height, false, Image.FORMAT_RGBA8)
    bg_image.fill(Color.RED)
    var progress_image = Image.create(width, height, false, Image.FORMAT_RGBA8)
    progress_image.fill(Color.GREEN)

    _hp_bar.texture_under = ImageTexture.create_from_image(bg_image)
    _hp_bar.texture_progress = ImageTexture.create_from_image(progress_image)
    _hp_bar.position = Vector2(-width/2, -20)
    add_child(_hp_bar)
    _update_hp_bar()

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

func _physics_process(delta: float) -> void:
    if not is_instance_valid(target):
        return
    var to_target := target.global_position - global_position
    var dist := to_target.length()
    if dist > keep_distance:
        var desired_pos := target.global_position - to_target.normalized() * keep_distance
        global_position = global_position.move_toward(desired_pos, speed * delta)
    queue_redraw()

func _draw() -> void:
    var color = Color.WHITE
    match unit_type:
        ClassType.STRIKER:
            color = Color.CYAN
            draw_arc(Vector2.ZERO, 8.0, 0.0, TAU, 24, color, 2.0)
        ClassType.HEAVY:
            color = Color.YELLOW
            var half := 8.0
            var rect := Rect2(Vector2(-half, -half), Vector2(half * 2.0, half * 2.0))
            draw_rect(rect, color, false, 2.0)
        ClassType.SPREAD:
            color = Color.PURPLE
            var p1 := Vector2(0.0, -10.0)
            var p2 := Vector2(-9.0, 8.0)
            var p3 := Vector2(9.0, 8.0)
            var points: PackedVector2Array = [p1, p2, p3, p1]
            draw_polyline(points, color, 2.0)

    # Visual feedback for level
    if level > 1:
        draw_circle(Vector2.ZERO, 3.0 * level, color)

func _on_shoot_timer_timeout() -> void:
    if BulletScene == null:
        return
    match unit_type:
        ClassType.STRIKER:
            var damage = balance.striker_damage
            if randf() < balance.striker_crit_chance:
                damage = int(damage * balance.striker_crit_multiplier)
            _spawn_bullet(Color.CYAN, damage, 1.0, 0.0)
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
    bullet.set("color", bullet_color)
    bullet.set("damage", int(damage * _damage_mult))
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

func _set_level(value: int) -> void:
    level = value
    queue_redraw()

func _on_area_entered(area: Area2D) -> void:
    if area.is_in_group("enemy_team"):
        current_hp -= 1
        _update_hp_bar()
        if current_hp <= 0:
            queue_free()

func _update_hp_bar() -> void:
    if _hp_bar:
        _hp_bar.max_value = float(max_hp)
        _hp_bar.value = float(current_hp)

func update_stats(bonuses: Dictionary) -> void:
    _attack_speed = float(bonuses.get("attack_speed", 1.0))
    _damage_mult = float(bonuses.get("damage_mult", 1.0))
    _size_mult = float(bonuses.get("size_mult", 1.0))

    # Apply level scaling
    var level_scaling = pow(2.0, level - 1)
    _damage_mult *= level_scaling
    max_hp = int(balance.snake_body_hp * level_scaling)
    current_hp = max_hp
    _update_hp_bar()

    if _shoot_timer != null:
        _shoot_timer.wait_time = _get_shoot_interval() / _attack_speed
