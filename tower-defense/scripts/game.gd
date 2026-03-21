extends Node2D

# Game State
var gold: int = 200
var lives: int = 20
var wave: int = 0
var game_over: bool = false
var wave_in_progress: bool = false
var selected_tower_type: String = ""
var towers: Array = []
var enemies: Array = []
var projectiles: Array = []

# Path waypoints
var path_points: Array = [
	Vector2(0, 300), Vector2(200, 300), Vector2(200, 500),
	Vector2(500, 500), Vector2(500, 200), Vector2(800, 200),
	Vector2(800, 400), Vector2(1100, 400), Vector2(1100, 300),
	Vector2(1300, 300)
]

# Tower definitions with damage types
const TOWER_TYPES = {
	"arrow": {
		"cost": 50, "damage": 10, "range": 150, "fire_rate": 1.2, 
		"color": Color(0.2, 0.6, 0.2), "name": "箭塔",
		"damage_type": "physical", "effective_against": "light"
	},
	"cannon": {
		"cost": 100, "damage": 30, "range": 120, "fire_rate": 0.5, 
		"color": Color(0.8, 0.4, 0.1), "name": "炮塔",
		"damage_type": "explosive", "effective_against": "armor"
	},
	"magic": {
		"cost": 80, "damage": 15, "range": 180, "fire_rate": 0.8, 
		"color": Color(0.4, 0.2, 0.8), "name": "魔塔",
		"damage_type": "magic", "effective_against": "fast"
	}
}

# Enemy types with resistances
const ENEMY_TYPES = {
	"normal": {"health": 100, "speed": 100, "reward": 10, "armor": 0, "magic_resist": 0, "name": "普通", "icon": "👹"},
	"armor": {"health": 200, "speed": 60, "reward": 25, "armor": 0.5, "magic_resist": 0, "name": "装甲", "icon": "🛡️"},
	"magic_resist": {"health": 120, "speed": 90, "reward": 20, "armor": 0, "magic_resist": 0.5, "name": "魔抗", "icon": "🔮"},
	"fast": {"health": 60, "speed": 160, "reward": 15, "armor": 0, "magic_resist": 0, "name": "快速", "icon": "⚡"}
}

# Upgrade system
const UPGRADE_COST_MULTIPLIER = 0.5
const UPGRADE_BONUS = 0.3
const MAX_LEVEL = 3

@onready var gold_label: Label = $UI/GoldLabel
@onready var lives_label: Label = $UI/LivesLabel
@onready var wave_label: Label = $UI/WaveLabel
@onready var message_label: Label = $UI/MessageLabel
@onready var tower_panel: Control = $UI/TowerPanel
@onready var path_line: Line2D = $PathLine

func _ready() -> void:
	randomize()
	path_line = $PathLine
	_setup_path()
	_update_ui()
	show_message("选择塔 → 点击放置 → 开始波次！")

func _setup_path() -> void:
	path_line.clear_points()
	for point in path_points:
		path_line.add_point(point)

func _process(_delta: float) -> void:
	if game_over:
		return
	
	# Update enemies
	var to_remove_enemies = []
	for enemy in enemies:
		if enemy and is_instance_valid(enemy):
			enemy.move_along_path(path_points)
			if enemy.reached_end:
				lives -= 1
				_update_ui()
				to_remove_enemies.append(enemy)
				if lives <= 0:
					trigger_game_over()
		else:
			to_remove_enemies.append(enemy)
	
	for enemy in to_remove_enemies:
		enemies.erase(enemy)
		if enemy and is_instance_valid(enemy):
			enemy.queue_free()
	
	# Update towers
	for tower in towers:
		if tower and is_instance_valid(tower):
			tower.find_target(enemies)
			tower.fire_if_ready()
	
	# Update projectiles
	var to_remove_projectiles = []
	for proj in projectiles:
		if proj and is_instance_valid(proj):
			proj.move_projectile()
			if proj.hit or proj.expired:
				to_remove_projectiles.append(proj)
		else:
			to_remove_projectiles.append(proj)
	
	for proj in to_remove_projectiles:
		projectiles.erase(proj)
		if proj and is_instance_valid(proj):
			proj.queue_free()
	
	# Check wave completion
	if wave_in_progress and enemies.is_empty() and not game_over:
		wave_in_progress = false
		show_message("波次 %d 完成！奖励 +50 金币" % wave)
		gold += 50
		_update_ui()

func _input(event: InputEvent) -> void:
	if game_over:
		return
	
	if event.is_action_pressed("place_tower") and selected_tower_type != "":
		var mouse_pos = get_global_mouse_position()
		attempt_place_tower(mouse_pos)
	
	if event.is_action_pressed("delete_tower"):
		var mouse_pos = get_global_mouse_position()
		attempt_remove_tower(mouse_pos)

