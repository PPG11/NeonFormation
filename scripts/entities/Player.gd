extends CharacterBody2D

@export var bullet_scene: PackedScene = preload("res://scenes/entities/Bullet.tscn")
@export var body_scene: PackedScene = preload("res://scenes/entities/SnakeBody.tscn")
@export var shoot_interval: float = 0.2

@export var max_hp: int = 10
var current_hp: int = 10
var is_invincible: bool = false

# Team shield system
var team_shield: int = 0
var _shield_visual_alpha: float = 0.0

var body_parts: Array[Node2D] = []
var class_counts: Dictionary = {}
var synergy_bonuses: Dictionary = {
    "attack_speed": 1.0,
    "damage_mult": 1.0,
    "size_mult": 1.0
}

var _shoot_timer: Timer
var _hp_bar: TextureProgressBar
const SnakeBodyScript: Script = preload("res://scripts/entities/SnakeBody.gd")
@onready var balance: GameBalance = get_node("/root/GameBalance") as GameBalance

func _ready() -> void:
    shoot_interval = balance.player_shoot_interval
    max_hp = balance.player_max_hp
    current_hp = max_hp
    add_to_group("player_team")
    _shoot_timer = Timer.new()
    _shoot_timer.wait_time = shoot_interval
    _shoot_timer.one_shot = false
    _shoot_timer.autostart = true
    add_child(_shoot_timer)
    _shoot_timer.timeout.connect(_on_shoot_timeout)

    _setup_hp_bar()

    call_deferred("_spawn_initial_bodies")

func _setup_hp_bar() -> void:
    _hp_bar = TextureProgressBar.new()

    var tex_under = GradientTexture2D.new()
    tex_under.width = 32
    tex_under.height = 4
    tex_under.fill_from = Vector2(0, 0)
    tex_under.fill_to = Vector2(0, 1)
    var grad_under = Gradient.new()
    grad_under.add_point(0.0, Color(0.2, 0.2, 0.2))
    tex_under.gradient = grad_under

    var tex_prog = GradientTexture2D.new()
    tex_prog.width = 32
    tex_prog.height = 4
    tex_prog.fill_from = Vector2(0, 0)
    tex_prog.fill_to = Vector2(0, 1)
    var grad_prog = Gradient.new()
    grad_prog.add_point(0.0, Color.GREEN)
    tex_prog.gradient = grad_prog

    _hp_bar.texture_under = tex_under
    _hp_bar.texture_progress = tex_prog
    _hp_bar.position = Vector2(-16, -24)
    add_child(_hp_bar)
    _update_floating_hp()

func _update_floating_hp() -> void:
    if _hp_bar:
        _hp_bar.max_value = max_hp
        _hp_bar.value = current_hp

func _physics_process(delta: float) -> void:
    var target := get_global_mouse_position()
    global_position = global_position.lerp(target, 0.1)

    # Update shield visual alpha
    if team_shield > 0:
        _shield_visual_alpha = min(_shield_visual_alpha + delta * 3.0, 1.0)
    else:
        _shield_visual_alpha = max(_shield_visual_alpha - delta * 2.0, 0.0)

    queue_redraw()

func _draw() -> void:
    # Draw team shield if active
    if _shield_visual_alpha > 0.0:
        var shield_color := Color(0.3, 0.7, 1.0, 0.3 * _shield_visual_alpha)
        var shield_radius := 24.0
        draw_circle(Vector2.ZERO, shield_radius, shield_color)
        # Shield border
        var border_color := Color(0.5, 0.8, 1.0, 0.6 * _shield_visual_alpha)
        draw_arc(Vector2.ZERO, shield_radius, 0, TAU, 32, border_color, 2.0)

    var p1 := Vector2(0.0, -16.0)
    var p2 := Vector2(-8.0, 10.0)
    var p3 := Vector2(8.0, 10.0)
    var points: PackedVector2Array = [p1, p2, p3, p1]
    draw_polyline(points, Color.GREEN, 2.0)

func die() -> void:
    call_deferred("_deferred_die")

func _deferred_die() -> void:
    print("Game Over")
    get_tree().reload_current_scene()

func take_damage(amount: int) -> void:
    if is_invincible:
        return

    # Shield absorbs damage first
    if team_shield > 0:
        var absorbed: int = min(team_shield, amount)
        team_shield -= absorbed
        amount -= absorbed

        # Visual feedback for shield hit
        modulate = Color(0.5, 0.8, 1.0, 1.2)
        var tween := create_tween()
        tween.tween_property(self, "modulate", Color.GREEN, 0.2)

        print("[SHIELD] Absorbed ", absorbed, " damage! Remaining: ", team_shield)

        if amount <= 0:
            return  # All damage absorbed

        print("[SHIELD] Shield broken! Taking ", amount, " damage")

    # Take remaining damage to HP
    current_hp -= amount
    _update_floating_hp()
    if current_hp <= 0:
        die()
        return
    is_invincible = true
    var tween := create_tween()
    tween.set_loops(5)
    tween.tween_property(self, "modulate:a", 0.5, 0.1)
    tween.tween_property(self, "modulate:a", 1.0, 0.1)
    var main := get_tree().current_scene
    if main != null and main.has_method("apply_shake"):
        main.call("apply_shake", 10.0)
    await get_tree().create_timer(balance.invincibility_duration).timeout
    is_invincible = false
    modulate.a = 1.0

