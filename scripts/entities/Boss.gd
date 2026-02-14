extends Area2D

signal boss_died(pos: Vector2)

enum State { ENTERING, HOVER_STRAFE, ATTACK_SPREAD, ATTACK_RAPID, DASH, ATTACK_CIRCLE, ATTACK_LASER, SUMMON_MINIONS }
enum Phase { PHASE_1, PHASE_2, PHASE_3 }

@export var max_hp: int = 2000
var current_hp: int

@onready var balance: GameBalance = get_node("/root/GameBalance") as GameBalance
const BulletScene: PackedScene = preload("res://scenes/entities/Bullet.tscn")
const EnemyScene: PackedScene = preload("res://scenes/entities/Enemy.tscn")

var _state_timer: Timer
var _shoot_timer: Timer
var _strafe_dir: int = 1
var target_y: float = 100.0
var strafe_speed: float = 150.0
var dash_speed: float = 600.0
var current_state: State = State.ENTERING
var _did_emit: bool = false
var _base_modulate: Color
var current_phase: Phase = Phase.PHASE_1
var _laser_particles: CPUParticles2D
var _aura_particles: CPUParticles2D
var _circle_bullet_count: int = 0

func _ready() -> void:
    current_hp = max_hp
    _base_modulate = modulate
    add_to_group("enemy")
    add_to_group("enemy_team")
    add_to_group("boss")
    monitoring = true

    _state_timer = Timer.new()
    _state_timer.one_shot = true
    add_child(_state_timer)
    _state_timer.timeout.connect(_on_state_timer_timeout)

    _shoot_timer = Timer.new()
    _shoot_timer.one_shot = false
    add_child(_shoot_timer)
    _shoot_timer.timeout.connect(_on_shoot_timer_timeout)

    _setup_particles()
    _change_state(State.ENTERING)

    # Add simple collision shape programmatically if not present (though Scene usually handles this)
    if not has_node("CollisionShape2D"):
        var shape = CollisionShape2D.new()
        var rect = RectangleShape2D.new()
        rect.size = Vector2(80, 80)
        shape.shape = rect
        shape.name = "CollisionShape2D"
        add_child(shape)

func _setup_particles() -> void:
    # 光环粒子效果
    _aura_particles = CPUParticles2D.new()
    _aura_particles.amount = 20
    _aura_particles.lifetime = 1.0
    _aura_particles.emission_shape = CPUParticles2D.EMISSION_SHAPE_SPHERE
    _aura_particles.emission_sphere_radius = 50.0
    _aura_particles.direction = Vector2(0, -1)
    _aura_particles.spread = 180.0
    _aura_particles.gravity = Vector2(0, -20)
    _aura_particles.initial_velocity_min = 20.0
    _aura_particles.initial_velocity_max = 40.0
    _aura_particles.scale_amount_min = 2.0
    _aura_particles.scale_amount_max = 4.0
    _aura_particles.color = Color.DARK_RED
    add_child(_aura_particles)
    _aura_particles.emitting = true
    
    # 激光粒子效果
    _laser_particles = CPUParticles2D.new()
    _laser_particles.amount = 30
    _laser_particles.lifetime = 0.3
    _laser_particles.emission_shape = CPUParticles2D.EMISSION_SHAPE_SPHERE
    _laser_particles.emission_sphere_radius = 20.0
    _laser_particles.direction = Vector2(1, 0)
    _laser_particles.spread = 10.0
    _laser_particles.gravity = Vector2.ZERO
    _laser_particles.initial_velocity_min = 200.0
    _laser_particles.initial_velocity_max = 300.0
    _laser_particles.scale_amount_min = 3.0
    _laser_particles.scale_amount_max = 5.0
    _laser_particles.color = Color.ORANGE_RED
    add_child(_laser_particles)
    _laser_particles.emitting = false

