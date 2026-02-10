extends Area2D

enum ClassType { STRIKER, HEAVY, SPREAD, BURST, LASER, RICOCHET, CHARGE, SHIELD, SUPPORT }

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

# Team shield
var _team_shield_amount: int = 0
var _shield_visual_alpha: float = 0.0

# Burst-specific variables
var _burst_count: int = 0
var _burst_max: int = 3
var _is_bursting: bool = false
var _burst_cooldown_mult: float = 1.0

# Laser-specific variables
var _laser_target: Node2D = null
var _laser_duration: float = 0.3
var _laser_elapsed: float = 0.0
var _is_lasering: bool = false
var _laser_line: Line2D = null
var _laser_duration_bonus: float = 0.0
var _laser_damage_mult: float = 1.0

# Ricochet-specific variables
var _ricochet_max_bounces: int = 2
var _ricochet_range: float = 150.0

# Charge-specific variables
var _charge_counter: int = 0
var _charge_shots_needed: int = 3

# Shield-specific variables
var _shield_gen_timer: Timer = null
var _shield_absorption: int = 20
var _shield_gen_interval_mult: float = 1.0
var _shield_aura_angle: float = 0.0

# Support-specific variables
var _support_buff_timer: Timer = null
var _support_attack_speed_buff: float = 0.15
var _support_buff_targets: int = 2
var _support_buff_lines: Array[Dictionary] = []
var _buff_pulse_time: float = 0.0

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

    # Setup Laser line
    if unit_type == ClassType.LASER:
        _laser_line = Line2D.new()
        _laser_line.width = 2.0
        _laser_line.default_color = Color.RED
        _laser_line.visible = false
        add_child(_laser_line)

    # Setup Shield generator timer
    if unit_type == ClassType.SHIELD:
        _shield_gen_timer = Timer.new()
        _shield_gen_timer.wait_time = balance.shield_gen_interval
        _shield_gen_timer.one_shot = false
        _shield_gen_timer.autostart = true
        add_child(_shield_gen_timer)
        _shield_gen_timer.timeout.connect(_on_shield_gen_timeout)

    # Setup Support buff timer
    if unit_type == ClassType.SUPPORT:
        _support_buff_timer = Timer.new()
        _support_buff_timer.wait_time = balance.support_buff_interval
        _support_buff_timer.one_shot = false
        _support_buff_timer.autostart = true
        add_child(_support_buff_timer)
        _support_buff_timer.timeout.connect(_on_support_buff_timeout)

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
    add_child(_hp_bar)

func _physics_process(delta: float) -> void:
    if target == null:
        return
    var to_target := target.global_position - global_position
    var dist := to_target.length()
    if dist > keep_distance:
        var desired_pos := target.global_position - to_target.normalized() * keep_distance
        global_position = global_position.move_toward(desired_pos, speed * delta)

    # Update Shield aura rotation
    if unit_type == ClassType.SHIELD:
        _shield_aura_angle += delta * 2.0
        if _shield_aura_angle > TAU:
            _shield_aura_angle -= TAU

    # Update Support buff pulse
    if unit_type == ClassType.SUPPORT:
        _buff_pulse_time += delta * 3.0
        if _buff_pulse_time > TAU:
            _buff_pulse_time -= TAU

    # Update team shield visual
    if _team_shield_amount > 0:
        _shield_visual_alpha = min(_shield_visual_alpha + delta * 3.0, 1.0)
    else:
        _shield_visual_alpha = max(_shield_visual_alpha - delta * 2.0, 0.0)

    queue_redraw()

    # Handle laser continuous damage
    if _is_lasering and _laser_target != null:
        _laser_elapsed += delta
        if _laser_elapsed >= 0.05:  # Tick every 0.05s
            _laser_elapsed = 0.0
            _apply_laser_damage()
        # Update laser line visual
        if _laser_line != null and is_instance_valid(_laser_target):
            _laser_line.clear_points()
            _laser_line.add_point(Vector2.ZERO)
            _laser_line.add_point(to_local(_laser_target.global_position))
            _laser_line.visible = true
        else:
            _stop_laser()

