extends Control

@onready var arrow_btn: Button = $"/root/Game/UI/TowerPanel/ArrowTower"
@onready var cannon_btn: Button = $"/root/Game/UI/TowerPanel/CannonTower"
@onready var magic_btn: Button = $"/root/Game/UI/TowerPanel/MagicTower"
@onready var start_btn: Button = $"/root/Game/UI/StartWaveButton"

var selected: String = ""

func _ready() -> void:
	# Get references through the scene tree
	var ui = get_parent()
	var game = ui.get_parent()
	
	arrow_btn = ui.get_node("TowerPanel/ArrowTower")
	cannon_btn = ui.get_node("TowerPanel/CannonTower")
	magic_btn = ui.get_node("TowerPanel/MagicTower")
	start_btn = ui.get_node("StartWaveButton")
	
	arrow_btn.pressed.connect(_on_arrow_pressed)
	cannon_btn.pressed.connect(_on_cannon_pressed)
	magic_btn.pressed.connect(_on_magic_pressed)
	start_btn.pressed.connect(_on_start_pressed)
	
	arrow_btn.tooltip_text = "Arrow Tower\nCost: 50g\nFast attack, low damage"
	cannon_btn.tooltip_text = "Cannon Tower\nCost: 100g\nSlow attack, high damage"
	magic_btn.tooltip_text = "Magic Tower\nCost: 80g\nSlows enemies"

func _on_arrow_pressed() -> void:
	_select_tower("arrow")

func _on_cannon_pressed() -> void:
	_select_tower("cannon")

func _on_magic_pressed() -> void:
	_select_tower("magic")

func _select_tower(type: String) -> void:
	selected = type if selected != type else ""
	_update_buttons()
	
	var game = get_parent().get_parent()
	if game:
		game.selected_tower = selected
		if selected != "":
			game.show_message("%s tower selected. Click to place!" % selected.capitalize())

func _update_buttons() -> void:
	arrow_btn.modulate = Color(1, 1, 1, 1) if selected != "arrow" else Color(1, 1.5, 1)
	cannon_btn.modulate = Color(1, 1, 1, 1) if selected != "cannon" else Color(1.5, 1.2, 1)
	magic_btn.modulate = Color(1, 1, 1, 1) if selected != "magic" else Color(1.5, 1, 1.5)

func _on_start_pressed() -> void:
	var game = get_parent().get_parent()
	if game:
		game.start_wave()
