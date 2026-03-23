extends CanvasLayer

signal item_purchased(item_type)

func _ready():
	$VBox/HealButton.pressed.connect(_on_heal)
	$VBox/ShieldButton.pressed.connect(_on_shield)
	$VBox/SpeedButton.pressed.connect(_on_speed)
	$VBox/DamageButton.pressed.connect(_on_damage)
	$VBox/CloseButton.pressed.connect(_on_close)

func show_shop(current_gold: int):
	visible = true
	$VBox/GoldLabel.text = "💰 %d" % current_gold
	_update_buttons(current_gold)

func _update_buttons(gold: int):
	$VBox/HealButton.disabled = gold < 50
	$VBox/ShieldButton.disabled = gold < 100
	$VBox/SpeedButton.disabled = gold < 80
	$VBox/DamageButton.disabled = gold < 120

func _on_heal():
	item_purchased.emit("heal")
	queue_free()

func _on_shield():
	item_purchased.emit("shield")
	queue_free()

func _on_speed():
	item_purchased.emit("speed")
	queue_free()

func _on_damage():
	item_purchased.emit("damage")
	queue_free()

func _on_close():
	queue_free()