func _draw() -> void:
    # Draw team shield if active
    if _shield_visual_alpha > 0.0:
        var shield_color := Color(0.3, 0.7, 1.0, 0.2 * _shield_visual_alpha)
        var shield_radius := 14.0
        draw_circle(Vector2.ZERO, shield_radius, shield_color)
        # Shield border
        var border_color := Color(0.5, 0.8, 1.0, 0.5 * _shield_visual_alpha)
        draw_arc(Vector2.ZERO, shield_radius, 0, TAU, 24, border_color, 1.5)

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
        ClassType.BURST:
            # Triple-star shape
            draw_arc(Vector2(-6.0, -3.0), 3.0, 0.0, TAU, 12, Color.ORANGE, 2.0)
            draw_arc(Vector2(6.0, -3.0), 3.0, 0.0, TAU, 12, Color.ORANGE, 2.0)
            draw_arc(Vector2(0.0, 6.0), 3.0, 0.0, TAU, 12, Color.ORANGE, 2.0)
        ClassType.LASER:
            # Crossed dual lines
            draw_line(Vector2(-8.0, -8.0), Vector2(8.0, 8.0), Color.RED, 2.0)
            draw_line(Vector2(8.0, -8.0), Vector2(-8.0, 8.0), Color.RED, 2.0)
        ClassType.RICOCHET:
            # Diamond shape
            var p1 := Vector2(0.0, -10.0)
            var p2 := Vector2(-7.0, 0.0)
            var p3 := Vector2(0.0, 10.0)
            var p4 := Vector2(7.0, 0.0)
            var points: PackedVector2Array = [p1, p2, p3, p4, p1]
            draw_polyline(points, Color(0.75, 0.75, 0.75), 2.0)  # Silver
        ClassType.CHARGE:
            # Circle with lightning center
            draw_arc(Vector2.ZERO, 8.0, 0.0, TAU, 24, Color(0.5, 0.9, 1.0), 2.0)  # Cyan-white
            # Lightning bolt indicator
            var charge_progress := float(_charge_counter) / float(_charge_shots_needed)
            if charge_progress > 0.0:
                var bolt_color := Color(1.0, 1.0, 0.0, 0.5 + charge_progress * 0.5)
                draw_line(Vector2(0, -4), Vector2(-2, 0), bolt_color, 2.0)
                draw_line(Vector2(-2, 0), Vector2(2, 2), bolt_color, 2.0)
                draw_line(Vector2(2, 2), Vector2(0, 4), bolt_color, 2.0)
        ClassType.SHIELD:
            # Hexagon shield with rotating aura
            var hex_points: PackedVector2Array = []
            for i in range(7):
                var angle := (TAU / 6.0) * i
                hex_points.append(Vector2(cos(angle), sin(angle)) * 8.0)
            draw_polyline(hex_points, Color(0.3, 0.5, 1.0), 2.0)  # Blue

            # Rotating shield aura (3 arcs)
            for i in range(3):
                var arc_angle := _shield_aura_angle + (TAU / 3.0) * i
                var start := arc_angle
                var end := arc_angle + PI / 3.0
                draw_arc(Vector2.ZERO, 12.0, start, end, 8, Color(0.5, 0.7, 1.0, 0.6), 2.0)

            # Inner glow
            draw_circle(Vector2.ZERO, 4.0, Color(0.3, 0.5, 1.0, 0.3))
        ClassType.SUPPORT:
            # Star/cross shape with pulse effect
            var pulse := 0.5 + sin(_buff_pulse_time) * 0.5
            var gold_color := Color(1.0, 0.84, 0.0, 0.8 + pulse * 0.2)

            draw_line(Vector2(0, -10), Vector2(0, 10), gold_color, 3.0)  # Gold
            draw_line(Vector2(-10, 0), Vector2(10, 0), gold_color, 3.0)
            draw_line(Vector2(-7, -7), Vector2(7, 7), gold_color, 2.5)
            draw_line(Vector2(7, -7), Vector2(-7, 7), gold_color, 2.5)

            # Stronger pulsing aura
            var aura_radius := 14.0 + pulse * 4.0
            draw_arc(Vector2.ZERO, aura_radius, 0, TAU, 24, Color(1.0, 0.84, 0.0, 0.4 + pulse * 0.3), 2.0)

            # Draw enhanced buff lines to targets
            for buff_info in _support_buff_lines:
                if is_instance_valid(buff_info.get("target")):
                    var target_node = buff_info.get("target") as Node2D
                    var to_target := to_local(target_node.global_position)

                    # Strong pulsing gold line
                    var line_alpha := 0.6 + pulse * 0.4
                    draw_line(Vector2.ZERO, to_target, Color(1.0, 0.84, 0.0, line_alpha), 3.0)

                    # Add glow effect with outer line
                    var glow_alpha := 0.3 + pulse * 0.2
                    draw_line(Vector2.ZERO, to_target, Color(1.0, 1.0, 0.5, glow_alpha), 5.0)

                    # Add particles effect at connection points
                    var mid_point := to_target * 0.5
                    var particle_alpha := 0.5 + pulse * 0.5
                    draw_circle(mid_point, 3.0 + pulse * 2.0, Color(1.0, 0.9, 0.2, particle_alpha))

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
        ClassType.BURST:
            _handle_burst()
        ClassType.LASER:
            _handle_laser()
        ClassType.RICOCHET:
            _handle_ricochet()
        ClassType.CHARGE:
            _handle_charge()
        ClassType.SHIELD:
            _handle_shield()
        ClassType.SUPPORT:
            pass  # Support uses separate timer

