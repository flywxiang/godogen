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
var showing_shop: bool = false
var showing_pause: bool = false
var game_paused: bool = false
var kill_streak: int = 0
var kill_streak_timer: float = 0.0
var combo_count: int = 0

# 障碍物系统
var obstacles: Array = []
var selected_obstacle: String = ""
var obstacle_damage_timers: Dictionary = {}

# 每日挑战
var daily_challenge: Dictionary = {
	"level": 1,
	"bonus_gold": 500,
	"special_rule": "双倍伤害"
}

# 英雄系统
var hero: Node2D = null
var hero_unlocked: bool = false
var hero_xp: int = 0
var hero_level: int = 1
var hero_skills_unlocked: Array = []
var hero_damage: float = 20.0
var hero_cooldown: float = 0.0
var hero_range: float = 200.0
var hero_level_mult: float = 1.0

# 技能树
const SKILL_TREE = {
	"damage_1": {"name": "攻击强化I", "cost": 100, "desc": "所有塔伤害+10%", "unlocks": ["damage_2"]},
	"damage_2": {"name": "攻击强化II", "cost": 200, "desc": "所有塔伤害+20%", "unlocks": ["damage_3"]},
	"damage_3": {"name": "攻击强化III", "cost": 400, "desc": "所有塔伤害+40%", "unlocks": []},
	"range_1": {"name": "射程强化I", "cost": 100, "desc": "所有塔射程+10%", "unlocks": ["range_2"]},
	"range_2": {"name": "射程强化II", "cost": 200, "desc": "所有塔射程+20%", "unlocks": []},
	"speed_1": {"name": "攻速强化I", "cost": 100, "desc": "所有塔攻速+10%", "unlocks": ["speed_2"]},
	"speed_2": {"name": "攻速强化II", "cost": 200, "desc": "所有塔攻速+20%", "unlocks": []},
	"gold_1": {"name": "金币强化I", "cost": 150, "desc": "击杀金币+10%", "unlocks": ["gold_2"]},
	"gold_2": {"name": "金币强化II", "cost": 300, "desc": "击杀金币+25%", "unlocks": []},
	"hero_1": {"name": "英雄解锁", "cost": 500, "desc": "解锁英雄角色", "unlocks": ["hero_2"]},
	"hero_2": {"name": "英雄强化", "cost": 800, "desc": "英雄伤害+50%", "unlocks": []}
}

var skill_tree_unlocked: Array = []

const OBSTACLE_TYPES = {
	"rock": {"cost": 30, "name": "石头", "desc": "减速敌人50%", "color": Color(0.5, 0.5, 0.5)},
	"spike": {"cost": 50, "name": "地刺", "desc": "持续伤害", "color": Color(0.7, 0.3, 0.3)},
	"wall": {"cost": 40, "name": "围墙", "desc": "阻挡敌人", "color": Color(0.6, 0.4, 0.2)}
}

# Save data
var save_data: Dictionary = {
	"high_scores": {},
	"achievements": [],
	"total_gold": 0,
	"total_kills": 0,
	"daily_challenge": null,
	"endless_best_wave": 0,
	"daily_best_scores": {},
	"star_ratings": {},  # {"level_1": 3, "level_2": 2, ...}
	"daily_challenge_completed": false,
	"daily_challenge_date": ""
}

var endless_mode: bool = false
var endless_wave: int = 0
var endless_active: bool = false
var endless_in_progress: bool = false

var path_points: Array = [
	Vector2(-50, 360), Vector2(200, 360), Vector2(200, 550),
	Vector2(450, 550), Vector2(450, 200), Vector2(700, 200),
	Vector2(700, 400), Vector2(950, 400), Vector2(950, 300),
	Vector2(1150, 300), Vector2(1300, 300)
]

const TOWER_TYPES = {
	"arrow": {"cost": 50, "damage": 10, "range": 150, "fire_rate": 1.2, "color": Color(0.2, 0.6, 0.2), "name": "箭塔", "skill_name": "连射", "skill_desc": "攻速+50%"},
	"cannon": {"cost": 100, "damage": 30, "range": 120, "fire_rate": 0.5, "color": Color(0.8, 0.4, 0.1), "name": "炮塔", "skill_name": "爆炸", "skill_desc": "范围伤害"},
	"magic": {"cost": 80, "damage": 15, "range": 180, "fire_rate": 0.8, "color": Color(0.4, 0.2, 0.8), "name": "魔塔", "skill_name": "冰冻", "skill_desc": "减速+80%"}
}

