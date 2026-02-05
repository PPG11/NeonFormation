extends Area2D

@export var speed: float = 400.0
@export var color: Color = Color.WHITE
@export var damage: int = 10
@export var is_enemy_bullet: bool = false
@export var is_crit: bool = false

func _ready() -> void:
    monitoring = true
    area_entered.connect(_on_area_entered)
    body_entered.connect(_on_body_entered)

func _process(delta: float) -> void:
    var dir := Vector2.UP.rotated(rotation)
    global_position += dir * speed * delta

func _draw() -> void:
    var draw_color := color
    var radius := 3.0
    if is_enemy_bullet:
        draw_color = Color.ORANGE
    elif is_crit:
        draw_color = Color.WHITE
        radius = 5.0
    draw_circle(Vector2.ZERO, radius, draw_color)

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
            queue_free()

func _on_body_entered(body: Node) -> void:
    if is_enemy_bullet and body.is_in_group("player_team"):
        if body.has_method("take_damage"):
            body.call("take_damage", damage)
        elif body.has_method("die"):
            body.call("die")
        queue_free()
