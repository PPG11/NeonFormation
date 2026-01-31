extends CharacterBody2D

@export var bullet_scene: PackedScene = preload("res://scenes/entities/Bullet.tscn")
@export var shoot_interval: float = 0.2

var _shoot_timer: Timer

func _ready() -> void:
	_shoot_timer = Timer.new()
	_shoot_timer.wait_time = shoot_interval
	_shoot_timer.one_shot = false
	_shoot_timer.autostart = true
	add_child(_shoot_timer)
	_shoot_timer.timeout.connect(_on_shoot_timeout)

func _physics_process(_delta: float) -> void:
	var target := get_global_mouse_position()
	global_position = global_position.lerp(target, 0.1)

func _draw() -> void:
	var p1 := Vector2(0.0, -16.0)
	var p2 := Vector2(-8.0, 10.0)
	var p3 := Vector2(8.0, 10.0)
	var points: PackedVector2Array = [p1, p2, p3, p1]
	draw_polyline(points, Color.GREEN, 2.0)

func _on_shoot_timeout() -> void:
	if bullet_scene == null:
		return
	var bullet := bullet_scene.instantiate() as Area2D
	if bullet == null:
		return
	bullet.global_position = global_position
	get_tree().current_scene.add_child(bullet)