func _process(delta: float) -> void:
    var viewport_rect := get_viewport_rect()
    
    # 更新阶段
    _update_phase()

    match current_state:
        State.ENTERING:
            global_position.y = move_toward(global_position.y, target_y, 100.0 * delta)
            if abs(global_position.y - target_y) < 5.0:
                _change_state(State.HOVER_STRAFE)

        State.HOVER_STRAFE:
            var speed_mult = 1.0
            if current_phase == Phase.PHASE_2:
                speed_mult = 1.3
            elif current_phase == Phase.PHASE_3:
                speed_mult = 1.6
            global_position.x += _strafe_dir * strafe_speed * speed_mult * delta
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
        
        State.ATTACK_LASER:
            # 激光攻击时缓慢移动
            global_position.x += _strafe_dir * strafe_speed * 0.3 * delta
            if global_position.x < 50.0:
                _strafe_dir = 1
            elif global_position.x > viewport_rect.size.x - 50.0:
                _strafe_dir = -1

    if current_state != State.ENTERING:
        global_position.y = move_toward(global_position.y, target_y, 50.0 * delta)

func _update_phase() -> void:
    var hp_percent = float(current_hp) / float(max_hp)
    var old_phase = current_phase
    
    if hp_percent > 0.66:
        current_phase = Phase.PHASE_1
    elif hp_percent > 0.33:
        current_phase = Phase.PHASE_2
    else:
        current_phase = Phase.PHASE_3
    
    # 阶段切换时的特效
    if old_phase != current_phase:
        _on_phase_change()

func _on_phase_change() -> void:
    # 屏幕震动效果（通过相机实现）
    var camera = get_viewport().get_camera_2d()
    if camera:
        var tween = create_tween()
        tween.set_loops(5)
        tween.tween_property(camera, "offset", Vector2(10, 10), 0.05)
        tween.tween_property(camera, "offset", Vector2(-10, -10), 0.05)
        tween.tween_property(camera, "offset", Vector2.ZERO, 0.05)
    
    # 更新粒子颜色
    match current_phase:
        Phase.PHASE_1:
            _aura_particles.color = Color.DARK_RED
        Phase.PHASE_2:
            _aura_particles.color = Color.PURPLE
            _aura_particles.amount = 30
        Phase.PHASE_3:
            _aura_particles.color = Color.ORANGE_RED
            _aura_particles.amount = 50
    
    # 闪烁效果
    var tween = create_tween()
    tween.tween_property(self, "modulate", Color.WHITE, 0.1)
    tween.tween_property(self, "modulate", _base_modulate, 0.1)
    tween.set_loops(3)
    
    # 更新外观
    queue_redraw()

func _change_state(new_state: State) -> void:
    current_state = new_state
    _shoot_timer.stop()
    _laser_particles.emitting = false

    match new_state:
        State.HOVER_STRAFE:
            _state_timer.start(randf_range(1.5, 3.0))

        State.ATTACK_SPREAD:
            _fire_spread()
            _state_timer.start(1.0)

        State.ATTACK_RAPID:
            var fire_rate = 0.2
            if current_phase == Phase.PHASE_2:
                fire_rate = 0.15
            elif current_phase == Phase.PHASE_3:
                fire_rate = 0.1
            _shoot_timer.wait_time = fire_rate
            _shoot_timer.start()
            _state_timer.start(2.5)

        State.DASH:
            _state_timer.start(1.5)
        
        State.ATTACK_CIRCLE:
            _circle_bullet_count = 0
            _shoot_timer.wait_time = 0.15
            _shoot_timer.start()
            _state_timer.start(2.0)
        
        State.ATTACK_LASER:
            _laser_particles.emitting = true
            _shoot_timer.wait_time = 0.05
            _shoot_timer.start()
            _state_timer.start(3.0)
        
        State.SUMMON_MINIONS:
            _summon_minions()
            _state_timer.start(1.5)

