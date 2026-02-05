extends CanvasLayer

signal upgrade_selected(upgrade_type: int)
signal start_next_wave

const SnakeBodyScript: Script = preload("res://scripts/entities/SnakeBody.gd")
@onready var balance: GameBalance = get_node("/root/GameBalance") as GameBalance

@onready var _buttons: Array[Button] = [
    $Control/HBoxContainer/Button1,
    $Control/HBoxContainer/Button2,
    $Control/HBoxContainer/Button3
]

var _options: Array[int] = []
var _current_gold: int = 0
var _next_wave_button: Button

func _ready() -> void:
    visible = false
    for i in _buttons.size():
        _buttons[i].pressed.connect(_on_button_pressed.bind(i))

    _next_wave_button = Button.new()
    _next_wave_button.text = "Next Wave"
    _next_wave_button.custom_minimum_size = Vector2(200, 50)
    _next_wave_button.position = Vector2(80, 500)
    $Control.add_child(_next_wave_button)
    _next_wave_button.pressed.connect(_on_next_wave_pressed)

func show_shop(current_gold: int) -> void:
    _current_gold = current_gold
    get_tree().paused = true
    visible = true
    _generate_options()
    _update_ui()

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

func _update_ui() -> void:
    var price = balance.unit_price
    for i in _buttons.size():
        var label := _type_to_label(_options[i])
        _buttons[i].text = "Add %s\n(%d G)" % [label, price]
        _buttons[i].disabled = (_current_gold < price)

func _on_button_pressed(index: int) -> void:
    if index < 0 or index >= _options.size():
        return
    if _current_gold < balance.unit_price:
        return
    _current_gold -= balance.unit_price
    emit_signal("upgrade_selected", _options[index])
    _update_ui()

func _on_next_wave_pressed() -> void:
    visible = false
    get_tree().paused = false
    emit_signal("start_next_wave")

func _type_to_label(t: int) -> String:
    match t:
        SnakeBodyScript.ClassType.STRIKER:
            return "Striker"
        SnakeBodyScript.ClassType.HEAVY:
            return "Heavy"
        SnakeBodyScript.ClassType.SPREAD:
            return "Spread"
    return "Unknown"
