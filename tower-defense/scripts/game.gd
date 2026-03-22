extends Node2D

const LD = {
	1: {"n": "新手村", "w": 10, "g": 200, "l": 20, "e": ["normal","fast"], "si": 1.5, "wm": 1.0, "bw": 5, "bt": "boss_normal", "r": 100},
	2: {"n": "森林要塞", "w": 10, "g": 300, "l": 25, "e": ["normal","fast","armor"], "si": 1.3, "wm": 1.3, "bw": 5, "bt": "boss_armor", "r": 200},
	3: {"n": "魔法山谷", "w": 10, "g": 400, "l": 30, "e": ["normal","fast","armor","magic_resist"], "si": 1.2, "wm": 1.6, "bw": 5, "bt": "boss_magic", "r": 350},
	4: {"n": "钢铁前线", "w": 10, "g": 500, "l": 35, "e": ["normal","fast","armor","magic_resist"], "si": 1.0, "wm": 2.0, "bw": 5, "bt": "boss_armor", "r": 500},
	5: {"n": "最终决战", "w": 10, "g": 600, "l": 40, "e": ["normal","fast","armor","magic_resist"], "si": 0.8, "wm": 2.5, "bw": 5, "bt": "boss_final", "r": 1000}
}
const BD = {
	"boss_normal": {"n": "哥布林首领", "m": 10, "s": 0.7, "r": 100, "sz": 2.0},
	"boss_armor": {"n": "铁甲巨兽", "m": 20, "s": 0.5, "r": 150, "sz": 2.5},
	"boss_magic": {"n": "黑暗法师", "m": 15, "s": 0.6, "r": 150, "sz": 2.0},
	"boss_final": {"n": "龙领主", "m": 30, "s": 0.8, "r": 300, "sz": 3.0}
}
func LVL(x): return LD.get(x, LD[1])
func BOS(x): return BD.get(x, BD["boss_normal"])

var gold: int = 200
var lives: int = 20
var wave: int = 0
var selected_level: int = 1
var game_over: bool = false
var wave_in_progress: bool = false
var selected_tower_type: String = ""
var towers: Array = []
var enemies: Array = []
var projectiles: Array = []
var level_progress: Array = [1]
var showing_level_select: bool = false

var path_points: Array = [
	Vector2(-50, 360), Vector2(200, 360), Vector2(200, 550),
	Vector2(450, 550), Vector2(450, 200), Vector2(700, 200),
	Vector2(700, 400), Vector2(950, 400), Vector2(950, 300),
	Vector2(1150, 300), Vector2(1300, 300)
]

const TOWER_TYPES = {
	"arrow": {"cost": 50, "damage": 10, "range": 150, "fire_rate": 1.2, "color": Color(0.2, 0.6, 0.2), "name": "箭塔"},
	"cannon": {"cost": 100, "damage": 30, "range": 120, "fire_rate": 0.5, "color": Color(0.8, 0.4, 0.1), "name": "炮塔"},
	"magic": {"cost": 80, "damage": 15, "range": 180, "fire_rate": 0.8, "color": Color(0.4, 0.2, 0.8), "name": "魔塔"}
}

const ENEMY_TYPES = {
	"normal": {"health": 100, "speed": 100, "reward": 10, "armor": 0, "magic_resist": 0, "name": "普通", "icon": "👹"},
	"armor": {"health": 200, "speed": 60, "reward": 25, "armor": 0.5, "magic_resist": 0, "name": "装甲", "icon": "🛡️"},
	"magic_resist": {"health": 120, "speed": 90, "reward": 20, "armor": 0, "magic_resist": 0.5, "name": "魔抗", "icon": "🔮"},
	"fast": {"health": 60, "speed": 160, "reward": 15, "armor": 0, "magic_resist": 0, "name": "快速", "icon": "⚡"}
}

const MAX_LEVEL = 3

func _ready():
	randomize()
	_setup_buttons()
	_start_level(1)

