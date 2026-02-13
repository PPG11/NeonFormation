extends CanvasLayer

signal item_purchased(upgrade_type: int, cost: int)
signal shop_closed()

const SnakeBodyScript: Script = preload("res://scripts/entities/SnakeBody.gd")
@onready var balance: GameBalance = get_node("/root/GameBalance") as GameBalance

@onready var _buttons: Array[Button] = [
    $Control/VBoxContainer/HBoxContainer/Button1,
    $Control/VBoxContainer/HBoxContainer/Button2,
    $Control/VBoxContainer/HBoxContainer/Button3
]
@onready var _gold_label: Label = $Control/VBoxContainer/GoldLabel
@onready var _leave_button: Button = $Control/VBoxContainer/LeaveButton

var _options: Array[int] = []
var _current_gold: int = 0
var _purchased: Array[bool] = [false, false, false]

func _ready() -> void:
    visible = false
    for i in _buttons.size():
        _buttons[i].pressed.connect(_on_button_pressed.bind(i))
    _leave_button.pressed.connect(_on_leave_pressed)

func show_shop(current_gold: int) -> void:
    _current_gold = current_gold
    _purchased = [false, false, false]
    
    # 清除所有子弹，避免误触
    _clear_all_bullets()
    
    get_tree().paused = true
    visible = true
    _generate_options()
    _update_ui()

func _clear_all_bullets() -> void:
    var bullets := get_tree().get_nodes_in_group("bullets")
    for bullet in bullets:
        if is_instance_valid(bullet):
            bullet.queue_free()

func _generate_options() -> void:
    var types := [
        SnakeBodyScript.ClassType.STRIKER,
        SnakeBodyScript.ClassType.HEAVY,
        SnakeBodyScript.ClassType.SPREAD,
        SnakeBodyScript.ClassType.BURST,
        SnakeBodyScript.ClassType.LASER,
        SnakeBodyScript.ClassType.RICOCHET,
        SnakeBodyScript.ClassType.CHARGE,
        SnakeBodyScript.ClassType.SHIELD,
        SnakeBodyScript.ClassType.SUPPORT
    ]
    types.shuffle()
    _options.clear()
    for i in range(3):
        _options.append(types[i])

func _update_ui() -> void:
    # 更新金币显示
    _gold_label.text = "Gold: %d" % _current_gold
    
    var price = balance.unit_price
    for i in _buttons.size():
        if _purchased[i]:
            # 已购买的商品显示为"已售出"
            _buttons[i].text = "SOLD OUT"
            _buttons[i].disabled = true
        else:
            var label := _type_to_label(_options[i])
            _buttons[i].text = "Add %s\n(%d G)" % [label, price]
            _buttons[i].disabled = (_current_gold < price)

func _on_button_pressed(index: int) -> void:
    if index < 0 or index >= _options.size():
        return
    if _purchased[index]:
        return
    if _current_gold < balance.unit_price:
        return
    
    # 购买商品
    var price = balance.unit_price
    # _current_gold will be updated by Main via update_gold, but we deduct locally for immediate feedback
    _current_gold -= price
    _purchased[index] = true
    
    # 发射购买信号
    emit_signal("item_purchased", _options[index], price)
    
    # 更新UI，但不关闭商店
    _update_ui()

func update_gold(amount: int) -> void:
    _current_gold = amount
    _update_ui()

func _on_leave_pressed() -> void:
    visible = false
    get_tree().paused = false
    emit_signal("shop_closed")

func _type_to_label(t: int) -> String:
    match t:
        SnakeBodyScript.ClassType.STRIKER:
            return "Striker"
        SnakeBodyScript.ClassType.HEAVY:
            return "Heavy"
        SnakeBodyScript.ClassType.SPREAD:
            return "Spread"
        SnakeBodyScript.ClassType.BURST:
            return "Burst"
        SnakeBodyScript.ClassType.LASER:
            return "Laser"
        SnakeBodyScript.ClassType.RICOCHET:
            return "Ricochet"
        SnakeBodyScript.ClassType.CHARGE:
            return "Charge"
        SnakeBodyScript.ClassType.SHIELD:
            return "Shield"
        SnakeBodyScript.ClassType.SUPPORT:
            return "Support"
    return "Unknown"
