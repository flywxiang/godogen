extends Node2D

# 关卡数据
const LD = {
	1: {"n": "新手村", "w": 10, "g": 200, "l": 20, "e": ["normal","fast"], "si": 1.5, "wm": 1.0, "bw": 5, "bt": "boss_normal", "r": 100, "d": "训练场"},
	2: {"n": "森林要塞", "w": 10, "g": 300, "l": 25, "e": ["normal","fast","armor"], "si": 1.3, "wm": 1.3, "bw": 5, "bt": "boss_armor", "r": 200, "d": "装甲敌人"},
	3: {"n": "魔法山谷", "w": 10, "g": 400, "l": 30, "e": ["normal","fast","armor","magic_resist"], "si": 1.2, "wm": 1.6, "bw": 5, "bt": "boss_magic", "r": 350, "d": "魔抗敌人"},
	4: {"n": "钢铁前线", "w": 10, "g": 500, "l": 35, "e": ["normal","fast","armor","magic_resist"], "si": 1.0, "wm": 2.0, "bw": 5, "bt": "boss_armor", "r": 500, "d": "全面强化"},
	5: {"n": "最终决战", "w": 10, "g": 600, "l": 40, "e": ["normal","fast","armor","magic_resist"], "si": 0.8, "wm": 2.5, "bw": 5, "bt": "boss_final", "r": 1000, "d": "最终BOSS"}
}
const BD = {
	"boss_normal": {"n": "哥布林首领", "m": 10, "s": 0.7, "r": 100, "sz": 2.0},
	"boss_armor": {"n": "铁甲巨兽", "m": 20, "s": 0.5, "r": 150, "sz": 2.5},
	"boss_magic": {"n": "黑暗法师", "m": 15, "s": 0.6, "r": 150, "sz": 2.0},
	"boss_final": {"n": "龙领主", "m": 30, "s": 0.8, "r": 300, "sz": 3.0}
}
func LVL(x): return LD.get(x, LD[1])
func BOS(x): return BD.get(x, BD["boss_normal"])

# Game State
var gold: int = 200
var lives: int = 20
var wave: int = 0
var current_level: int = 1
var game_over: bool = false
var wave_in_progress: bool = false
var selected_tower_type: String = ""
var towers: Array = []
var enemies: Array = []
var projectiles: Array = []
var level_progress: Array = []  # 已通过的关卡
var selected_level: int = 1
var showing_level_select: bool = true
var level_completed: bool = false
var boss_spawned: bool = false
var boss: Node = null

# Path waypoints
var path_points: Array = [
	Vector2(0, 300), Vector2(200, 300), Vector2(200, 500),
	Vector2(500, 500), Vector2(500, 200), Vector2(800, 200),
	Vector2(800, 400), Vector2(1100, 400), Vector2(1100, 300),
	Vector2(1300, 300)
]

# Tower definitions
const TOWER_TYPES = {
	"arrow": {"cost": 50, "damage": 10, "range": 150, "fire_rate": 1.2, "color": Color(0.2, 0.6, 0.2), "name": "箭塔", "damage_type": "physical", "effective_against": "light"},
	"cannon": {"cost": 100, "damage": 30, "range": 120, "fire_rate": 0.5, "color": Color(0.8, 0.4, 0.1), "name": "炮塔", "damage_type": "explosive", "effective_against": "armor"},
	"magic": {"cost": 80, "damage": 15, "range": 180, "fire_rate": 0.8, "color": Color(0.4, 0.2, 0.8), "name": "魔塔", "damage_type": "magic", "effective_against": "fast"}
}

# Enemy types
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
@onready var path_line: Line2D = $PathLine
@onready var level_select: Control = $UI/LevelSelect
@onready var level_select_panel: Control = $UI/LevelSelect/LevelSelectPanel

func _ready() -> void:
	randomize()
	path_line = $PathLine
	_setup_path()
	_setup_level_progress()
	show_level_select()
	_update_ui()