func _setup_buttons():
	# 塔按钮
	$UI/TowerArrow.pressed.connect(_on_arrow.bind())
	$UI/TowerCannon.pressed.connect(_on_cannon.bind())
	$UI/TowerMagic.pressed.connect(_on_magic.bind())
	$UI/StartWaveButton.pressed.connect(_on_start_wave.bind())
	$UI/LevelButton.pressed.connect(_on_show_levels.bind())
	
	# 关卡按钮
	for i in range(1, 6):
		var btn = $UI.get_node_or_null("LevelPanel/VBox/Grid/Level%d" % i)
		if btn:
			var n = i
			btn.pressed.connect(_on_select_level.bind(n))

func _start_level(level_num: int):
	selected_level = level_num
	var data = LVL(level_num)
	gold = data["g"]
	lives = data["l"]
	wave = 0
	game_over = false
	wave_in_progress = false
	selected_tower_type = ""
	towers = []
	enemies = []
	projectiles = []
	
	for t in get_tree().get_nodes_in_group("towers"): t.queue_free()
	for e in get_tree().get_nodes_in_group("enemies"): e.queue_free()
	for p in get_tree().get_nodes_in_group("projectiles"): p.queue_free()
	
	_update_ui()

func _on_arrow(): _select_tower("arrow")
func _on_cannon(): _select_tower("cannon")
func _on_magic(): _select_tower("magic")

func _select_tower(type: String):
	if selected_tower_type == type:
		selected_tower_type = ""
	else:
		selected_tower_type = type
	_update_tower_buttons()

func _update_tower_buttons():
	var colors = {"arrow": Color(0.2, 0.6, 0.2), "cannon": Color(0.8, 0.4, 0.1), "magic": Color(0.4, 0.2, 0.8)}
	var btns = {"arrow": $UI/TowerArrow, "cannon": $UI/TowerCannon, "magic": $UI/TowerMagic}
	for t in ["arrow", "cannon", "magic"]:
		btns[t].modulate = colors[t] if selected_tower_type == t else Color(1, 1, 1)

func _on_start_wave():
	if game_over or showing_level_select:
		return
	if wave_in_progress:
		return
	if wave >= LVL(selected_level)["w"]:
		show_msg("已通关！")
		return
	wave += 1
	wave_in_progress = true
	show_msg("第%d波来袭！" % wave)
	_update_ui()
	var ld = LVL(selected_level)
	var count = 5 + wave * 2
	for i in range(count):
		await get_tree().create_timer(ld["si"]).timeout
		_spawn_enemy(wave, ld)

func _spawn_enemy(wave_num: int, ld):
	var etype = ld["e"][randi() % ld["e"].size()]
	var edata = ENEMY_TYPES[etype]
	var scene = load("res://scenes/enemy.tscn")
	var e = scene.instantiate()
	e.enemy_type = etype
	e.max_health = edata.health * ld["wm"]
	e.health = e.max_health
	e.speed = edata.speed
	e.reward = edata.reward + wave_num * 2
	e.armor = edata.armor
	e.magic_resist = edata.magic_resist
	e.enemy_name = edata.name
	e.enemy_icon = edata.icon
	e.path_index = 0
	e.path_progress = 0
	e.reached_end = false
	e.add_to_group("enemies")
	add_child(e)
	enemies.append(e)

func _on_show_levels():
	showing_level_select = true
	$UI/LevelSelectBG.visible = true
	$UI/LevelPanel.visible = true
	_update_level_buttons()

func _on_select_level(n):
	showing_level_select = false
	$UI/LevelSelectBG.visible = false
	$UI/LevelPanel.visible = false
	_start_level(n)
	show_msg("第%d关：%s" % [n, LVL(n)["n"]])

func _update_level_buttons():
	for i in range(1, 6):
		var btn = $UI.get_node_or_null("LevelPanel/VBox/Grid/Level%d" % i)
		if btn:
			btn.disabled = false
			if i in level_progress:
				btn.modulate = Color(0.3, 0.8, 0.3)
			elif i <= level_progress[-1] + 1:
				btn.modulate = Color(1, 1, 1)
			else:
				btn.modulate = Color(0.4, 0.4, 0.4)
				btn.disabled = true

func _input(event: InputEvent):
	if event is InputEventScreenTouch:
		if event.pressed:
			var pos = event.position
			_handle_tap(pos)

func _handle_tap(pos: Vector2):
	if showing_level_select:
		return
	
	# 底部UI区域不响应
	if pos.y > 620:
		return
	
	# 左下角塔按钮
	if pos.x < 430 and pos.y > 340:
		return
	
	# 放置或升级
	if selected_tower_type != "":
		_attempt_place(pos)
	else:
		_attempt_upgrade(pos)

