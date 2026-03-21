extends Control

@onready var arrow_btn: Button = null
@onready var cannon_btn: Button = null
@onready var magic_btn: Button = null
@onready var start_btn: Button = null
@onready var upgrade_btn: Button = null
@onready var menu_btn: Button = null

var selected: String = ""

func _ready() -> void:
	await get_tree().process_frame
	
	var tower_panel = find_child("TowerPanel", true, false)
	if tower_panel:
		arrow_btn = tower_panel.find_child("ArrowTower", true, false)
		cannon_btn = tower_panel.find_child("CannonTower", true, false)
		magic_btn = tower_panel.find_child("MagicTower", true, false)
		upgrade_btn = tower_panel.find_child("UpgradeTower", true, false)
	
	start_btn = find_child("StartWaveButton", true, false)
	menu_btn = find_child("MenuButton", true, false)
	
	# 塔按钮
	if arrow_btn:
		arrow_btn.pressed.connect(_on_arrow_pressed)
	if cannon_btn:
		cannon_btn.pressed.connect(_on_cannon_pressed)
	if magic_btn:
		magic_btn.pressed.connect(_on_magic_pressed)
	if upgrade_btn:
		upgrade_btn.pressed.connect(_on_upgrade_pressed)
	if start_btn:
		start_btn.pressed.connect(_on_start_pressed)
	if menu_btn:
		menu_btn.pressed.connect(_on_menu_pressed)
	
	# 关卡选择按钮
	var level_select = find_child("LevelSelect", true, false)
	if level_select:
		var panel = level_select.find_child("LevelSelectPanel", true, false)
		if panel:
			var grid = panel.find_child("Grid", true, false)
			if grid:
				for i in range(1, 6):
					var btn = grid.find_child("Level%d" % i, true, false)
					if btn:
						var level_num = i
						btn.pressed.connect(_on_level_selected.bind(level_num))
			
			var back_btn = panel.find_child("BackButton", true, false)
			if back_btn:
				back_btn.pressed.connect(_on_back_pressed)

func _on_level_selected(level_num: int) -> void:
	var game = get_parent().get_parent()
	if game and game.has_method("select_level"):
		game.select_level(level_num)

func _on_back_pressed() -> void:
	var game = get_parent().get_parent()
	if game and game.has_method("return_to_menu"):
		pass  # 返回菜单

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
	if game and game.has_method("select_level"):
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
		var mouse_pos = game.get_global_mouse_position()
		game.attempt_upgrade_tower(mouse_pos)

func _on_start_pressed() -> void:
	var game = get_parent().get_parent()
	if game and game.has_method("start_wave"):
		game.start_wave()

func _on_menu_pressed() -> void:
	var game = get_parent().get_parent()
	if game and game.has_method("show_level_select"):
		game.show_level_select()
