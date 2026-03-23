extends CanvasLayer

var selected_level: int = 1

func _ready():
	_setup_buttons()

func _setup_buttons():
	$LevelContainer/Level1.mouse_filter = Control.MOUSE_FILTER_STOP
	$LevelContainer/Level2.mouse_filter = Control.MOUSE_FILTER_STOP
	$LevelContainer/Level3.mouse_filter = Control.MOUSE_FILTER_STOP
	$LevelContainer/Level4.mouse_filter = Control.MOUSE_FILTER_STOP
	$LevelContainer/Level5.mouse_filter = Control.MOUSE_FILTER_STOP
	
	$LevelContainer/Level1.gui_input.connect(_on_level_click.bind(1))
	$LevelContainer/Level2.gui_input.connect(_on_level_click.bind(2))
	$LevelContainer/Level3.gui_input.connect(_on_level_click.bind(3))
	$LevelContainer/Level4.gui_input.connect(_on_level_click.bind(4))
	$LevelContainer/Level5.gui_input.connect(_on_level_click.bind(5))
	
	$BackBtn.pressed.connect(_on_back)

func _on_level_click(event: InputEvent, level: int):
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_start_level(level)

func _start_level(level: int):
	Global.selected_level = level
	match level:
		1: Global.selected_map = "res://scenes/maps/map_1.tscn"
		2: Global.selected_map = "res://scenes/maps/map_2.tscn"
		3: Global.selected_map = "res://scenes/maps/map_3.tscn"
		4: Global.selected_map = "res://scenes/maps/map_4.tscn"
		5: Global.selected_map = "res://scenes/maps/map_5.tscn"
	get_tree().change_scene_to_file("res://scenes/game.tscn")

func _on_back():
	get_tree().change_scene_to_file("res://scenes/ui/main_menu.tscn")