func attempt_place_tower(pos: Vector2) -> bool:
	if selected_tower_type == "":
		return false
	
	var tower_data = TOWER_TYPES.get(selected_tower_type)
	if not tower_data:
		return false
	
	if gold < tower_data.cost:
		show_message("金币不足！需要 %d" % tower_data.cost)
		return false
	
	if not _is_valid_position(pos):
		show_message("不能放在这里！")
		return false
	
	for tower in towers:
		if tower and is_instance_valid(tower):
			if tower.global_position.distance_to(pos) < 40:
				show_message("离其他塔太近！")
				return false
	
	gold -= tower_data.cost
	var tower = _create_tower(selected_tower_type, pos)
	towers.append(tower)
	_update_ui()
	show_message("%s 已放置！" % tower_data.name)
	return true

func _is_valid_position(pos: Vector2) -> bool:
	if pos.x < 50 or pos.x > 1200 or pos.y < 50 or pos.y > 650:
		return false
	
	for i in range(path_points.size() - 1):
		var p1 = path_points[i]
		var p2 = path_points[i + 1]
		var dist = _distance_to_segment(pos, p1, p2)
		if dist < 35:
			return false
	
	return true

func _distance_to_segment(p: Vector2, a: Vector2, b: Vector2) -> float:
	var ap = p - a
	var ab = b - a
	var t = clamp(ap.dot(ab) / ab.dot(ab), 0, 1)
	var closest = a + ab * t
	return p.distance_to(closest)

func attempt_remove_tower(pos: Vector2) -> void:
	for tower in towers:
		if tower and is_instance_valid(tower):
			if tower.global_position.distance_to(pos) < 25:
				var base_cost = TOWER_TYPES[tower.tower_type].cost
				var level_refund = tower.level * base_cost * 0.3
				var total_refund = int(base_cost / 2 + level_refund)
				gold += total_refund
				towers.erase(tower)
				tower.queue_free()
				show_message("出售！返还 %d 金币" % total_refund)
				_update_ui()
				return

func attempt_upgrade_tower(pos: Vector2) -> void:
	for tower in towers:
		if tower and is_instance_valid(tower):
			if tower.global_position.distance_to(pos) < 25:
				if tower.level >= MAX_LEVEL:
					show_message("已满级！")
					return
				
				var base_cost = TOWER_TYPES[tower.tower_type].cost
				var upgrade_cost = int(base_cost * UPGRADE_COST_MULTIPLIER * tower.level)
				
				if gold < upgrade_cost:
					show_message("金币不足！需要 %d" % upgrade_cost)
					return
				
				gold -= upgrade_cost
				tower.upgrade()
				_update_ui()
				show_message("升级成功！%s Lv.%d" % [TOWER_TYPES[tower.tower_type].name, tower.level])
				return

func _create_tower(type: String, pos: Vector2) -> Node2D:
	var tower_scene = load("res://scenes/tower.tscn")
	var tower = tower_scene.instantiate()
	tower.tower_type = type
	tower.level = 1
	tower.setup(TOWER_TYPES[type], pos)
	add_child(tower)
	return tower

func start_wave() -> void:
	if wave_in_progress:
		show_message("波次进行中！")
		return
	
	wave += 1
	wave_in_progress = true
	show_message("第 %d 波来袭！" % wave)
	_update_ui()
	
	var enemy_count = 5 + wave * 2
	var spawn_delay = max(0.4, 1.5 - wave * 0.05)
	
	for i in range(enemy_count):
		await get_tree().create_timer(spawn_delay).timeout
		spawn_enemy(wave)

func spawn_enemy(wave_num: int) -> void:
	var enemy_scene = load("res://scenes/enemy.tscn")
	var enemy = enemy_scene.instantiate()
	
	# Choose enemy type based on wave
	var enemy_type = _choose_enemy_type(wave_num)
	var type_data = ENEMY_TYPES[enemy_type]
	
	enemy.enemy_type = enemy_type
	enemy.max_health = type_data.health * (1 + wave_num * 0.15)
	enemy.health = enemy.max_health
	enemy.speed = type_data.speed
	enemy.reward = type_data.reward + wave_num * 2
	enemy.armor = type_data.armor
	enemy.magic_resist = type_data.magic_resist
	enemy.enemy_name = type_data.name
	enemy.enemy_icon = type_data.icon
	enemy.path_index = 0
	enemy.path_progress = 0.0
	enemy.reached_end = false
	
	add_child(enemy)
	enemies.append(enemy)

func _choose_enemy_type(wave_num: int) -> String:
	var roll = randf()
	
	if wave_num >= 5:
		if roll < 0.2:
			return "armor"
		elif roll < 0.35:
			return "magic_resist"
		elif roll < 0.5:
			return "fast"
	elif wave_num >= 3:
		if roll < 0.25:
			return "armor"
		elif roll < 0.4:
			return "fast"
	else:
		if roll < 0.2:
			return "fast"
	
	return "normal"

func trigger_game_over() -> void:
	game_over = true
	show_message("游戏结束！坚守了 %d 波！" % wave)
	$UI/GameOverPanel.visible = true

func restart_game() -> void:
	get_tree().reload_current_scene()

func _update_ui() -> void:
	gold_label.text = "💰 金币: %d" % gold
	lives_label.text = "❤️ 生命: %d" % lives
	wave_label.text = "🌊 波次: %d" % wave

func show_message(msg: String) -> void:
	message_label.text = msg
	message_label.visible = true
	await get_tree().create_timer(3.0).timeout
	message_label.visible = false