const ENEMY_TYPES = {
	"normal": {"health": 100, "speed": 100, "reward": 10, "armor": 0, "magic_resist": 0, "name": "普通", "icon": "👹"},
	"armor": {"health": 200, "speed": 60, "reward": 25, "armor": 0.5, "magic_resist": 0, "name": "装甲", "icon": "🛡️"},
	"magic_resist": {"health": 120, "speed": 90, "reward": 20, "armor": 0, "magic_resist": 0.5, "name": "魔抗", "icon": "🔮"},
	"fast": {"health": 60, "speed": 160, "reward": 15, "armor": 0, "magic_resist": 0, "name": "快速", "icon": "⚡"},
	"shadow": {"health": 80, "speed": 120, "reward": 30, "armor": 0.1, "magic_resist": 0.1, "name": "暗影", "icon": "👻"},
	"healer": {"health": 150, "speed": 70, "reward": 35, "armor": 0, "magic_resist": 0, "name": "治疗", "icon": "💚"},
	"elite": {"health": 250, "speed": 80, "reward": 50, "armor": 0.3, "magic_resist": 0.3, "name": "精英", "icon": "⭐"}
}

const SHOP_ITEMS = {
	"heal": {"name": "生命药水", "cost": 50, "desc": "恢复20生命"},
	"shield": {"name": "护盾", "cost": 100, "desc": "免疫3波伤害"},
	"speed_up": {"name": "攻速光环", "cost": 80, "desc": "所有塔攻速+30%"},
	"damage_up": {"name": "力量光环", "cost": 120, "desc": "所有塔伤害+30%"}
}

const PLAYER_SKILLS = {
	"lightning": {"name": "⚡雷电", "cost": 0, "cooldown": 15.0, "desc": "对所有敌人造成伤害", "color": Color(0.9, 0.9, 0.2)},
	"freeze": {"name": "❄️冰冻", "cost": 0, "cooldown": 20.0, "desc": "冻结所有敌人3秒", "color": Color(0.4, 0.8, 1.0)},
	"heal": {"name": "💚治疗", "cost": 0, "cooldown": 30.0, "desc": "恢复30生命", "color": Color(0.2, 0.9, 0.4)}
}

var skill_cooldowns: Dictionary = {
	"lightning": 0.0,
	"freeze": 0.0,
	"heal": 0.0
}
var skill_active: String = ""

const ACHIEVEMENTS = {
	"first_blood": {"name": "初战告捷", "desc": "击杀第一个敌人", "reward": 20},
	"kill_10": {"name": "杀手", "desc": "击杀10个敌人", "reward": 50},
	"kill_100": {"name": "屠夫", "desc": "击杀100个敌人", "reward": 200},
	"wave_5": {"name": "小试牛刀", "desc": "完成第5波", "reward": 30},
	"wave_10": {"name": "波涛汹涌", "desc": "完成第10波", "reward": 100},
	"combo_5": {"name": "连杀达人", "desc": "5连杀", "reward": 50},
	"rich": {"name": "财大气粗", "desc": "拥有500金币", "reward": 30},
	"all_towers": {"name": "塔防大师", "desc": "同时拥有3种塔", "reward": 100}
}

const MAX_LEVEL = 3

func _ready():
	randomize()
	_load_save()
	_setup_buttons()
	_start_level(1)

