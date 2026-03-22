extends CanvasLayer

const LEVEL_DATA = {
	1: {"name": "新手村", "map": "res://scenes/maps/map_1.tscn"},
	2: {"name": "森林要塞", "map": "res://scenes/maps/map_2.tscn"},
	3: {"name": "魔法山谷", "map": "res://scenes/maps/map_3.tscn"},
	4: {"name": "钢铁前线", "map": "res://scenes/maps/map_4.tscn"},
	5: {"name": "最终决战", "map": "res://scenes/maps/map_5.tscn"}
}

var selected_level: int = 1
var save_data: Dictionary = {}

func _ready():
	_load_save()
	_setup_buttons()

func _setup_buttons():
	$Grid/Level1.pressed.connect(_on_level_selected.bind(1))
	$Grid/Level2.pressed.connect(_on_level_selected.bind(2))
	$Grid/Level3.pressed.connect(_on_level_selected.bind(3))
	$Grid/Level4.pressed.connect(_on_level_selected.bind(4))
	$Grid/Level5.pressed.connect(_on_level_selected.bind(5))
	$BackButton.pressed.connect(_on_back)
	$DailyChallenge.pressed.connect(_on_daily_challenge)
	
	# 更新关卡按钮状态
	_update_level_buttons()

func _update_level_buttons():
	var btns = [
		$Grid/Level1, $Grid/Level2, $Grid/Level3, $Grid/Level4, $Grid/Level5
	]
	var unlocked = save_data.get("level_progress", [1])
	
	for i in range(5):
		var level_num = i + 1
		var btn = btns[i]
		if level_num in unlocked:
			btn.disabled = false
			btn.modulate = Color(1, 1, 1)
		else:
			btn.disabled = true
			btn.modulate = Color(0.4, 0.4, 0.4)

func _on_level_selected(level: int):
	selected_level = level
	Global.selected_level = level
	Global.selected_map = LEVEL_DATA[level]["map"]
	get_tree().change_scene_to_file("res://scenes/game.tscn")

func _on_daily_challenge():
	Global.selected_level = 1
	Global.selected_map = "res://scenes/maps/map_1.tscn"
	Global.is_daily_challenge = true
	get_tree().change_scene_to_file("res://scenes/game.tscn")

func _on_back():
	get_tree().change_scene_to_file("res://scenes/ui/main_menu.tscn")

func _load_save():
	var f = FileAccess.open("user://save.dat", FileAccess.READ)
	if f:
		var data = JSON.parse_string(f.get_as_text())
		if data:
			save_data = data
		f.close()
