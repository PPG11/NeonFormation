extends Node2D

enum ClassType { STRIKER, HEAVY, SPREAD }

@export var target: Node2D
@export var speed: float = 450.0
@export var keep_distance: float = 20.0
@export var follow_offset: Vector2 = Vector2(-24.0, 12.0)
@export var unit_type: ClassType = ClassType.STRIKER : set = _set_unit_type

const BulletScene: PackedScene = preload("res://scenes/entities/Bullet.tscn")

var _shoot_timer: Timer

func _ready() -> void:
	_shoot_timer = Timer.new()
	_shoot_timer.wait_time = _get_shoot_interval()
	_shoot_timer.one_shot = false
	_shoot_timer.autostart = true
	add_child(_shoot_timer)
	_shoot_timer.timeout.connect(_on_shoot_timer_timeout)

func _physics_process(delta: float) -> void:
	if target == null:
		return
	var target_pos := target.global_transform * follow_offset
	var dist := global_position.distance_to(target_pos)
	if dist > keep_distance:
		global_position = global_position.move_toward(target_pos, speed * delta)
	queue_redraw()

func _draw() -> void:
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

func _on_shoot_timer_timeout() -> void:
	if BulletScene == null:
		return
	match unit_type:
		ClassType.STRIKER:
			_spawn_bullet(Color.CYAN, 10, 1.0, 0.0)
		ClassType.HEAVY:
			_spawn_bullet(Color.YELLOW, 30, 2.0, 0.0)
		ClassType.SPREAD:
			_spawn_bullet(Color.PURPLE, 15, 1.0, -15.0)
			_spawn_bullet(Color.PURPLE, 15, 1.0, 0.0)
			_spawn_bullet(Color.PURPLE, 15, 1.0, 15.0)

func _spawn_bullet(bullet_color: Color, damage: int, scale_factor: float, angle_deg: float) -> void:
	var bullet := BulletScene.instantiate() as Area2D
	if bullet == null:
		return
	bullet.set("color", bullet_color)
	bullet.set("damage", damage)
	bullet.global_position = global_position
	bullet.rotation = deg_to_rad(angle_deg)
	bullet.scale = Vector2.ONE * scale_factor
	get_tree().current_scene.add_child(bullet)

func _get_shoot_interval() -> float:
	match unit_type:
		ClassType.STRIKER:
			return 0.2
		ClassType.HEAVY:
			return 1.0
		ClassType.SPREAD:
			return 0.5
	return 0.3

func _set_unit_type(value: ClassType) -> void:
	unit_type = value
	if _shoot_timer != null:
		_shoot_timer.wait_time = _get_shoot_interval()
	queue_redraw()