func _setup_buttons():
	$UI/TowerArrow.pressed.connect(_on_arrow.bind())
	$UI/TowerCannon.pressed.connect(_on_cannon.bind())
	$UI/TowerMagic.pressed.connect(_on_magic.bind())
	$UI/StartWaveButton.pressed.connect(_on_start_wave.bind())
	$UI/StartEndlessButton.pressed.connect(_on_start_endless.bind())
	$UI/DailyChallengeButton.pressed.connect(_on_daily_challenge.bind())
	$UI/SkillTreeButton.pressed.connect(_on_show_skill_tree.bind())
	$UI/HeroButton.pressed.connect(_on_spawn_hero.bind())
	$UI/LevelButton.pressed.connect(_on_show_levels.bind())
	$UI/ShopButton.pressed.connect(_on_show_shop.bind())
	$UI/PauseButton.pressed.connect(_on_toggle_pause.bind())
	$UI/SkillLightning.pressed.connect(_on_skill_lightning.bind())
	$UI/SkillFreeze.pressed.connect(_on_skill_freeze.bind())
	$UI/SkillHeal.pressed.connect(_on_skill_heal.bind())
	$UI/ObstacleRock.pressed.connect(_on_obstacle_rock.bind())
	$UI/ObstacleSpike.pressed.connect(_on_obstacle_spike.bind())
	$UI/ObstacleWall.pressed.connect(_on_obstacle_wall.bind())
	
	for i in range(1, 6):
		var btn = $UI.get_node_or_null("LevelPanel/VBox/Grid/Level%d" % i)
		if btn:
			var n = i
			btn.pressed.connect(_on_select_level.bind(n))
	
	$UI/ShopPanel/VBox/HealButton.pressed.connect(_on_shop_heal.bind())
	$UI/ShopPanel/VBox/ShieldButton.pressed.connect(_on_shop_shield.bind())
	$UI/ShopPanel/VBox/SpeedButton.pressed.connect(_on_shop_speed.bind())
	$UI/ShopPanel/VBox/DamageButton.pressed.connect(_on_shop_damage.bind())
	$UI/ShopPanel/VBox/CloseButton.pressed.connect(_on_close_shop.bind())
	$UI/PausePanel/VBox/ResumeButton.pressed.connect(_on_toggle_pause.bind())
	$UI/PausePanel/VBox/RestartButton.pressed.connect(_on_restart.bind())
	$UI/PausePanel/VBox/MenuButton.pressed.connect(_on_show_levels.bind())
	$UI/FlashLayer/Timer.timeout.connect(_on_flash_timer.bind())
	$UI/SkillTreePanel/VBox/CloseButton.pressed.connect(_on_close_skill_tree.bind())
	$UI/SkillTreePanel/VBox/Skill1.pressed.connect(_on_unlock_skill.bind("damage_1"))
	$UI/SkillTreePanel/VBox/Skill2.pressed.connect(_on_unlock_skill.bind("range_1"))
	$UI/SkillTreePanel/VBox/Skill3.pressed.connect(_on_unlock_skill.bind("speed_1"))
	$UI/SkillTreePanel/VBox/Skill4.pressed.connect(_on_unlock_skill.bind("gold_1"))
	$UI/SkillTreePanel/VBox/Skill5.pressed.connect(_on_unlock_skill.bind("hero_1"))

func _load_save():
	var f = FileAccess.open("user://save.dat", FileAccess.READ)
	if f:
		var data = JSON.parse_string(f.get_as_text())
		if data:
			save_data = data
		f.close()
	
	# 生成今日挑战
	_generate_daily_challenge()

func _generate_daily_challenge():
	var today = Time.get_date_string_from_system()
	if save_data.get("daily_challenge_date", "") != today:
		# 随机生成每日挑战
		var levels = [1, 2, 3, 4, 5]
		var level = levels[randi() % levels.size()]
		var rules = ["双倍伤害", "无塔挑战", "极速模式", "生命守护", "金币翻倍"]
		var rule = rules[randi() % rules.size()]
		daily_challenge = {
			"level": level,
			"bonus_gold": 200 + level * 100,
			"special_rule": rule
		}
		save_data["daily_challenge_date"] = today
		save_data["daily_challenge_completed"] = false
		_save_game()

func _save_game():
	var f = FileAccess.open("user://save.dat", FileAccess.WRITE)
	if f:
		f.store_string(JSON.stringify(save_data))
		f.close()

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
	game_paused = false
	showing_pause = false
	showing_shop = false
	showing_level_select = false
	kill_streak = 0
	combo_count = 0
	
	for t in get_tree().get_nodes_in_group("towers"): t.queue_free()
	for e in get_tree().get_nodes_in_group("enemies"): e.queue_free()
	for p in get_tree().get_nodes_in_group("projectiles"): p.queue_free()
	
	_update_ui()
	_hide_all_panels()

func _hide_all_panels():
	$UI/LevelSelectBG.visible = false
	$UI/LevelPanel.visible = false
	$UI/ShopPanel.visible = false
	$UI/PausePanel.visible = false

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
	if endless_mode:
		_start_endless_wave()
		return
	if showing_level_select or showing_shop or showing_pause or game_over:
		return
	if game_paused:
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
		if not game_paused:
			_spawn_enemy(wave, ld)

func _on_start_endless():
	if wave_in_progress or endless_in_progress:
		show_msg("正在进行中！")
		return
	endless_mode = true
	endless_wave = 0
	endless_active = true
	gold = 100
	lives = 10
	wave = 0
	game_over = false
	_update_ui()
	_show_panel("")
	show_msg("⚡ 无尽模式开始！生存挑战！")
	_start_endless_wave()

func _on_daily_challenge():
	if save_data.get("daily_challenge_completed", false):
		show_msg("今日挑战已完成！明天再来！")
		return
	
	selected_level = daily_challenge["level"]
	_start_level(selected_level)
	gold += daily_challenge["bonus_gold"]
	show_msg("📅 每日挑战：%s！+%d金币" % [daily_challenge["special_rule"], daily_challenge["bonus_gold"]])
	_update_ui()

func _complete_daily_challenge():
	if not save_data.get("daily_challenge_completed", false):
		save_data["daily_challenge_completed"] = true
		gold += daily_challenge["bonus_gold"]
		show_msg("🎉 每日挑战完成！+%d金币" % daily_challenge["bonus_gold"])
		_save_game()

