extends Area2D

@export var speed: float = 100.0
@export var max_hp: int = 30

var current_hp: int
var _base_modulate: Color
const SnakeBodyScript: Script = preload("res://scripts/entities/SnakeBody.gd")

func _ready() -> void:
	add_to_group("enemy")
	monitoring = true
	current_hp = max_hp
	_base_modulate = modulate
	var notifier := get_node_or_null("VisibleOnScreenNotifier2D") as VisibleOnScreenNotifier2D
	if notifier == null:
		notifier = VisibleOnScreenNotifier2D.new()
		add_child(notifier)
	notifier.screen_exited.connect(_on_screen_exited)
	body_entered.connect(_on_body_entered)
	area_entered.connect(_on_area_entered)

func _process(delta: float) -> void:
	global_position += Vector2.DOWN * speed * delta

func _draw() -> void:
	var half := 10.0
	var rect := Rect2(Vector2(-half, -half), Vector2(half * 2.0, half * 2.0))
	draw_rect(rect, Color.RED, false, 2.0)

func _on_screen_exited() -> void:
	queue_free()

func _on_body_entered(body: Node) -> void:
	if body is CharacterBody2D and body.has_method("die"):
		body.call("die")
		queue_free()

func _on_area_entered(area: Area2D) -> void:
	if area != null and area.get_script() == SnakeBodyScript:
		area.queue_free()
		queue_free()

func take_damage(amount: int) -> void:
	current_hp -= amount
	modulate = Color.RED
	var tween := create_tween()
	tween.tween_property(self, "modulate", _base_modulate, 0.1)
	if current_hp <= 0:
		die()

func die() -> void:
	print("Enemy destroyed")
	queue_free()
