extends Node2D

@export var target: Node2D
@export var speed: float = 450.0
@export var keep_distance: float = 20.0
@export var follow_offset: Vector2 = Vector2(-24.0, 12.0)
@export var shoot_interval: float = 0.3

const BulletScene: PackedScene = preload("res://scenes/entities/Bullet.tscn")

var _shoot_timer: Timer

func _ready() -> void:
	_shoot_timer = Timer.new()
	_shoot_timer.wait_time = shoot_interval
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
	draw_arc(Vector2.ZERO, 8.0, 0.0, TAU, 24, Color.CORNFLOWER_BLUE, 2.0)

func _on_shoot_timer_timeout() -> void:
	if BulletScene == null:
		return
	var bullet := BulletScene.instantiate() as Area2D
	if bullet == null:
		return
	bullet.set("color", Color.CYAN)
	bullet.global_position = global_position
	get_tree().current_scene.add_child(bullet)