# 技能树系统
func _on_show_skill_tree():
	_show_panel("skilltree")

func _show_panel(name: String):
	_hide_all_panels()
	if name == "level":
		showing_level_select = true
		$UI/LevelSelectBG.visible = true
		$UI/LevelPanel.visible = true
		_update_level_buttons()
	elif name == "shop":
		showing_shop = true
		$UI/ShopPanel.visible = true
		_update_shop()
	elif name == "pause":
		showing_pause = true
		$UI/PausePanel.visible = true
	elif name == "skilltree":
		showing_shop = true
		$UI/SkillTreePanel.visible = true
		_update_skill_tree_panel()
	elif name == "skilltree":
		showing_shop = true
		$UI/SkillTreePanel.visible = true
		_update_skill_tree_panel()

func _update_skill_tree_panel():
	$UI/SkillTreePanel/VBox/GoldLabel.text = "💰 %d" % gold
	
	var keys = ["damage_1", "range_1", "speed_1", "gold_1", "hero_1"]
	var btns = ["Skill1", "Skill2", "Skill3", "Skill4", "Skill5"]
	
	for i in range(keys.size()):
		var key = keys[i]
		var btn = $UI/SkillTreePanel/VBox.get_node(btns[i])
		var skill = SKILL_TREE[key]
		var unlocked = key in skill_tree_unlocked
		
		if unlocked:
			btn.text = "✅ %s\n已解锁" % skill["name"]
			btn.disabled = true
			btn.modulate = Color(0.3, 0.8, 0.3)
		elif gold >= skill.cost:
			btn.text = "%s\n%d金币\n%s" % [skill["name"], skill.cost, skill["desc"]]
			btn.disabled = false
			btn.modulate = Color(1, 1, 1)
		else:
			btn.text = "%s\n%d金币\n%s" % [skill["name"], skill.cost, skill["desc"]]
			btn.disabled = true
			btn.modulate = Color(0.5, 0.5, 0.5)

# 英雄系统
func _on_spawn_hero():
	if not ("hero_1" in skill_tree_unlocked):
		show_msg("需要先解锁英雄！")
		return
	
	if hero and is_instance_valid(hero):
		show_msg("英雄已在场！")
		return
	
	hero = Node2D.new()
	hero_damage = 20.0
	hero_cooldown = 0.0
	hero_range = 200.0
	hero_level_mult = 1.0
	add_child(hero)
	
	# 英雄视觉
	var rect = ColorRect.new()
	rect.size = Vector2(40, 40)
	rect.color = Color(1.0, 0.5, 0.1)
	hero.add_child(rect)
	
	# 英雄标签
	var label = Label.new()
	label.text = "🦸"
	label.position = Vector2(-15, -40)
	hero.add_child(label)
	
	hero.position = Vector2(400, 300)
	show_msg("🦸 英雄登场！")
	
	_update_hero_button()

func _update_hero_button():
	if "hero_1" in skill_tree_unlocked:
		$UI/HeroButton.visible = true
		$UI/HeroButton.disabled = hero != null and is_instance_valid(hero)
		$UI/HeroButton.text = "🦸 英雄" if not hero else "🦸 英雄已部署"
	else:
		$UI/HeroButton.visible = false

func _apply_skill_effect(skill_key: String):
	match skill_key:
		"damage_1":
			for t in towers:
				if t: t.damage_mult *= 1.1
		"damage_2":
			for t in towers:
				if t: t.damage_mult *= 1.2
		"damage_3":
			for t in towers:
				if t: t.damage_mult *= 1.4
		"range_1":
			for t in towers:
				if t: t.range_mult *= 1.1
		"range_2":
			for t in towers:
				if t: t.range_mult *= 1.2
		"speed_1":
			for t in towers:
				if t: t.fire_rate_mult *= 1.1
		"speed_2":
			for t in towers:
				if t: t.fire_rate_mult *= 1.2
		"gold_1":
			save_data["gold_bonus"] = save_data.get("gold_bonus", 1.0) + 0.1
		"gold_2":
			save_data["gold_bonus"] = save_data.get("gold_bonus", 1.0) + 0.15
		"hero_1":
			_update_hero_button()
		"hero_2":
			hero_level_mult = 1.5

