extends Node

const EnemyScene: PackedScene = preload("res://scenes/entities/Enemy.tscn")
const PlayerScene: PackedScene = preload("res://scenes/entities/Player.tscn")

@export var spawn_interval: float = 1.0
@export var spawn_padding: float = 20.0

var current_wave: int = 1
var gold: int = 0
var enemies_to_spawn: int = 10
var enemies_alive: int = 0

var _spawn_timer: Timer
@onready var _wave_label: Label = $CanvasLayer/WaveLabel
@onready var _gold_label: Label = $CanvasLayer/GoldLabel

func _ready() -> void:
	if PlayerScene != null:
		var player := PlayerScene.instantiate() as Node2D
		if player != null:
			add_child(player)
			player.position = Vector2(180.0, 550.0)

	_spawn_timer = Timer.new()
	_spawn_timer.wait_time = spawn_interval
	_spawn_timer.one_shot = false
	_spawn_timer.autostart = false
	add_child(_spawn_timer)
	_spawn_timer.timeout.connect(_on_spawn_timeout)

	start_wave()

func _on_spawn_timeout() -> void:
	if enemies_to_spawn <= 0:
		_spawn_timer.stop()
		return
	if EnemyScene == null:
		return
	var enemy := EnemyScene.instantiate() as Area2D
	if enemy == null:
		return
	if enemy.has_signal("enemy_died"):
		enemy.connect("enemy_died", _on_enemy_killed)
	var viewport_rect := get_viewport().get_visible_rect()
	var x := randf_range(viewport_rect.position.x + spawn_padding,
		viewport_rect.position.x + viewport_rect.size.x - spawn_padding)
	var y := viewport_rect.position.y - spawn_padding
	enemy.global_position = Vector2(x, y)
	get_tree().current_scene.add_child(enemy)
	enemies_to_spawn -= 1
	enemies_alive += 1
	if enemies_to_spawn == 0:
		_spawn_timer.stop()

func start_wave() -> void:
	_update_ui()
	enemies_to_spawn = 10 + (current_wave * 5)
	enemies_alive = 0
	_spawn_timer.start()

func _on_enemy_killed(reward_gold: int) -> void:
	gold += reward_gold
	enemies_alive = max(enemies_alive - 1, 0)
	_update_ui()
	if enemies_alive == 0 and enemies_to_spawn == 0:
		print("Wave Complete")
		await get_tree().create_timer(2.0).timeout
		next_wave()

func next_wave() -> void:
	current_wave += 1
	start_wave()

func _update_ui() -> void:
	if _wave_label != null:
		_wave_label.text = "Wave: %d" % current_wave
	if _gold_label != null:
		_gold_label.text = "Gold: %d" % gold