func _setup_path() -> void:
	path_line.clear_points()
	for point in path_points:
		path_line.add_point(point)

func _setup_level_progress() -> void:
	# 加载保存的进度
	var save_file = FileAccess.open("user://level_progress.save", FileAccess.READ)
	if save_file:
		var data = JSON.parse_string(save_file.get_as_text())
		if data:
			level_progress = data
		save_file.close()
	else:
		level_progress = [1]  # 默认解锁第1关

func save_level_progress() -> void:
	var save_file = FileAccess.open("user://level_progress.save", FileAccess.WRITE)
	if save_file:
		save_file.store_string(JSON.stringify(level_progress))
		save_file.close()

func show_level_select() -> void:
	showing_level_select = true
	level_select.visible = true
	level_select_panel.visible = true
	update_level_buttons()

func hide_level_select() -> void:
	showing_level_select = false
	level_select.visible = false
	level_select_panel.visible = false

func update_level_buttons() -> void:
	for i in range(1, 6):
		var btn = level_select.find_child("Level%d" % i, true, false)
		if btn:
			var level_data = LVL(i)
			btn.text = "第%d关\n%s\n%s" % [i, level_data["n"], level_data["d"]]
			
			# 设置颜色
			if i in level_progress:
				btn.modulate = Color(0.7, 1, 0.7)  # 已通过-绿色
			elif i <= level_progress[-1] + 1:
				btn.modulate = Color(1, 1, 1)  # 可进入-白色
			else:
				btn.modulate = Color(0.4, 0.4, 0.4)  # 锁定-灰色

func select_level(level_num: int) -> void:
	if level_num > level_progress[-1] + 1:
		show_message("请先通关前面的关卡！")
		return
	
	selected_level = level_num
	var data = LVL(level_num)
	
	gold = data["g"]
	lives = data["l"]
	wave = 0
	game_over = false
	wave_in_progress = false
	boss_spawned = false
	towers = []
	enemies = []
	projectiles = []
	
	# 清理旧敌人和塔
	for t in get_tree().get_nodes_in_group("towers"):
		t.queue_free()
	for e in get_tree().get_nodes_in_group("enemies"):
		e.queue_free()
	for p in get_tree().get_nodes_in_group("projectiles"):
		p.queue_free()
	
	hide_level_select()
	show_message("第%d关：%s 开始！" % [level_num, data["n"]])
	_update_ui()

func _process(_delta: float) -> void:
	if game_over or showing_level_select:
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
		_on_wave_complete()

func _on_wave_complete() -> void:
	var level_data = LVL(selected_level)
	
	if wave >= level_data["w"]:
		# 关卡完成
		level_completed = true
		show_message("🎉 第%d关通关！奖励 %d 金币！" % [selected_level, level_data["r"]])
		gold += level_data["r"]
		
		# 解锁下一关
		if selected_level < 5:
			var next_level = selected_level + 1
			if not next_level in level_progress:
				level_progress.append(next_level)
				save_level_progress()
				show_message("🎊 解锁第%d关：%s！" % [next_level, LVL(next_level)["n"]])
		else:
			show_message("🏆 恭喜通关所有关卡！你是大师！")
		
		wave_in_progress = false
		level_completed = true
	else:
		wave_in_progress = false
		gold += 50
		show_message("波次 %d 完成！+50 金币" % wave)
	
	_update_ui()

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		if not showing_level_select and not game_over:
			show_level_select()
			return
	
	if game_over or showing_level_select:
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
	show_message("%s 已放置！" % tower_data["n"])
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
	tower.add_to_group("towers")
	add_child(tower)
	return tower

