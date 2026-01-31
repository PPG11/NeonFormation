extends CanvasLayer

signal upgrade_selected(upgrade_type: int)

const SnakeBodyScript: Script = preload("res://scripts/entities/SnakeBody.gd")

@onready var _buttons: Array[Button] = [
    $Control/HBoxContainer/Button1,
    $Control/HBoxContainer/Button2,
    $Control/HBoxContainer/Button3
]

var _options: Array[int] = []

func _ready() -> void:
    visible = false
    for i in _buttons.size():
        _buttons[i].pressed.connect(_on_button_pressed.bind(i))

func show_shop() -> void:
    get_tree().paused = true
    visible = true
    _generate_options()
    _update_button_text()

func _generate_options() -> void:
    var types := [
        SnakeBodyScript.ClassType.STRIKER,
        SnakeBodyScript.ClassType.HEAVY,
        SnakeBodyScript.ClassType.SPREAD
    ]
    types.shuffle()
    _options.clear()
    for i in range(3):
        _options.append(types[i])

func _update_button_text() -> void:
    for i in _buttons.size():
        var label := _type_to_label(_options[i])
        _buttons[i].text = "Add %s" % label

func _on_button_pressed(index: int) -> void:
    if index < 0 or index >= _options.size():
        return
    emit_signal("upgrade_selected", _options[index])
    visible = false
    get_tree().paused = false

func _type_to_label(t: int) -> String:
    match t:
        SnakeBodyScript.ClassType.STRIKER:
            return "Striker"
        SnakeBodyScript.ClassType.HEAVY:
            return "Heavy"
        SnakeBodyScript.ClassType.SPREAD:
            return "Spread"
    return "Unknown"
