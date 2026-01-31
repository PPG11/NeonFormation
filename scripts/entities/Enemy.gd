extends Area2D

@export var speed: float = 100.0

func _ready() -> void:
	add_to_group("enemy")
	var notifier := get_node_or_null("VisibleOnScreenNotifier2D") as VisibleOnScreenNotifier2D
	if notifier == null:
		notifier = VisibleOnScreenNotifier2D.new()
		add_child(notifier)
	notifier.screen_exited.connect(_on_screen_exited)

func _process(delta: float) -> void:
	global_position += Vector2.DOWN * speed * delta

func _draw() -> void:
	var half := 10.0
	var rect := Rect2(Vector2(-half, -half), Vector2(half * 2.0, half * 2.0))
	draw_rect(rect, Color.RED, false, 2.0)

func _on_screen_exited() -> void:
	queue_free()