func _spawn_bullet(bullet_color: Color, damage: int, scale_factor: float, angle_deg: float) -> void:
    var bullet := BulletScene.instantiate() as Area2D
    if bullet == null:
        return

    var final_damage: int = int(damage * _damage_mult)

    # Critical hit logic for STRIKER
    if unit_type == ClassType.STRIKER:
        if randf() < 0.2: # 20% critical hit chance
            final_damage *= 2
            bullet_color = Color.WHITE # Visual feedback: bright white bullet
            scale_factor *= 1.5 # Visual feedback: larger bullet

    bullet.set("color", bullet_color)
    bullet.set("damage", final_damage)
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
        ClassType.BURST:
            return balance.burst_shot_interval if _is_bursting else balance.burst_cooldown
        ClassType.LASER:
            return balance.laser_fire_interval
        ClassType.RICOCHET:
            return balance.ricochet_interval
        ClassType.CHARGE:
            return balance.charge_normal_interval
        ClassType.SHIELD:
            return balance.shield_interval
        ClassType.SUPPORT:
            return 999.0  # Support doesn't fire bullets
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
    # Try to use team shield first
    var player := get_tree().get_first_node_in_group("player_team")
    if player != null and player.has_method("consume_team_shield"):
        var absorbed: int = player.call("consume_team_shield", amount)
        if absorbed > 0:
            amount -= absorbed
            # Visual feedback for shield hit
            modulate = Color(0.5, 0.8, 1.0, 1.2)
            var shield_tween := create_tween()
            shield_tween.tween_property(self, "modulate", Color.WHITE if level == 1 else Color(1.5, 1.5, 1.5), 0.2)

            if amount <= 0:
                return  # All damage absorbed

    # Take remaining damage to HP
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

func update_team_shield(shield_amount: int) -> void:
    _team_shield_amount = shield_amount

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

    # Apply class-specific synergies
    if unit_type == ClassType.BURST:
        _burst_max = int(bonuses.get("burst_shots", 3))
        _burst_cooldown_mult = float(bonuses.get("burst_cooldown_mult", 1.0))

    if unit_type == ClassType.LASER:
        _laser_duration_bonus = float(bonuses.get("laser_duration_bonus", 0.0))
        _laser_damage_mult = float(bonuses.get("laser_damage_mult", 1.0))

    if unit_type == ClassType.RICOCHET:
        _ricochet_max_bounces = int(bonuses.get("ricochet_bounces", 2))
        _ricochet_range = balance.ricochet_range * float(bonuses.get("ricochet_range_mult", 1.0))

    if unit_type == ClassType.CHARGE:
        _charge_shots_needed = int(bonuses.get("charge_shots_needed", 3))

    if unit_type == ClassType.SHIELD:
        _shield_absorption = int(balance.shield_absorption * float(bonuses.get("shield_absorption_mult", 1.0)))
        _shield_gen_interval_mult = float(bonuses.get("shield_gen_interval_mult", 1.0))
        if _shield_gen_timer != null:
            _shield_gen_timer.wait_time = balance.shield_gen_interval * _shield_gen_interval_mult

    if unit_type == ClassType.SUPPORT:
        _support_attack_speed_buff = balance.support_attack_speed_buff * float(bonuses.get("support_buff_mult", 1.0))
        _support_buff_targets = balance.support_buff_targets
        if float(bonuses.get("support_damage_bonus", 0.0)) > 0.0:
            _support_buff_targets += 1  # Also buff player at 3x support

    if _shoot_timer != null:
        _shoot_timer.wait_time = _get_shoot_interval() / _attack_speed

# ==================== BURST ====================
func _handle_burst() -> void:
    if not _is_bursting:
        # Start burst mode
        _is_bursting = true
        _burst_count = 0

    # Fire a bullet
    _spawn_bullet(Color.ORANGE, balance.burst_damage, 1.0, 0.0)
    _burst_count += 1

    # Check if burst is complete
    if _burst_count >= _burst_max:
        _is_bursting = false
        _burst_count = 0
        # Switch to cooldown interval (with synergy reduction)
        _shoot_timer.wait_time = (balance.burst_cooldown * _burst_cooldown_mult) / _attack_speed
    else:
        # Continue burst with short interval
        _shoot_timer.wait_time = balance.burst_shot_interval / _attack_speed

