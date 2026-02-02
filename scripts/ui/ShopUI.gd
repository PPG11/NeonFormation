extends CanvasLayer

signal upgrade_selected(upgrade_type: int)

const SnakeBodyScript: Script = preload("res://scripts/entities/SnakeBody.gd")

@onready var _buttons: Array[Button] = [
    $Control/HBoxContainer/Button1,
    $Control/HBoxContainer/Button2,
    $Control/HBoxContainer/Button3
]

var _options: Array[int] = []
var _current_gold: int = 0
@onready var balance: GameBalance = get_node("/root/GameBalance") as GameBalance

func _ready() -> void:
    visible = false
    for i in _buttons.size():
        _buttons[i].pressed.connect(_on_button_pressed.bind(i))

func show_shop(current_gold: int) -> void:
    _current_gold = current_gold
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
        var type = _options[i]
        var label := _type_to_label(type)
        var cost = _get_cost(type)
        _buttons[i].text = "Add %s (%dG)" % [label, cost]
        _buttons[i].disabled = _current_gold < cost

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

func _get_cost(t: int) -> int:
    match t:
        SnakeBodyScript.ClassType.STRIKER:
            return balance.unit_cost_striker
        SnakeBodyScript.ClassType.HEAVY:
            return balance.unit_cost_heavy
        SnakeBodyScript.ClassType.SPREAD:
            return balance.unit_cost_spread
    return 999