func _process_hero(delta: float):
	if hero and is_instance_valid(hero):
		hero_cooldown -= delta
		
		if hero_cooldown <= 0 and not enemies.is_empty():
			var nearest = null
			var nearest_dist = hero_range
			for e in enemies:
				if e and is_instance_valid(e):
					var dist = hero.global_position.distance_to(e.global_position)
					if dist < nearest_dist:
						nearest_dist = dist
						nearest = e
			
			if nearest:
				nearest.take_damage(hero_damage * hero_level_mult, "magic")
				hero_cooldown = 1.0
				var attack_rect = ColorRect.new()
				attack_rect.size = Vector2(10, 10)
				attack_rect.color = Color(1, 0.5, 0)
				attack_rect.global_position = hero.global_position
				add_child(attack_rect)
				var t = create_tween()
				t.tween_property(attack_rect, "global_position", nearest.global_position, 0.2)
				t.tween_callback(attack_rect.queue_free)

func _start_endless_wave():
	if game_over:
		return
	endless_wave += 1
	endless_in_progress = true
	show_msg("⚡ 无尽波次 %d 来袭！" % endless_wave)
	_update_ui()
	
	var enemy_count = 3 + endless_wave * 2
	var spawn_interval = max(0.3, 1.5 - endless_wave * 0.05)
	var enemy_types = ["normal", "fast", "armor", "magic_resist", "shadow", "healer", "elite"]
	
	# 无尽模式敌人越来越强
	for i in range(enemy_count):
		await get_tree().create_timer(spawn_interval).timeout
		if game_over:
			return
		var etype = enemy_types[randi() % enemy_types.size()]
		var edata = ENEMY_TYPES[etype]
		var scene = load("res://scenes/enemy.tscn")
		var e = scene.instantiate()
		e.enemy_type = etype
		e.max_health = edata.health * (1.0 + endless_wave * 0.15)
		e.health = e.max_health
		e.speed = edata.speed * (1.0 + endless_wave * 0.02)
		e.reward = edata.reward + endless_wave * 2
		e.armor = edata.armor
		e.magic_resist = edata.magic_resist
		e.enemy_name = edata.name
		e.enemy_icon = edata.icon
		e.path_index = 0
		e.path_progress = 0
		e.reached_end = false
		e.enemy_path = path_points.duplicate()
		e.add_to_group("enemies")
		add_child(e)
		enemies.append(e)

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
	e.enemy_path = path_points.duplicate()
	e.add_to_group("enemies")
	add_child(e)
	enemies.append(e)

func _on_show_levels():
	_show_panel("level")

func _on_select_level(n):
	_start_level(n)
	show_msg("第%d关：%s" % [n, LVL(n)["n"]])

func _on_show_shop():
	_show_panel("shop")

func _update_level_buttons():
	# 显示每日挑战信息
	var challenge_text = "📅 今日挑战：第%d关 - %s" % [daily_challenge["level"], daily_challenge["special_rule"]]
	if save_data.get("daily_challenge_completed", false):
		challenge_text += " ✅已完成"
	$UI/LevelPanel/VBox/ChallengeLabel.text = challenge_text
	
	for i in range(1, 6):
		var btn = $UI.get_node_or_null("LevelPanel/VBox/Grid/Level%d" % i)
		if btn:
			btn.disabled = false
			# 显示星级
			var key = "level_%d" % i
			var stars = save_data["star_ratings"].get(key, 0)
			var star_str = "⭐" if stars > 0 else ""
			btn.text = "第%d关\n%s" % [i, star_str]
			
			if i in level_progress:
				btn.modulate = Color(0.3, 0.8, 0.3)
			elif i <= level_progress[-1] + 1:
				btn.modulate = Color(1, 1, 1)
			else:
				btn.modulate = Color(0.4, 0.4, 0.4)
				btn.disabled = true

func _update_shop():
	$UI/ShopPanel/VBox/GoldLabel.text = "💰 %d" % gold
	_update_shop_button($UI/ShopPanel/VBox/HealButton, SHOP_ITEMS["heal"])
	_update_shop_button($UI/ShopPanel/VBox/ShieldButton, SHOP_ITEMS["shield"])
	_update_shop_button($UI/ShopPanel/VBox/SpeedButton, SHOP_ITEMS["speed_up"])
	_update_shop_button($UI/ShopPanel/VBox/DamageButton, SHOP_ITEMS["damage_up"])

func _update_shop_button(btn: Button, item: Dictionary):
	btn.text = "%s\n%d金币\n%s" % [item.name, item.cost, item.desc]
	btn.disabled = gold < item.cost

func _on_shop_heal():
	if gold >= SHOP_ITEMS["heal"]["cost"] and lives < 100:
		gold -= SHOP_ITEMS["heal"]["cost"]
		lives = min(100, lives + 20)
		show_msg("生命+20！")
		_update_ui()
	_update_shop()

func _on_shop_shield():
	if gold >= SHOP_ITEMS["shield"]["cost"]:
		gold -= SHOP_ITEMS["shield"]["cost"]
		lives += 50
		show_msg("护盾+50！")
		_update_ui()
	_update_shop()

