extends CharacterBody2D

@export var bullet_scene: PackedScene = preload("res://scenes/entities/Bullet.tscn")
@export var body_scene: PackedScene = preload("res://scenes/entities/SnakeBody.tscn")
@export var shoot_interval: float = 0.2

var body_parts: Array[Node2D] = []

var _shoot_timer: Timer
const SnakeBodyScript: Script = preload("res://scripts/entities/SnakeBody.gd")

func _ready() -> void:
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

func _draw() -> void:
	var p1 := Vector2(0.0, -16.0)
	var p2 := Vector2(-8.0, 10.0)
	var p3 := Vector2(8.0, 10.0)
	var points: PackedVector2Array = [p1, p2, p3, p1]
	draw_polyline(points, Color.GREEN, 2.0)

func die() -> void:
	print("Game Over")
	get_tree().reload_current_scene()

func _on_shoot_timeout() -> void:
	if bullet_scene == null:
		return
	var bullet := bullet_scene.instantiate() as Area2D
	if bullet == null:
		return
	bullet.set("color", Color.GREEN)
	bullet.set("damage", 10)
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
	var offset := body.get("follow_offset") as Vector2
	if offset == null:
		offset = Vector2.ZERO
	body.global_position = target.global_transform * offset
	body_parts.append(body)

func _spawn_initial_bodies() -> void:
	add_body(SnakeBodyScript.ClassType.STRIKER)
	add_body(SnakeBodyScript.ClassType.HEAVY)
	add_body(SnakeBodyScript.ClassType.SPREAD)
