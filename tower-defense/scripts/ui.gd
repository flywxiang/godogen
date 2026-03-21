extends Control

@onready var arrow_btn: Button = null
@onready var cannon_btn: Button = null
@onready var magic_btn: Button = null
@onready var start_btn: Button = null
@onready var upgrade_btn: Button = null
@onready var info_label: Label = null

var selected: String = ""

func _ready() -> void:
	await get_tree().process_frame
	
	var tower_panel = find_child("TowerPanel", true, false)
	if tower_panel:
		arrow_btn = tower_panel.find_child("ArrowTower", true, false)
		cannon_btn = tower_panel.find_child("CannonTower", true, false)
		magic_btn = tower_panel.find_child("MagicTower", true, false)
		upgrade_btn = tower_panel.find_child("UpgradeTower", true, false)
		info_label = tower_panel.find_child("InfoLabel", true, false)
	
	start_btn = find_child("StartWaveButton", true, false)
	
	if arrow_btn:
		arrow_btn.pressed.connect(_on_arrow_pressed)
		arrow_btn.tooltip_text = "箭塔\n费用: 50g\n克制: 快速怪"
	if cannon_btn:
		cannon_btn.pressed.connect(_on_cannon_pressed)
		cannon_btn.tooltip_text = "炮塔\n费用: 100g\n克制: 装甲怪"
	if magic_btn:
		magic_btn.pressed.connect(_on_magic_pressed)
		magic_btn.tooltip_text = "魔塔\n费用: 80g\n克制: 快速怪"
	if upgrade_btn:
		upgrade_btn.pressed.connect(_on_upgrade_pressed)
		upgrade_btn.tooltip_text = "升级塔\n点击地图上的塔进行升级"
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
		game.selected_tower_type = selected
		if selected != "":
			var tower_names = {"arrow": "🏹 箭塔", "cannon": "💣 炮塔", "magic": "✨ 魔塔"}
			game.show_message("%s 已选择，点击地图放置！" % tower_names.get(selected, ""))

func _update_buttons() -> void:
	if arrow_btn:
		arrow_btn.modulate = Color(1, 1, 1, 1) if selected != "arrow" else Color(1, 1.5, 1)
	if cannon_btn:
		cannon_btn.modulate = Color(1, 1, 1, 1) if selected != "cannon" else Color(1.5, 1.2, 1)
	if magic_btn:
		magic_btn.modulate = Color(1, 1, 1, 1) if selected != "magic" else Color(1.5, 1, 1.5)

func _on_upgrade_pressed() -> void:
	var game = get_parent().get_parent()
	if game and game.has_method("attempt_upgrade_tower"):
		# Get mouse position and call upgrade
		var mouse_pos = game.get_global_mouse_position()
		game.attempt_upgrade_tower(mouse_pos)

func _on_start_pressed() -> void:
	var game = get_parent().get_parent()
	if game and game.has_method("start_wave"):
		game.start_wave()
