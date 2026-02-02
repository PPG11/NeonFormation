extends CharacterBody2D

@export var bullet_scene: PackedScene = preload("res://scenes/entities/Bullet.tscn")
@export var body_scene: PackedScene = preload("res://scenes/entities/SnakeBody.tscn")
@export var shoot_interval: float = 0.2

@export var max_hp: int = 10
var current_hp: int = 10
var is_invincible: bool = false

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

    # Create HP Bar
    _hp_bar = TextureProgressBar.new()
    _hp_bar.fill_mode = TextureProgressBar.FILL_LEFT_TO_RIGHT
    _hp_bar.value = 100
    # Create simple textures
    var width = 40
    var height = 5
    var bg_image = Image.create(width, height, false, Image.FORMAT_RGBA8)
    bg_image.fill(Color.RED)
    var progress_image = Image.create(width, height, false, Image.FORMAT_RGBA8)
    progress_image.fill(Color.GREEN)

    _hp_bar.texture_under = ImageTexture.create_from_image(bg_image)
    _hp_bar.texture_progress = ImageTexture.create_from_image(progress_image)
    _hp_bar.position = Vector2(-width/2, -30)
    add_child(_hp_bar)

    _shoot_timer = Timer.new()
    _shoot_timer.wait_time = shoot_interval
    _shoot_timer.one_shot = false
    _shoot_timer.autostart = true
    add_child(_shoot_timer)
    _shoot_timer.timeout.connect(_on_shoot_timeout)

    call_deferred("_spawn_initial_bodies")

func _physics_process(_delta: float) -> void:
    var target := get_global_mouse_position()
    global_position = global_position.lerp(target, 0.1)

    if _hp_bar:
        _hp_bar.max_value = float(max_hp)
        _hp_bar.value = float(current_hp)

func _draw() -> void:
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
    current_hp -= amount
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
    if body_scene == null:
        return
    var body := body_scene.instantiate() as Node2D
    if body == null:
        return
    var target: Node2D = self if body_parts.is_empty() else body_parts.back()
    body.set("unit_type", unit_type)
    body.set("target", target)
    get_tree().current_scene.add_child(body)
    body.tree_exited.connect(_on_body_exited.bind(body))
    var offset := body.get("follow_offset") as Vector2
    if offset == null:
        offset = Vector2.ZERO
    body.global_position = target.global_transform * offset
    body_parts.append(body)
    recalculate_synergies()
    check_for_merges()

func check_for_merges() -> void:
    # Group bodies by type and level
    var groups = {}
    for body in body_parts:
        var type = body.get("unit_type")
        var level = body.get("level")
        var key = "%d_%d" % [type, level]
        if not groups.has(key):
            groups[key] = []
        groups[key].append(body)

    for key in groups:
        var bodies = groups[key]
        if bodies.size() >= 3:
            # Found 3 mergeable units
            var first_body = bodies[0]
            var type = first_body.get("unit_type")
            var level = first_body.get("level")
            var new_level = level + 1

            # Find indices
            var indices = []
            for b in bodies.slice(0, 3):
                indices.append(body_parts.find(b))
            indices.sort()

            # Identify insertion index (the lowest index among the 3)
            var insert_index = indices[0]
            var ref_pos = body_parts[insert_index].global_position

            # Remove bodies (careful with indices shifting, so remove by reference)
            for b in bodies.slice(0, 3):
                body_parts.erase(b)
                b.queue_free()

            # Instantiate new body
            var new_body = body_scene.instantiate() as Node2D
            new_body.set("unit_type", type)
            new_body.set("level", new_level)
            new_body.global_position = ref_pos
            get_tree().current_scene.add_child(new_body)
            new_body.tree_exited.connect(_on_body_exited.bind(new_body))

            # Insert at correct position
            body_parts.insert(insert_index, new_body)

            # Refresh links
            _refresh_body_targets()
            recalculate_synergies()

            # Check for recursive merges (e.g. 3 lvl 1 -> 1 lvl 2, making 3 lvl 2s)
            check_for_merges()
            return

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
        "spread": 0
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

    synergy_bonuses["attack_speed"] = 1.0
    synergy_bonuses["damage_mult"] = 1.0
    synergy_bonuses["size_mult"] = 1.0

    if class_counts["striker"] >= 4:
        synergy_bonuses["attack_speed"] = balance.synergy_striker_attack_speed_high
    elif class_counts["striker"] >= balance.synergy_striker_threshold:
        synergy_bonuses["attack_speed"] = balance.synergy_striker_attack_speed_low

    if class_counts["heavy"] >= balance.synergy_heavy_threshold:
        synergy_bonuses["damage_mult"] = balance.synergy_heavy_damage_mult

    if class_counts["spread"] >= balance.synergy_spread_threshold:
        synergy_bonuses["size_mult"] = balance.synergy_spread_size_mult

    print("Active Synergies: ", synergy_bonuses)
    for part in body_parts:
        if part != null and part.has_method("update_stats"):
            part.call("update_stats", synergy_bonuses)

func _spawn_initial_bodies() -> void:
    add_body(SnakeBodyScript.ClassType.STRIKER)
    add_body(SnakeBodyScript.ClassType.HEAVY)
    add_body(SnakeBodyScript.ClassType.SPREAD)
