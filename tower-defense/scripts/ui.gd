extends Control

@onready var arrow_btn: Button = null
@onready var cannon_btn: Button = null
@onready var magic_btn: Button = null
@onready var start_btn: Button = null

var selected: String = ""

func _ready() -> void:
	# Wait for tree to be ready
	await get_tree().process_frame
	
	# Get references safely
	var tower_panel = find_child("TowerPanel", true, false)
	if tower_panel:
		arrow_btn = tower_panel.find_child("ArrowTower", true, false)
		cannon_btn = tower_panel.find_child("CannonTower", true, false)
		magic_btn = tower_panel.find_child("MagicTower", true, false)
	
	start_btn = find_child("StartWaveButton", true, false)
	
	if arrow_btn:
		arrow_btn.pressed.connect(_on_arrow_pressed)
		arrow_btn.tooltip_text = "Arrow Tower\nCost: 50g\nFast attack, low damage"
	if cannon_btn:
		cannon_btn.pressed.connect(_on_cannon_pressed)
		cannon_btn.tooltip_text = "Cannon Tower\nCost: 100g\nSlow attack, high damage"
	if magic_btn:
		magic_btn.pressed.connect(_on_magic_pressed)
		magic_btn.tooltip_text = "Magic Tower\nCost: 80g\nSlows enemies"
	if start_btn:
		start_btn.pressed.connect(_on_start_pressed)

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
	if game and game.has_method("start_wave"):
		game.selected_tower = selected
		if selected != "":
			game.show_message("%s tower selected. Click to place!" % selected.capitalize())

func _update_buttons() -> void:
	if arrow_btn:
		arrow_btn.modulate = Color(1, 1, 1, 1) if selected != "arrow" else Color(1, 1.5, 1)
	if cannon_btn:
		cannon_btn.modulate = Color(1, 1, 1, 1) if selected != "cannon" else Color(1.5, 1.2, 1)
	if magic_btn:
		magic_btn.modulate = Color(1, 1, 1, 1) if selected != "magic" else Color(1.5, 1, 1.5)

func _on_start_pressed() -> void:
	var game = get_parent().get_parent()
	if game and game.has_method("start_wave"):
		game.start_wave()