func _on_shop_speed():
	if gold >= SHOP_ITEMS["speed_up"]["cost"]:
		gold -= SHOP_ITEMS["speed_up"]["cost"]
		for t in towers:
			if t: t.fire_rate_mult *= 1.3
		show_msg("攻速+30%%！")
		_update_ui()
	_update_shop()

func _on_shop_damage():
	if gold >= SHOP_ITEMS["damage_up"]["cost"]:
		gold -= SHOP_ITEMS["damage_up"]["cost"]
		for t in towers:
			if t: t.damage_mult *= 1.3
		show_msg("伤害+30%%！")
		_update_ui()
	_update_shop()

func _on_close_shop():
	_show_panel("")

func _on_close_skill_tree():
	_show_panel("")

func _on_unlock_skill(skill_key: String):
	var skill = SKILL_TREE.get(skill_key)
	if not skill:
		return
	if skill_key in skill_tree_unlocked:
		show_msg("已解锁！")
		return
	if gold < skill.cost:
		show_msg("金币不足！")
		return
	
	gold -= skill.cost
	skill_tree_unlocked.append(skill_key)
	show_msg("🌳 解锁：%s" % skill["name"])
	_save_game()
	_update_skill_tree_panel()
	_update_ui()
	
	# 应用技能效果
	_apply_skill_effect(skill_key)

func _on_toggle_pause():
	if showing_level_select or showing_shop:
		return
	if game_over:
		return
	game_paused = !game_paused
	if game_paused:
		_show_panel("pause")
	else:
		_hide_all_panels()
		_update_ui()

func _on_restart():
	_start_level(selected_level)
	show_msg("重新开始！")

func _input(event: InputEvent):
	if event is InputEventScreenTouch and event.pressed:
		var pos = event.position
		_handle_tap(pos)

func _handle_tap(pos: Vector2):
	if showing_level_select or showing_shop or game_over:
		return
	if game_paused and not $UI/PausePanel.get_global_rect().has_point(pos):
		return
	
	if pos.y > 620:
		return
	if pos.x < 150 and pos.y > 350:
		return
	
	if selected_obstacle != "":
		_attempt_place_obstacle(pos)
	elif selected_tower_type != "":
		_attempt_place(pos)
	else:
		_attempt_upgrade(pos)

func _attempt_place(pos: Vector2) -> bool:
	var td = TOWER_TYPES.get(selected_tower_type)
	if not td or gold < td.cost:
		show_msg("金币不足！")
		return false
	if not _valid_pos(pos):
		show_msg("位置无效！")
		return false
	for t in towers:
		if t and is_instance_valid(t) and t.global_position.distance_to(pos) < 50:
			show_msg("太近了！")
			return false
	gold -= td.cost
	var tower = _create_tower(selected_tower_type, pos)
	towers.append(tower)
	_update_ui()
	_check_achievement("all_towers")
	return true

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

func _attempt_place_obstacle(pos: Vector2) -> bool:
	var obs_data = OBSTACLE_TYPES.get(selected_obstacle)
	if not obs_data or gold < obs_data.cost:
		show_msg("金币不足！")
		return false
	if not _valid_pos(pos):
		show_msg("位置无效！")
		return false
	for o in obstacles:
		if o and is_instance_valid(o) and o.global_position.distance_to(pos) < 40:
			show_msg("太近了！")
			return false
	gold -= obs_data.cost
	var obs = _create_obstacle(selected_obstacle, pos)
	obstacles.append(obs)
	selected_obstacle = ""
	_update_obstacle_buttons()
	_update_ui()
	return true

func _create_obstacle(type: String, pos: Vector2) -> Node2D:
	var obs = Node2D.new()
	obs.global_position = pos
	obs.set("obstacle_type", type)
	obs.set("obstacle_data", OBSTACLE_TYPES[type])
	add_child(obs)
	
	# 创建视觉
	var rect = ColorRect.new()
	rect.size = Vector2(30, 30)
	var colors = {
		"rock": Color(0.5, 0.5, 0.5),
		"spike": Color(0.7, 0.3, 0.3),
		"wall": Color(0.6, 0.4, 0.2)
	}
	rect.color = colors.get(type, Color(0.5, 0.5, 0.5))
	obs.add_child(rect)
	
	# 障碍物效果
	if type == "spike":
		obs.set("damage_timer", 1.0)
		obs.set("damage_cooldown", 1.0)
	
	return obs