# ==================== LASER ====================
func _handle_laser() -> void:
    if _is_lasering:
        _stop_laser()
        return

    # Find nearest enemy
    var enemies := get_tree().get_nodes_in_group("enemy_team")
    if enemies.is_empty():
        return

    var nearest: Node2D = null
    var min_dist := INF
    for enemy in enemies:
        if not is_instance_valid(enemy) or not enemy is Node2D:
            continue
        var dist := global_position.distance_to(enemy.global_position)
        if dist < min_dist:
            min_dist = dist
            nearest = enemy

    if nearest != null:
        _start_laser(nearest)

func _start_laser(target_enemy: Node2D) -> void:
    _laser_target = target_enemy
    _is_lasering = true
    _laser_elapsed = 0.0
    # Schedule laser stop (with synergy bonus)
    var duration := balance.laser_duration + _laser_duration_bonus
    get_tree().create_timer(duration).timeout.connect(_stop_laser)

func _stop_laser() -> void:
    _is_lasering = false
    _laser_target = null
    if _laser_line != null:
        _laser_line.visible = false
        _laser_line.clear_points()

func _apply_laser_damage() -> void:
    if _laser_target == null or not is_instance_valid(_laser_target):
        _stop_laser()
        return

    if _laser_target.has_method("take_damage"):
        var dmg := int(balance.laser_tick_damage * _damage_mult * _laser_damage_mult)
        _laser_target.call("take_damage", dmg)

# ==================== RICOCHET ====================
func _handle_ricochet() -> void:
    var bullet := BulletScene.instantiate() as Area2D
    if bullet == null:
        return
    bullet.set("color", Color(0.75, 0.75, 0.75))  # Silver
    bullet.set("damage", int(balance.ricochet_damage * _damage_mult))
    bullet.set("is_enemy_bullet", false)
    bullet.set("can_ricochet", true)
    bullet.set("max_bounces", _ricochet_max_bounces)
    bullet.set("bounce_range", _ricochet_range)
    bullet.set("damage_decay", balance.ricochet_damage_decay)
    bullet.global_position = global_position
    bullet.scale = Vector2.ONE * _size_mult
    get_tree().current_scene.add_child(bullet)

# ==================== CHARGE ====================
func _handle_charge() -> void:
    _charge_counter += 1

    if _charge_counter >= _charge_shots_needed:
        # Fire charged shot (damage multiplier is already in _damage_mult from synergy)
        _spawn_bullet(Color(1.0, 1.0, 0.0), balance.charge_charged_damage, 1.5, 0.0)  # Gold, larger
        _charge_counter = 0
    else:
        # Fire normal shot
        _spawn_bullet(Color(0.5, 0.9, 1.0), balance.charge_normal_damage, 1.0, 0.0)  # Cyan-white

    queue_redraw()  # Update charge indicator

# ==================== SHIELD ====================
func _handle_shield() -> void:
    # Shield still fires weak bullets
    _spawn_bullet(Color(0.3, 0.5, 1.0), balance.shield_damage, 1.0, 0.0)  # Blue

func _on_shield_gen_timeout() -> void:
    # Generate a shield for the player
    var player := get_tree().get_first_node_in_group("player_team")
    if player != null and player.has_method("add_shield"):
        player.call("add_shield", _shield_absorption)
        # Visual feedback - flash
        modulate = Color(0.5, 0.7, 1.0, 1.5)
        var tween := create_tween()
        tween.tween_property(self, "modulate", Color.WHITE, 0.3)

# ==================== SUPPORT ====================
func _on_support_buff_timeout() -> void:
    # Find nearest allies to buff
    var allies := get_tree().get_nodes_in_group("player_team")
    var buffed_count := 0

    # Clear old buff lines
    _support_buff_lines.clear()

    # Sort by distance
    var ally_distances: Array[Dictionary] = []
    for ally in allies:
        if not is_instance_valid(ally) or not ally is Node2D:
            continue
        if ally == self:
            continue
        var dist := global_position.distance_to(ally.global_position)
        ally_distances.append({"ally": ally, "dist": dist})

    ally_distances.sort_custom(func(a, b): return a["dist"] < b["dist"])

    # Buff the nearest allies
    for i in range(min(_support_buff_targets, ally_distances.size())):
        var ally = ally_distances[i]["ally"]
        # Store for visual line drawing
        _support_buff_lines.append({"target": ally})

        if ally.has_method("apply_support_buff"):
            ally.call("apply_support_buff", _support_attack_speed_buff, balance.support_buff_duration)
            buffed_count += 1

    # Visual feedback
    if buffed_count > 0:
        print("Support buffed ", buffed_count, " allies with +", int(_support_attack_speed_buff * 100), "% attack speed")
