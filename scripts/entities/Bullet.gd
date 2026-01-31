extends Area2D

@export var speed: float = 400.0
@export var color: Color = Color.WHITE
@export var damage: int = 10

func _ready() -> void:
	area_entered.connect(_on_area_entered)
	body_entered.connect(_on_body_entered)

func _process(delta: float) -> void:
	var dir := Vector2.UP.rotated(rotation)
	global_position += dir * speed * delta

func _draw() -> void:
	draw_circle(Vector2.ZERO, 3.0, color)

func _on_area_entered(area: Area2D) -> void:
	if area.is_in_group("enemy") and area.has_method("take_damage"):
		area.call("take_damage", damage)
		queue_free()

func _on_body_entered(body: Node) -> void:
	if body.is_in_group("enemy") and body.has_method("take_damage"):
		body.call("take_damage", damage)
		queue_free()