func _process_obstacles(delta: float):
	for i in range(obstacles.size()):
		var o = obstacles[i]
		if not is_instance_valid(o):
			continue
		var type = o.get("obstacle_type") if o.has("obstacle_type") else "rock"
		var pos = o.global_position
		
		if type == "spike":
			if not obstacle_damage_timers.has(i):
				obstacle_damage_timers[i] = 1.0
			obstacle_damage_timers[i] -= delta
			if obstacle_damage_timers[i] <= 0:
				for e in enemies:
					if e and is_instance_valid(e) and e.global_position.distance_to(pos) < 25:
						e.take_damage(5.0, "magic")
				obstacle_damage_timers[i] = 1.0
		
		if type == "rock":
			for e in enemies:
				if e and is_instance_valid(e) and e.global_position.distance_to(pos) < 25:
					e.apply_slow(0.5, 0.5)

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
	# 更新技能冷却
	for skill in skill_cooldowns:
		if skill_cooldowns[skill] > 0:
			skill_cooldowns[skill] -= _d
	_update_skill_buttons()
	
	if game_over or showing_level_select or showing_shop or game_paused:
		return
	
	_process_obstacles(_d)
	_process_hero(_d)
	
	kill_streak_timer -= _d
	if kill_streak_timer <= 0:
		kill_streak = 0
	
	var to_rm = []
	for e in enemies:
		if e and is_instance_valid(e):
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
	if endless_active:
		# 无尽模式
		gold += 20 + endless_wave * 5
		show_msg("无尽波次 %d 完成！+%d金币" % [endless_wave, 20 + endless_wave * 5])
		endless_in_progress = false
		_update_ui()
		return
	
	var ld = LVL(selected_level)
	if wave >= ld["w"]:
		gold += ld["r"]
		if selected_level < 5 and not (selected_level + 1 in level_progress):
			level_progress.append(selected_level + 1)
		
		# 星级评价
		var stars = _calculate_stars()
		var key = "level_%d" % selected_level
		var prev_stars = save_data["star_ratings"].get(key, 0)
		if stars > prev_stars:
			save_data["star_ratings"][key] = stars
			show_msg("⭐ 通关！%d星评价！新纪录！" % stars)
		else:
			show_msg("🎉 通关！%d星评价！" % stars)
		
		_save_game()
		_check_achievement("wave_5" if wave >= 5 else "wave_10")
		# 每日挑战完成检查
		if selected_level == daily_challenge["level"] and not save_data.get("daily_challenge_completed", false):
			_complete_daily_challenge()
		wave_in_progress = false
	else:
		wave_in_progress = false
		gold += 50
		show_msg("波次完成！+50金币")
	_update_ui()

func _calculate_stars() -> int:
	# 星级计算：基于剩余生命和金币
	var stars = 1
	if lives >= 10:
		stars = 2
	if lives >= 15 and gold >= 200:
		stars = 3
	return stars

func _trigger_game_over():
	game_over = true
	if endless_active and endless_wave > save_data.get("endless_best_wave", 0):
		save_data["endless_best_wave"] = endless_wave
		show_msg("💀 游戏结束！无尽模式到达第%d波！新纪录！" % endless_wave)
	else:
		show_msg("💀 游戏结束！")
	_save_game()
	$UI/PausePanel.visible = true

func _update_ui():
	$UI/TopBar/HBox/GoldLabel.text = "💰 %d" % gold
	$UI/TopBar/HBox/LivesLabel.text = "❤️ %d" % lives
	$UI/TopBar/HBox/WaveLabel.text = "🌊 %d/%d" % [wave, LVL(selected_level)["w"]]
	$UI/TopBar/HBox/LevelName.text = LVL(selected_level)["n"]
	$UI/ComboLabel.visible = kill_streak >= 3
	if kill_streak >= 3:
		$UI/ComboLabel.text = "🔥 %d连杀！+%d" % [kill_streak, kill_streak * 5]

func show_msg(msg: String):
	$UI/MessageLabel.text = msg
	$UI/MessageLabel.visible = true
	$UI/MessageLabel/Timer.start(3.0)

func show_screen_flash(color: Color = Color(1, 1, 1)):
	$UI/FlashLayer.color = Color(color.r, color.g, color.b, 0.3)
	$UI/FlashLayer/Timer.start(0.1)

func _on_flash_timer():
	$UI/FlashLayer.visible = false

func screen_shake(intensity: float = 5.0):
	var t = create_tween()
	var base_pos = Vector2(0, 0)
	for i in range(3):
		var offset = Vector2(randf_range(-intensity, intensity), randf_range(-intensity, intensity))
		t.tween_property($Camera, "offset", offset, 0.05)
		t.tween_property($Camera, "offset", Vector2.ZERO, 0.05)

func add_gold(amount: int):
	gold += amount
	_update_ui()
	_check_achievement("rich")

