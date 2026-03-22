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

# Save data
var save_data: Dictionary = {
	"high_scores": {},
	"achievements": [],
	"total_gold": 0,
	"total_kills": 0,
	"daily_challenge": null
}

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
	$UI/LevelButton.pressed.connect(_on_show_levels.bind())
	$UI/ShopButton.pressed.connect(_on_show_shop.bind())
	$UI/PauseButton.pressed.connect(_on_toggle_pause.bind())
	$UI/SkillLightning.pressed.connect(_on_skill_lightning.bind())
	$UI/SkillFreeze.pressed.connect(_on_skill_freeze.bind())
	$UI/SkillHeal.pressed.connect(_on_skill_heal.bind())
	
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

func _load_save():
	var f = FileAccess.open("user://save.dat", FileAccess.READ)
	if f:
		var data = JSON.parse_string(f.get_as_text())
		if data:
			save_data = data
		f.close()

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
	
	if selected_tower_type != "":
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
	
	kill_streak_timer -= _d
	if kill_streak_timer <= 0:
		kill_streak = 0
	
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
		_save_game()
		_check_achievement("wave_5" if wave >= 5 else "wave_10")
		show_msg("🎉 通关！+%d金币" % ld["r"])
		wave_in_progress = false
	else:
		wave_in_progress = false
		gold += 50
		show_msg("波次完成！+50金币")
	_update_ui()

func _trigger_game_over():
	game_over = true
	_save_game()
	show_msg("游戏结束！")
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
