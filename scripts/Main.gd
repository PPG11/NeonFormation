extends Node

const EnemyScene: PackedScene = preload("res://scenes/entities/Enemy.tscn")
const BulletScene: PackedScene = preload("res://scenes/entities/Bullet.tscn")
const PlayerScene: PackedScene = preload("res://scenes/entities/Player.tscn")

@export var spawn_interval: float = 1.0
@export var spawn_padding: float = 20.0

var _spawn_timer: Timer

func _ready() -> void:
	if PlayerScene != null:
		var player := PlayerScene.instantiate() as Node2D
		if player != null:
			add_child(player)
			player.position = Vector2(180.0, 550.0)

	_spawn_timer = Timer.new()
	_spawn_timer.wait_time = spawn_interval
	_spawn_timer.one_shot = false
	_spawn_timer.autostart = true
	add_child(_spawn_timer)
	_spawn_timer.timeout.connect(_on_spawn_timeout)

func _on_spawn_timeout() -> void:
	if EnemyScene == null:
		return
	var enemy := EnemyScene.instantiate() as Area2D
	if enemy == null:
		return
	var viewport_rect := get_viewport().get_visible_rect()
	var x := randf_range(viewport_rect.position.x + spawn_padding,
		viewport_rect.position.x + viewport_rect.size.x - spawn_padding)
	var y := viewport_rect.position.y - spawn_padding
	enemy.global_position = Vector2(x, y)
	get_tree().current_scene.add_child(enemy)