func _on_shoot_timeout() -> void:
    if bullet_scene == null:
        return
    var bullet := bullet_scene.instantiate() as Area2D
    if bullet == null:
        return
    bullet.set("color", Color.GREEN)
    bullet.set("damage", balance.player_main_damage)
    bullet.set("is_enemy_bullet", false)
    bullet.global_position = global_position
    get_tree().current_scene.add_child(bullet)

func add_body(unit_type: int) -> void:
    _add_body_internal(unit_type, 1)

func _add_body_internal(unit_type: int, level: int, insertion_index: int = -1) -> void:
    var matching_indices = []
    for i in range(body_parts.size()):
        var part = body_parts[i]
        if part != null and part.get("unit_type") == unit_type and part.get("level") == level:
            matching_indices.append(i)
            if matching_indices.size() == 2:
                break

    if matching_indices.size() == 2:
        var idx1 = matching_indices[0]
        var idx2 = matching_indices[1]
        var target_index = min(idx1, idx2)

        matching_indices.sort()
        matching_indices.reverse()
        for idx in matching_indices:
            var part = body_parts[idx]
            body_parts.remove_at(idx)
            part.queue_free()

        _refresh_body_targets()
        _add_body_internal(unit_type, level + 1, target_index)
        return

    if body_scene == null:
        return
    var body := body_scene.instantiate() as Node2D
    if body == null:
        return

    body.set("unit_type", unit_type)
    body.set("level", level)

    get_tree().current_scene.add_child(body)

    if insertion_index >= 0 and insertion_index <= body_parts.size():
        body_parts.insert(insertion_index, body)
    else:
        body_parts.append(body)

    _refresh_body_targets()

    # Set initial position based on target (now that targets are refreshed)
    var target = body.get("target")
    if target:
        var offset := body.get("follow_offset") as Vector2
        if offset == null: offset = Vector2.ZERO
        body.global_position = target.global_transform * offset

    body.tree_exited.connect(_on_body_exited.bind(body))
    recalculate_synergies()

func _on_body_exited(body: Node) -> void:
    body_parts.erase(body)
    _refresh_body_targets()
    recalculate_synergies()

func _refresh_body_targets() -> void:
    for i in body_parts.size():
        var part := body_parts[i]
        if part == null:
            continue
        var target: Node2D = self if i == 0 else body_parts[i - 1]
        part.set("target", target)