func add_kill():
	kill_streak += 1
	kill_streak_timer = 3.0
	combo_count += 1
	save_data["total_kills"] += 1
	
	if kill_streak >= 5:
		_check_achievement("combo_5")
		gold += kill_streak * 5
		show_msg("🔥 %d连杀！+%d金币" % [kill_streak, kill_streak * 5])
	
	if combo_count >= 10:
		_check_achievement("kill_10")
	if combo_count >= 100:
		_check_achievement("kill_100")
	
	_update_ui()

func _check_achievement(key: String):
	if key in save_data["achievements"]:
		return
	save_data["achievements"].append(key)
	var ach = ACHIEVEMENTS[key]
	gold += ach["reward"]
	show_msg("🏆 成就解锁：%s！+%d金币" % [ach["name"], ach["reward"]])
	_update_ui()
	_save_game()

# 特殊技能
func _on_skill_lightning():
	if skill_cooldowns["lightning"] > 0:
		show_msg("⚡技能冷却中...")
		return
	skill_cooldowns["lightning"] = PLAYER_SKILLS["lightning"]["cooldown"]
	# 对所有敌人造成伤害
	var damage = 50.0
	for e in enemies:
		if e and is_instance_valid(e):
			e.take_damage(damage, "lightning")
	show_msg("⚡雷电打击！-%d伤害" % int(damage))
	_update_skill_buttons()

func _on_skill_freeze():
	if skill_cooldowns["freeze"] > 0:
		show_msg("❄️技能冷却中...")
		return
	skill_cooldowns["freeze"] = PLAYER_SKILLS["freeze"]["cooldown"]
	# 冻结所有敌人3秒
	for e in enemies:
		if e and is_instance_valid(e):
			e.apply_slow(0.99, 3.0)
	show_msg("❄️冰冻全场！敌人冻结3秒")
	_update_skill_buttons()

func _on_skill_heal():
	if skill_cooldowns["heal"] > 0:
		show_msg("💚技能冷却中...")
		return
	skill_cooldowns["heal"] = PLAYER_SKILLS["heal"]["cooldown"]
	lives = min(100, lives + 30)
	show_msg("💚治疗！生命+30")
	_update_ui()
	_update_skill_buttons()

func _on_obstacle_rock():
	selected_obstacle = "rock" if selected_obstacle != "rock" else ""
	_update_obstacle_buttons()

func _on_obstacle_spike():
	selected_obstacle = "spike" if selected_obstacle != "spike" else ""
	_update_obstacle_buttons()

func _on_obstacle_wall():
	selected_obstacle = "wall" if selected_obstacle != "wall" else ""
	_update_obstacle_buttons()

func _update_obstacle_buttons():
	var obs_types = ["rock", "spike", "wall"]
	var btns = {
		"rock": $UI/ObstacleRock, 
		"spike": $UI/ObstacleSpike, 
		"wall": $UI/ObstacleWall
	}
	var colors = {
		"rock": Color(0.5, 0.5, 0.5),
		"spike": Color(0.7, 0.3, 0.3),
		"wall": Color(0.6, 0.4, 0.2)
	}
	for t in obs_types:
		if selected_obstacle == t:
			btns[t].modulate = colors[t]
		else:
			btns[t].modulate = Color(1, 1, 1)

func _update_skill_buttons():
	var lightning_cd = skill_cooldowns["lightning"]
	var freeze_cd = skill_cooldowns["freeze"]
	var heal_cd = skill_cooldowns["heal"]
	
	$UI/SkillLightning.text = "⚡%s\n%.0f秒" % [PLAYER_SKILLS["lightning"]["name"], max(0, lightning_cd)]
	$UI/SkillFreeze.text = "❄️%s\n%.0f秒" % [PLAYER_SKILLS["freeze"]["name"], max(0, freeze_cd)]
	$UI/SkillHeal.text = "💚%s\n%.0f秒" % [PLAYER_SKILLS["heal"]["name"], max(0, heal_cd)]
	
	$UI/SkillLightning.disabled = lightning_cd > 0
	$UI/SkillFreeze.disabled = freeze_cd > 0
	$UI/SkillHeal.disabled = heal_cd > 0
	
	# 冷却时变灰
	var lightning_modulate = Color(0.5, 0.5, 0.5) if lightning_cd > 0 else Color(1, 1, 0.3)
	var freeze_modulate = Color(0.5, 0.5, 0.5) if freeze_cd > 0 else Color(0.4, 0.8, 1)
	var heal_modulate = Color(0.5, 0.5, 0.5) if heal_cd > 0 else Color(0.2, 0.9, 0.4)
	$UI/SkillLightning.modulate = lightning_modulate
	$UI/SkillFreeze.modulate = freeze_modulate
	$UI/SkillHeal.modulate = heal_modulate