func _on_state_timer_timeout() -> void:
    match current_state:
        State.ENTERING:
            _change_state(State.HOVER_STRAFE)
        State.HOVER_STRAFE:
            var available_attacks = []
            available_attacks.append(State.ATTACK_SPREAD)
            available_attacks.append(State.ATTACK_RAPID)
            available_attacks.append(State.DASH)
            
            # 阶段2解锁环形弹幕
            if current_phase >= Phase.PHASE_2:
                available_attacks.append(State.ATTACK_CIRCLE)
            
            # 阶段3解锁激光和召唤
            if current_phase == Phase.PHASE_3:
                available_attacks.append(State.ATTACK_LASER)
                available_attacks.append(State.SUMMON_MINIONS)
            
            var next_state = available_attacks[randi() % available_attacks.size()]
            _change_state(next_state)
        
        State.ATTACK_SPREAD, State.ATTACK_RAPID, State.DASH, State.ATTACK_CIRCLE, State.ATTACK_LASER, State.SUMMON_MINIONS:
            _change_state(State.HOVER_STRAFE)

func _fire_spread() -> void:
    # 根据阶段增加弹幕密度
    var spread_count = 5
    var spread_angle = 15.0
    if current_phase == Phase.PHASE_2:
        spread_count = 7
        spread_angle = 12.0
    elif current_phase == Phase.PHASE_3:
        spread_count = 9
        spread_angle = 10.0
    
    var start_offset = -(spread_count / 2)
    for i in range(spread_count):
        var angle = 180.0 + ((start_offset + i) * spread_angle)
        _spawn_bullet(angle, Color.RED)

func _fire_circle() -> void:
    # 环形弹幕
    var bullet_count = 12
    if current_phase == Phase.PHASE_3:
        bullet_count = 16
    
    for i in range(bullet_count):
        var angle = 180.0 + (360.0 / bullet_count) * i + (_circle_bullet_count * 15.0)
        _spawn_bullet(angle, Color.PURPLE)

func _fire_laser() -> void:
    # 激光扫射（密集直线弹幕）
    var player = get_tree().get_first_node_in_group("player_team") as Node2D
    var base_angle = 180.0
    if player != null:
        var dir = (player.global_position - global_position).normalized()
        base_angle = rad_to_deg(dir.angle()) + 90.0
    
    # 发射三发略微分散的激光
    for offset in [-5.0, 0.0, 5.0]:
        _spawn_bullet(base_angle + offset, Color.ORANGE, 1.5)

func _summon_minions() -> void:
    if EnemyScene == null:
        return
    
    var minion_count = 2
    if current_phase == Phase.PHASE_3:
        minion_count = 3
    
    for i in range(minion_count):
        var minion = EnemyScene.instantiate() as Area2D
        if minion == null:
            continue
        
        var offset_x = (i - minion_count / 2) * 80.0
        minion.global_position = global_position + Vector2(offset_x, 40.0)
        
        # 设置为射手类型
        if minion.has_method("set"):
            minion.set("enemy_type", 1) # SHOOTER
        
        get_tree().current_scene.add_child(minion)

func _on_shoot_timer_timeout() -> void:
    match current_state:
        State.ATTACK_RAPID:
            var player = get_tree().get_first_node_in_group("player_team") as Node2D
            var angle = 180.0
            if player != null:
                var dir = (player.global_position - global_position).normalized()
                angle = rad_to_deg(dir.angle()) + 90.0
            _spawn_bullet(angle, Color.RED)
        
        State.ATTACK_CIRCLE:
            _fire_circle()
            _circle_bullet_count += 1
        
        State.ATTACK_LASER:
            _fire_laser()

func _spawn_bullet(angle_deg: float, color: Color = Color.RED, damage_mult: float = 1.0) -> void:
    if BulletScene == null: return
    var bullet = BulletScene.instantiate() as Area2D
    if bullet == null: return
    bullet.global_position = global_position
    bullet.rotation_degrees = angle_deg
    bullet.set("is_enemy_bullet", true)
    bullet.set("color", color)
    
    var base_damage = 20
    if current_phase == Phase.PHASE_2:
        base_damage = 25
    elif current_phase == Phase.PHASE_3:
        base_damage = 30
    
    bullet.set("damage", int(base_damage * damage_mult))
    get_tree().current_scene.add_child(bullet)