func recalculate_synergies() -> void:
    class_counts = {
        "striker": 0,
        "heavy": 0,
        "spread": 0,
        "burst": 0,
        "laser": 0,
        "ricochet": 0,
        "charge": 0,
        "shield": 0,
        "support": 0
    }
    for part in body_parts:
        if part == null:
            continue
        var t: int = int(part.get("unit_type"))
        if t == SnakeBodyScript.ClassType.STRIKER:
            class_counts["striker"] += 1
        elif t == SnakeBodyScript.ClassType.HEAVY:
            class_counts["heavy"] += 1
        elif t == SnakeBodyScript.ClassType.SPREAD:
            class_counts["spread"] += 1
        elif t == SnakeBodyScript.ClassType.BURST:
            class_counts["burst"] += 1
        elif t == SnakeBodyScript.ClassType.LASER:
            class_counts["laser"] += 1
        elif t == SnakeBodyScript.ClassType.RICOCHET:
            class_counts["ricochet"] += 1
        elif t == SnakeBodyScript.ClassType.CHARGE:
            class_counts["charge"] += 1
        elif t == SnakeBodyScript.ClassType.SHIELD:
            class_counts["shield"] += 1
        elif t == SnakeBodyScript.ClassType.SUPPORT:
            class_counts["support"] += 1

    synergy_bonuses["attack_speed"] = 1.0
    synergy_bonuses["damage_mult"] = 1.0
    synergy_bonuses["size_mult"] = 1.0
    synergy_bonuses["burst_shots"] = 3
    synergy_bonuses["burst_cooldown_mult"] = 1.0
    synergy_bonuses["laser_duration_bonus"] = 0.0
    synergy_bonuses["laser_damage_mult"] = 1.0
    synergy_bonuses["ricochet_bounces"] = balance.ricochet_max_bounces
    synergy_bonuses["ricochet_range_mult"] = 1.0
    synergy_bonuses["charge_shots_needed"] = balance.charge_shots_to_charge
    synergy_bonuses["charge_damage_mult"] = 1.0
    synergy_bonuses["shield_absorption_mult"] = 1.0
    synergy_bonuses["shield_gen_interval_mult"] = 1.0
    synergy_bonuses["support_buff_mult"] = 1.0
    synergy_bonuses["support_damage_bonus"] = 0.0

    if class_counts["striker"] >= 4:
        synergy_bonuses["attack_speed"] = balance.synergy_striker_attack_speed_high
    elif class_counts["striker"] >= balance.synergy_striker_threshold:
        synergy_bonuses["attack_speed"] = balance.synergy_striker_attack_speed_low

    if class_counts["heavy"] >= balance.synergy_heavy_threshold:
        synergy_bonuses["damage_mult"] = balance.synergy_heavy_damage_mult

    if class_counts["spread"] >= balance.synergy_spread_threshold:
        synergy_bonuses["size_mult"] = balance.synergy_spread_size_mult

    if class_counts["burst"] >= 3:
        synergy_bonuses["burst_cooldown_mult"] = 1.0 - balance.synergy_burst_cooldown_reduction
    if class_counts["burst"] >= balance.synergy_burst_threshold:
        synergy_bonuses["burst_shots"] = 3 + balance.synergy_burst_shots_bonus

    if class_counts["laser"] >= 3:
        synergy_bonuses["laser_damage_mult"] = balance.synergy_laser_damage_mult
    if class_counts["laser"] >= balance.synergy_laser_threshold:
        synergy_bonuses["laser_duration_bonus"] = balance.synergy_laser_duration_bonus

    if class_counts["ricochet"] >= 3:
        synergy_bonuses["ricochet_range_mult"] = balance.synergy_ricochet_range_mult
    if class_counts["ricochet"] >= balance.synergy_ricochet_threshold:
        synergy_bonuses["ricochet_bounces"] = balance.ricochet_max_bounces + balance.synergy_ricochet_bounce_bonus

    if class_counts["charge"] >= 3:
        synergy_bonuses["charge_damage_mult"] = balance.synergy_charge_damage_mult
    if class_counts["charge"] >= balance.synergy_charge_threshold:
        synergy_bonuses["charge_shots_needed"] = balance.charge_shots_to_charge - balance.synergy_charge_shots_reduction

    if class_counts["shield"] >= 3:
        synergy_bonuses["shield_gen_interval_mult"] = 1.0 - balance.synergy_shield_gen_reduction
    if class_counts["shield"] >= balance.synergy_shield_threshold:
        synergy_bonuses["shield_absorption_mult"] = balance.synergy_shield_absorption_mult

    if class_counts["support"] >= 3:
        synergy_bonuses["support_damage_bonus"] = balance.synergy_support_damage_bonus
    if class_counts["support"] >= balance.synergy_support_threshold:
        synergy_bonuses["support_buff_mult"] = balance.synergy_support_buff_mult

    print("Active Synergies: ", synergy_bonuses)
    for part in body_parts:
        if part != null and part.has_method("update_stats"):
            part.call("update_stats", synergy_bonuses)

func _spawn_initial_bodies() -> void:
    add_body(SnakeBodyScript.ClassType.STRIKER)
    add_body(SnakeBodyScript.ClassType.HEAVY)
    add_body(SnakeBodyScript.ClassType.SPREAD)
    # Add new classes for testing
    add_body(SnakeBodyScript.ClassType.BURST)
    add_body(SnakeBodyScript.ClassType.LASER)
    add_body(SnakeBodyScript.ClassType.RICOCHET)
    add_body(SnakeBodyScript.ClassType.CHARGE)
    add_body(SnakeBodyScript.ClassType.SHIELD)
    add_body(SnakeBodyScript.ClassType.SUPPORT)

func _broadcast_shield_to_team() -> void:
    # Notify all body parts to update their shield visuals
    for part in body_parts:
        if part != null and part.has_method("update_team_shield"):
            part.call("update_team_shield", team_shield)

func get_team_shield() -> int:
    return team_shield

func consume_team_shield(amount: int) -> int:
    var absorbed: int = min(team_shield, amount)
    team_shield -= absorbed
    if absorbed > 0:
        _broadcast_shield_to_team()
    return absorbed

# Add team shield (called by Shield units)
func add_shield(absorption: int) -> void:
    # Add to team shield pool
    team_shield += absorption

    # Visual feedback - blue flash
    modulate = Color(0.5, 0.7, 1.0, 1.5)
    var tween := create_tween()
    tween.tween_property(self, "modulate", Color.GREEN, 0.4)

    # Screen shake
    var main := get_tree().current_scene
    if main != null and main.has_method("apply_shake"):
        main.call("apply_shake", 5.0)

    print("[SHIELD] TEAM SHIELD: +", absorption, " (Total: ", team_shield, ")")

    # Notify all team members
    _broadcast_shield_to_team()
