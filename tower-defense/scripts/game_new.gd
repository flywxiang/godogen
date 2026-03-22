extends Node2D

var current_map: Node2D = null
var enemies: Array = []
var towers: Array = []
var gold: int = 200
var lives: int = 20
var wave: int = 0
var max_waves: int = 10
var wave_in_progress: bool = false
var game_over: bool = false
var selected_tower_type: String = ""

const TOWER_TYPES = {
	"arrow": {"cost": 50, "damage": 10, "range": 150, "fire_rate": 1.2, "color": Color(0.2, 0.6, 0.2)},
	"cannon": {"cost": 100, "damage": 30, "range": 120, "fire_rate": 0.5, "color": Color(0.8, 0.4, 0.1)},
	"magic": {"cost": 80, "damage": 15, "range": 180, "fire_rate": 0.8, "color": Color(0.4, 0.2, 0.8)}
}

const ENEMY_TYPES = {
	"normal": {"health": 100, "speed": 100, "reward": 10},
	"fast": {"health": 60, "speed": 160, "reward": 15},
	"armor": {"health": 200, "speed": 60, "reward": 25},
	"magic_resist": {"health": 120, "speed": 90, "reward": 20}
}

func _ready():
	randomize()
	_setup_buttons()
	_load_map()

func _setup_buttons():
	$UI/TowerPanel/TowerArrow.pressed.connect(_on_select_arrow)
	$UI/TowerPanel/TowerCannon.pressed.connect(_on_select_cannon)
	$UI/TowerPanel/TowerMagic.pressed.connect(_on_select_magic)
	$UI/StartWaveButton.pressed.connect(_on_start_wave)
	$UI/BackButton.pressed.connect(_on_back)
	$UI/PauseButton.pressed.connect(_on_pause)
	$UI/ShopButton.pressed.connect(_on_shop)

func _load_map():
	var map_path = Global.selected_map
	if map_path.is_empty():
		map_path = "res://scenes/maps/map_1.tscn"
	
	var map_scene = load(map_path)
	if map_scene:
		current_map = map_scene.instantiate()
		$MapContainer.add_child(current_map)
		
		# 更新UI显示地图名
		if current_map.has("map_name"):
			$UI/TopBar/HBox/LevelName.text = current_map.map_name
	else:
		print("Failed to load map: ", map_path)
	
	_update_ui()

func _process(_delta: float):
	if game_over or wave_in_progress:
		return
	
	# 更新敌人位置
	for e in enemies:
		if is_instance_valid(e):
			e.move_along_path(current_map.get_path_points() if current_map else [])

func _input(event: InputEvent):
	if event is InputEventScreenTouch and event.pressed:
		var pos = event.position
		if selected_tower_type != "" and pos.y < 600:
			_place_tower(pos)

func _on_select_arrow():
	selected_tower_type = "arrow"
	_update_tower_buttons()

func _on_select_cannon():
	selected_tower_type = "cannon"
	_update_tower_buttons()

func _on_select_magic():
	selected_tower_type = "magic"
	_update_tower_buttons()

func _update_tower_buttons():
	var colors = {"arrow": Color(0.2, 0.6, 0.2), "cannon": Color(0.8, 0.4, 0.1), "magic": Color(0.4, 0.2, 0.8)}
	var btns = {"arrow": $UI/TowerPanel/TowerArrow, "cannon": $UI/TowerPanel/TowerCannon, "magic": $UI/TowerPanel/TowerMagic}
	for t in ["arrow", "cannon", "magic"]:
		btns[t].modulate = colors[t] if selected_tower_type == t else Color(1, 1, 1)

func _place_tower(pos: Vector2):
	var td = TOWER_TYPES.get(selected_tower_type)
	if not td or gold < td.cost:
		show_msg("金币不足！")
		return
	
	gold -= td.cost
	var tower = Node2D.new()
	tower.position = pos
	
	var rect = ColorRect.new()
	rect.size = Vector2(40, 40)
	rect.color = td.color
	tower.add_child(rect)
	
	tower.set("tower_type", selected_tower_type)
	tower.set("damage", td.damage)
	tower.set("range", td.range)
	tower.set("fire_rate", td.fire_rate)
	tower.set("fire_cooldown", 0.0)
	
	add_child(tower)
	towers.append(tower)
	_update_ui()
	show_msg("塔已放置！")

func _on_start_wave():
	if wave_in_progress or game_over:
		return
	if wave >= max_waves:
		show_msg("已通关！")
		return
	
	wave += 1
	wave_in_progress = true
	show_msg("第%d波来袭！" % wave)
	_update_ui()
	
	var enemy_count = 5 + wave * 2
	var spawn_interval = max(0.5, 1.5 - wave * 0.05)
	var enemy_types = ["normal", "fast", "armor", "magic_resist"]
	
	for i in range(enemy_count):
		await get_tree().create_timer(spawn_interval).timeout
		_spawn_enemy(enemy_types[randi() % enemy_types.size()])

func _spawn_enemy(type: String):
	var edata = ENEMY_TYPES.get(type, ENEMY_TYPES["normal"])
	var enemy = Node2D.new()
	
	var rect = ColorRect.new()
	rect.size = Vector2(30, 30)
	rect.color = Color(0.9, 0.3, 0.3)
	enemy.add_child(rect)
	
	enemy.set("enemy_type", type)
	enemy.set("max_health", edata.health)
	enemy.set("health", edata.health)
	enemy.set("speed", edata.speed)
	enemy.set("reward", edata.reward)
	enemy.set("path_index", 0)
	enemy.set("path_progress", 0.0)
	enemy.set("reached_end", false)
	enemy.set("move_timer", 0.0)
	
	add_child(enemy)
	enemies.append(enemy)

func move_along_path(path_points: Array):
	if path_points.is_empty():
		return
	
	var idx = self.get("path_index")
	var progress = self.get("path_progress")
	var spd = self.get("speed")
	
	if idx >= path_points.size() - 1:
		self.set("reached_end", true)
		return
	
	var p1 = path_points[idx]
	var p2 = path_points[idx + 1]
	var segment_length = p1.distance_to(p2)
	
	progress += spd * get_process_delta_time()
	
	if progress >= segment_length:
		progress -= segment_length
		idx += 1
		if idx >= path_points.size() - 1:
			self.set("reached_end", true)
			return
	
	var t = progress / segment_length if segment_length > 0 else 0
	global_position = p1.lerp(p2, t)
	
	self.set("path_index", idx)
	self.set("path_progress", progress)

func _on_back():
	get_tree().change_scene_to_file("res://scenes/ui/level_select.tscn")

func _on_pause():
	get_tree().paused = !get_tree().paused
	show_msg("暂停" if get_tree().paused else "继续")

func _on_shop():
	show_msg("商店功能开发中...")

func _update_ui():
	$UI/TopBar/HBox/GoldLabel.text = "💰 %d" % gold
	$UI/TopBar/HBox/LivesLabel.text = "❤️ %d" % lives
	$UI/TopBar/HBox/WaveLabel.text = "🌊 %d/%d" % [wave, max_waves]

func show_msg(msg: String):
	$UI/MessageLabel.text = msg
	$UI/MessageLabel.visible = true
