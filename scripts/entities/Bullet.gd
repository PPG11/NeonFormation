extends Area2D

@export var speed: float = 400.0

func _ready() -> void:
	area_entered.connect(_on_area_entered)
	body_entered.connect(_on_body_entered)

func _process(delta: float) -> void:
	global_position += Vector2.UP * speed * delta

func _draw() -> void:
	draw_circle(Vector2.ZERO, 3.0, Color.WHITE)

func _on_area_entered(area: Area2D) -> void:
	if area.is_in_group("enemy"):
		area.queue_free()
		queue_free()

func _on_body_entered(body: Node) -> void:
	if body.is_in_group("enemy"):
		body.queue_free()
		queue_free()
