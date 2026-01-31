extends CharacterBody2D

@export var max_speed: float = 420.0
@export var accel: float = 1400.0
@export var rotate_speed: float = 10.0
@export var segment_spacing: float = 22.0
@export var follow_speed: float = 900.0
@export var body_segments: Array[Node2D] = []

@export var head_size: float = 18.0
@export var body_radius: float = 10.0
@export var line_width: float = 2.0

func _physics_process(delta: float) -> void:
	var target: Vector2 = get_global_mouse_position()
	var to_target: Vector2 = target - global_position
	if to_target.length() > 0.001:
		var desired_velocity: Vector2 = to_target.normalized() * max_speed
		velocity = velocity.move_toward(desired_velocity, accel * delta)
		rotation = lerp_angle(rotation, to_target.angle(), 1.0 - exp(-rotate_speed * delta))
	else:
		velocity = velocity.move_toward(Vector2.ZERO, accel * delta)

	move_and_slide()
	_update_body_segments(delta)
	queue_redraw()

func _update_body_segments(delta: float) -> void:
	for i in body_segments.size():
		var seg: Node2D = body_segments[i]
		if seg == null:
			continue
		var prev: Node2D = self if i == 0 else body_segments[i - 1]
		if prev == null:
			continue
		var from_prev: Vector2 = seg.global_position.direction_to(prev.global_position)
		var target_pos: Vector2 = prev.global_position - from_prev * segment_spacing
		seg.global_position = seg.global_position.move_toward(target_pos, follow_speed * delta)

func _draw() -> void:
	var p1 := Vector2(head_size, 0.0)
	var p2 := Vector2(-head_size * 0.6, head_size * 0.6)
	var p3 := Vector2(-head_size * 0.6, -head_size * 0.6)
	var head_points: PackedVector2Array = [p1, p2, p3, p1]
	draw_polyline(head_points, Color.GREEN, line_width)

	for seg in body_segments:
		if seg == null:
			continue
		var local_pos: Vector2 = to_local(seg.global_position)
		draw_arc(local_pos, body_radius, 0.0, TAU, 24, Color.YELLOW, line_width)
