extends Node2D

@export var target: Node2D
@export var speed: float = 450.0
@export var keep_distance: float = 20.0
@export var follow_offset: Vector2 = Vector2(-24.0, 12.0)

func _physics_process(delta: float) -> void:
	if target == null:
		return
	var target_pos := target.global_transform * follow_offset
	var dist := global_position.distance_to(target_pos)
	if dist > keep_distance:
		global_position = global_position.move_toward(target_pos, speed * delta)
	queue_redraw()

func _draw() -> void:
	draw_arc(Vector2.ZERO, 8.0, 0.0, TAU, 24, Color.CORNFLOWER_BLUE, 2.0)