func start_wave() -> void:
	if showing_level_select or level_completed:
		show_level_select()
		return
	
	if wave_in_progress:
		show_message("波次进行中！")
		return
	
	wave += 1
	wave_in_progress = true
	boss_spawned = false
	
	var level_data = LVL(selected_level)
	show_message("第 %d 波来袭！" % wave)
	_update_ui()
	
	# 检查是否BOSS波
	if wave == level_data["bw"]:
		spawn_boss(level_data["bt"])
	else:
		var enemy_count = 5 + wave * 2
		var spawn_delay = level_data["si"]
		for i in range(enemy_count):
			await get_tree().create_timer(spawn_delay).timeout
			spawn_enemy(wave, level_data)

func spawn_enemy(wave_num: int, level_data: Dictionary) -> void:
	var enemy_scene = load("res://scenes/enemy.tscn")
	var enemy = enemy_scene.instantiate()
	
	var enemy_type = _choose_enemy_type(wave_num, level_data["e"])
	var type_data = ENEMY_TYPES[enemy_type]
	
	enemy.enemy_type = enemy_type
	enemy.max_health = type_data.health * level_data["wm"]
	enemy.health = enemy.max_health
	enemy.speed = type_data.speed
	enemy.reward = type_data.reward + wave_num * 2
	enemy.armor = type_data.armor
	enemy.magic_resist = type_data.magic_resist
	enemy.enemy_name = type_data["n"]
	enemy.enemy_icon = type_data.icon
	enemy.path_index = 0
	enemy.path_progress = 0.0
	enemy.reached_end = false
	enemy.add_to_group("enemies")
	
	add_child(enemy)
	enemies.append(enemy)

func spawn_boss(boss_type: String) -> void:
	var boss_data = BOS(boss_type)
	
	var enemy_scene = load("res://scenes/enemy.tscn")
	var boss_enemy = enemy_scene.instantiate()
	
	boss_enemy.enemy_type = boss_type
	boss_enemy.enemy_name = boss_data["n"]
	boss_enemy.enemy_icon = "👑"
	boss_enemy.max_health = 500 * boss_data["m"] * LVL(selected_level)["wm"]
	boss_enemy.health = boss_enemy.max_health
	boss_enemy.speed = 50 * boss_data["s"]
	boss_enemy.reward = boss_data["r"]
	boss_enemy.armor = 0.7
	boss_enemy.magic_resist = 0.5
	boss_enemy.path_index = 0
	boss_enemy.path_progress = 0.0
	boss_enemy.reached_end = false
	boss_enemy.is_boss = true
	boss_enemy.boss_data = boss_data
	boss_enemy.add_to_group("enemies")
	boss_enemy.scale = Vector2(boss_data["sz"], boss_data["sz"])
	
	add_child(boss_enemy)
	enemies.append(boss_enemy)
	boss = boss_enemy
	boss_spawned = true
	
	show_message("⚠️ BOSS来袭：%s ！" % boss_data["n"])

func _choose_enemy_type(wave_num: int, allowed_types: Array) -> String:
	var roll = randf()
	
	if wave_num >= 3 and "armor" in allowed_types and roll < 0.2:
		return "armor"
	elif wave_num >= 2 and "magic_resist" in allowed_types and roll < 0.15:
		return "magic_resist"
	elif wave_num >= 1 and "fast" in allowed_types and roll < 0.25:
		return "fast"
	
	return "normal"

func trigger_game_over() -> void:
	game_over = true
	show_message("游戏结束！第 %d 波失败" % wave)
	$UI/GameOverPanel.visible = true

func restart_level() -> void:
	select_level(selected_level)

func return_to_menu() -> void:
	show_level_select()

func _update_ui() -> void:
	gold_label.text = "💰 金币: %d" % gold
	lives_label.text = "❤️ 生命: %d" % lives
	wave_label.text = "🌊 波次: %d/%d" % [wave, LVL(selected_level)["w"]]

func show_message(msg: String) -> void:
	message_label.text = msg
	message_label.visible = true
	await get_tree().create_timer(3.0).timeout
	message_label.visible = false
