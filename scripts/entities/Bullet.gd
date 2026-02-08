extends Area2D

@export var speed: float = 400.0
@export var color: Color = Color.WHITE
@export var damage: int = 10
@export var is_enemy_bullet: bool = false

# Ricochet properties
@export var can_ricochet: bool = false
@export var max_bounces: int = 0
@export var bounce_range: float = 150.0
@export var damage_decay: float = 1.0
var _bounces_left: int = 0
var _hit_targets: Array[Node2D] = []
var sprite_texture: Texture2D

func _ready() -> void:
    monitoring = true
    area_entered.connect(_on_area_entered)
    body_entered.connect(_on_body_entered)
    _bounces_left = max_bounces
    add_to_group("bullets")

    if sprite_texture:
        var sprite = Sprite2D.new()
        sprite.texture = sprite_texture
        sprite.scale = Vector2(0.05, 0.05) # Approx 12px
        add_child(sprite)

func _process(delta: float) -> void:
    var dir := Vector2.UP.rotated(rotation)
    global_position += dir * speed * delta

func _draw() -> void:
    if sprite_texture:
        return
    var draw_color := color
    if is_enemy_bullet:
        draw_color = Color.ORANGE
    draw_circle(Vector2.ZERO, 3.0, draw_color)

func _on_area_entered(area: Area2D) -> void:
    if is_enemy_bullet:
        if area.is_in_group("player_team"):
            if area.has_method("take_damage"):
                area.call("take_damage", damage)
            elif area.has_method("die"):
                area.call("die")
            queue_free()
    else:
        if area.is_in_group("enemy_team") and area.has_method("take_damage"):
            area.call("take_damage", damage)
            
            # Handle ricochet
            if can_ricochet and _bounces_left > 0 and area is Node2D:
                _hit_targets.append(area)
                _try_ricochet()
            else:
                queue_free()

func _on_body_entered(body: Node) -> void:
    if is_enemy_bullet and body.is_in_group("player_team"):
        if body.has_method("take_damage"):
            body.call("take_damage", damage)
        elif body.has_method("die"):
            body.call("die")
        queue_free()

func _try_ricochet() -> void:
    # Find nearest enemy not yet hit
    var enemies := get_tree().get_nodes_in_group("enemy_team")
    var nearest: Node2D = null
    var min_dist := INF
    
    for enemy in enemies:
        if not is_instance_valid(enemy) or not enemy is Node2D:
            continue
        if _hit_targets.has(enemy):
            continue
        var dist := global_position.distance_to(enemy.global_position)
        if dist < min_dist and dist <= bounce_range:
            min_dist = dist
            nearest = enemy
    
    if nearest != null:
        # Ricochet to new target
        _bounces_left -= 1
        damage = int(damage * damage_decay)
        
        # Redirect bullet
        var to_target := (nearest.global_position - global_position).normalized()
        rotation = to_target.angle() + PI / 2
    else:
        # No valid target, destroy bullet
        queue_free()