func take_damage(amount: int) -> void:
    current_hp -= amount
    
    modulate = Color.RED
    var tween := create_tween()
    tween.tween_property(self, "modulate", _base_modulate, 0.1)
    
    # 受伤粒子效果
    var hit_particles = CPUParticles2D.new()
    hit_particles.global_position = global_position
    hit_particles.amount = 10
    hit_particles.lifetime = 0.5
    hit_particles.one_shot = true
    hit_particles.explosiveness = 1.0
    hit_particles.emission_shape = CPUParticles2D.EMISSION_SHAPE_SPHERE
    hit_particles.emission_sphere_radius = 10.0
    hit_particles.direction = Vector2(0, -1)
    hit_particles.spread = 180.0
    hit_particles.gravity = Vector2(0, 100)
    hit_particles.initial_velocity_min = 100.0
    hit_particles.initial_velocity_max = 200.0
    hit_particles.scale_amount_min = 2.0
    hit_particles.scale_amount_max = 4.0
    hit_particles.color = Color.WHITE
    get_tree().current_scene.add_child(hit_particles)
    hit_particles.emitting = true
    await get_tree().create_timer(1.0).timeout
    hit_particles.queue_free()
    
    if current_hp <= 0:
        die()

func die() -> void:
    if _did_emit: return
    _did_emit = true
    
    # 死亡爆炸效果
    for i in range(20):
        var explosion_particles = CPUParticles2D.new()
        var random_offset = Vector2(randf_range(-30, 30), randf_range(-30, 30))
        explosion_particles.global_position = global_position + random_offset
        explosion_particles.amount = 30
        explosion_particles.lifetime = 1.0
        explosion_particles.one_shot = true
        explosion_particles.explosiveness = 1.0
        explosion_particles.emission_shape = CPUParticles2D.EMISSION_SHAPE_SPHERE
        explosion_particles.emission_sphere_radius = 20.0
        explosion_particles.direction = Vector2(0, 0)
        explosion_particles.spread = 180.0
        explosion_particles.gravity = Vector2(0, 100)
        explosion_particles.initial_velocity_min = 200.0
        explosion_particles.initial_velocity_max = 400.0
        explosion_particles.scale_amount_min = 3.0
        explosion_particles.scale_amount_max = 6.0
        var colors = [Color.RED, Color.ORANGE, Color.YELLOW, Color.WHITE]
        explosion_particles.color = colors[randi() % colors.size()]
        get_tree().current_scene.add_child(explosion_particles)
        explosion_particles.emitting = true
        
        # 延迟删除粒子
        var timer = get_tree().create_timer(2.0)
        timer.timeout.connect(explosion_particles.queue_free)
    
    # 屏幕震动
    var camera = get_viewport().get_camera_2d()
    if camera:
        var tween = create_tween()
        tween.set_loops(10)
        tween.tween_property(camera, "offset", Vector2(15, 15), 0.05)
        tween.tween_property(camera, "offset", Vector2(-15, -15), 0.05)
        tween.tween_property(camera, "offset", Vector2.ZERO, 0.05)
    
    emit_signal("boss_died", global_position)
    queue_free()

func _draw() -> void:
    var size = 40.0
    var rect = Rect2(-size, -size, size*2, size*2)
    
    # 根据阶段改变外观
    var main_color = Color.DARK_RED
    var border_color = Color.WHITE
    
    match current_phase:
        Phase.PHASE_1:
            main_color = Color.DARK_RED
            border_color = Color.WHITE
        Phase.PHASE_2:
            main_color = Color.PURPLE
            border_color = Color.LIGHT_PINK
        Phase.PHASE_3:
            main_color = Color.ORANGE_RED
            border_color = Color.YELLOW
    
    draw_rect(rect, main_color, true)
    draw_rect(rect, border_color, false, 4.0)
    
    # 绘制内部装饰
    var inner_size = size * 0.5
    var inner_rect = Rect2(-inner_size, -inner_size, inner_size*2, inner_size*2)
    draw_rect(inner_rect, border_color, false, 2.0)
    
    # 绘制X形装饰
    draw_line(Vector2(-size, -size), Vector2(size, size), border_color, 2.0)
    draw_line(Vector2(size, -size), Vector2(-size, size), border_color, 2.0)