func _attempt_place(pos: Vector2):
	var td = TOWER_TYPES.get(selected_tower_type)
	if not td or gold < td.cost:
		show_msg("金币不足！")
		return
	if not _valid_pos(pos):
		show_msg("位置无效！")
		return
	for t in towers:
		if t and is_instance_valid(t) and t.global_position.distance_to(pos) < 50:
			show_msg("太近了！")
			return
	gold -= td.cost
	var tower = _create_tower(selected_tower_type, pos)
	towers.append(tower)
	_update_ui()

func _attempt_upgrade(pos: Vector2):
	for t in towers:
		if t and is_instance_valid(t) and t.global_position.distance_to(pos) < 35:
			if t.level >= MAX_LEVEL:
				show_msg("已满级！")
				return
			var cost = int(TOWER_TYPES[t.tower_type].cost * 0.5 * t.level)
			if gold < cost:
				show_msg("金币不足！")
				return
			gold -= cost
			t.upgrade()
			show_msg("升级成功！")
			_update_ui()
			return

func _valid_pos(pos: Vector2) -> bool:
	if pos.y < 80 or pos.y > 340 or pos.x < 50 or pos.x > 1150:
		return false
	for i in range(path_points.size() - 1):
		var dist = _dist_to_seg(pos, path_points[i], path_points[i+1])
		if dist < 50:
			return false
	return true

func _dist_to_seg(p, a, b) -> float:
	var ap = p - a
	var ab = b - a
	var t = clamp(ap.dot(ab) / ab.dot(ab), 0, 1)
	return p.distance_to(a + ab * t)

func _create_tower(type: String, pos: Vector2) -> Node2D:
	var scene = load("res://scenes/tower.tscn")
	var t = scene.instantiate()
	t.tower_type = type
	t.level = 1
	t.setup(TOWER_TYPES[type], pos)
	t.add_to_group("towers")
	add_child(t)
	return t

func _process(_d: float):
	if game_over or showing_level_select:
		return
	
	var to_rm = []
	for e in enemies:
		if e and is_instance_valid(e):
			e.move_along_path(path_points)
			if e.reached_end:
				lives -= 1
				to_rm.append(e)
				_update_ui()
				if lives <= 0:
					_trigger_game_over()
		else:
			to_rm.append(e)
	for e in to_rm:
		enemies.erase(e)
		if e and is_instance_valid(e): e.queue_free()
	
	for t in towers:
		if t and is_instance_valid(t):
			t.find_target(enemies)
			t.fire_if_ready()
	
	to_rm.clear()
	for p in projectiles:
		if p and is_instance_valid(p):
			p.move_projectile()
			if p.hit or p.expired:
				to_rm.append(p)
	for p in to_rm:
		projectiles.erase(p)
		if p and is_instance_valid(p): p.queue_free()
	
	if wave_in_progress and enemies.is_empty() and not game_over:
		_on_wave_done()

func _on_wave_done():
	var ld = LVL(selected_level)
	if wave >= ld["w"]:
		gold += ld["r"]
		if selected_level < 5 and not (selected_level + 1 in level_progress):
			level_progress.append(selected_level + 1)
		show_msg("🎉 通关！+%d金币" % ld["r"])
		wave_in_progress = false
	else:
		wave_in_progress = false
		gold += 50
		show_msg("波次完成！+50金币")
	_update_ui()

func _trigger_game_over():
	game_over = true
	show_msg("游戏结束！")
	$UI/GameOverPanel.visible = true

func _update_ui():
	$UI/TopBar/HBox/GoldLabel.text = "💰 %d" % gold
	$UI/TopBar/HBox/LivesLabel.text = "❤️ %d" % lives
	$UI/TopBar/HBox/WaveLabel.text = "🌊 %d/%d" % [wave, LVL(selected_level)["w"]]
	$UI/TopBar/HBox/LevelName.text = LVL(selected_level)["n"]

func show_msg(msg: String):
	$UI/MessageLabel.text = msg
	$UI/MessageLabel.visible = true
	$UI/MessageLabel/Timer.start(3.0)
