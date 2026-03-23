extends Node2D

var current_map: Node2D = null
var enemies: Array = []
var towers: Array = []
var projectiles: Array = []
var gold: int = 200
var lives: int = 20
var wave: int = 0
var max_waves: int = 10
var wave_in_progress: bool = false
var game_over: bool = false
var selected_tower_type: String = ""

# 技能系统
var skill_cooldowns: Dictionary = {
	"lightning": 0.0,
	"freeze": 0.0,
	"heal": 0.0
}
var skill_bonus_damage: float = 1.0
var skill_bonus_speed: float = 1.0

const TOWER_TYPES = {
	"arrow": {"cost": 50, "damage": 10, "range": 150, "fire_rate": 1.2, "color": Color(0.3, 0.7, 0.3)},
	"cannon": {"cost": 100, "damage": 30, "range": 120, "fire_rate": 0.5, "color": Color(0.9, 0.5, 0.2)},
	"magic": {"cost": 80, "damage": 15, "range": 180, "fire_rate": 0.8, "color": Color(0.5, 0.3, 0.9)}
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
	
	var music = Node.new()
	music.set_script(load("res://scripts/music_manager.gd"))
	add_child(music)
	set("music_manager", music)

func _setup_buttons():
	$UI/TowerPanelBG/TowerPanel/TowerArrow.pressed.connect(_on_select_arrow)
	$UI/TowerPanelBG/TowerPanel/TowerCannon.pressed.connect(_on_select_cannon)
	$UI/TowerPanelBG/TowerPanel/TowerMagic.pressed.connect(_on_select_magic)
	$UI/StartWaveButton.pressed.connect(_on_start_wave)
	$UI/ButtonPanel/BackButton.pressed.connect(_on_back)
	$UI/ButtonPanel/PauseButton.pressed.connect(_on_pause)
	$UI/ButtonPanel/ShopButton.pressed.connect(_on_shop)
	$UI/ButtonPanel/MusicButton.pressed.connect(_on_toggle_music)
	$UI/SkillPanel/SkillLightning.pressed.connect(_on_skill_lightning)
	$UI/SkillPanel/SkillFreeze.pressed.connect(_on_skill_freeze)
	$UI/SkillPanel/SkillHeal.pressed.connect(_on_skill_heal)

func _load_map():
	var map_path = Global.selected_map
	if map_path.is_empty():
		map_path = "res://scenes/maps/map_1.tscn"
	
	var map_scene = load(map_path)
	if map_scene:
		current_map = map_scene.instantiate()
		$MapContainer.add_child(current_map)
		
		# 尝试获取关卡名称
		if current_map:
			var level_name = current_map.get("map_name")
			if level_name:
				$UI/TopBarBG/TopBar/LevelName.text = str(level_name)
	else:
		print("Failed to load map: ", map_path)
	
	_update_ui()

func _process(delta: float):
	# 更新技能冷却
	for skill in skill_cooldowns:
		skill_cooldowns[skill] = max(0, skill_cooldowns[skill] - delta)
	_update_skill_ui()
	
	if game_over:
		return
	
	# 塔攻击
	for tower in towers:
		if is_instance_valid(tower):
			_tower_attack(tower, delta)
	
	# 更新子弹
	var to_remove_proj = []
	for proj in projectiles:
		if is_instance_valid(proj):
			proj.position += proj.get("velocity") * delta
			var lifetime = proj.get("lifetime", 1.0) - delta
			proj.set("lifetime", lifetime)
			
			# 检测命中
			for enemy in enemies:
				if is_instance_valid(enemy):
					if proj.position.distance_to(enemy.position) < 20:
						# 命中敌人
						var damage = proj.get("damage", 10)
						enemy.take_damage(damage)
						_create_hit_effect(proj.position)
						to_remove_proj.append(proj)
						break
			
			if lifetime <= 0:
				to_remove_proj.append(proj)
		else:
			to_remove_proj.append(proj)
	
	for p in to_remove_proj:
		projectiles.erase(p)
		if is_instance_valid(p):
			p.queue_free()
	
	# 更新敌人
	var to_remove_enemy = []
	for enemy in enemies:
		if is_instance_valid(enemy):
			enemy.move_along_path(current_map.get_path_points() if current_map else [])
			
			if enemy.is_dead:
				to_remove_enemy.append(enemy)
		else:
			to_remove_enemy.append(enemy)
	
	for e in to_remove_enemy:
		enemies.erase(e)
		if is_instance_valid(e):
			e.queue_free()
	
	# 波次完成检测
	if wave_in_progress and enemies.is_empty():
		wave_in_progress = false
		gold += 50
		show_msg("波次完成！+50金币")
		_update_ui()
		if wave >= max_waves:
			_trigger_victory()

func _tower_attack(tower, delta):
	var cooldown = tower.get("fire_cooldown", 0.0) - delta
	tower.set("fire_cooldown", cooldown)
	
	if cooldown > 0:
		return
	
	# 找最近的敌人
	var range = tower.get("range", 150)
	var damage = tower.get("damage", 10)
	var tower_type = tower.get("tower_type", "arrow")
	
	var nearest = null
	var nearest_dist = range
	
	for enemy in enemies:
		if is_instance_valid(enemy) and not enemy.is_dead:
			var dist = tower.position.distance_to(enemy.position)
			if dist < nearest_dist:
				nearest_dist = dist
				nearest = enemy
	
	if nearest:
		_fire_projectile(tower.position, nearest, damage, tower_type)
		tower.set("fire_cooldown", 1.0 / tower.get("fire_rate", 1.0))

func _fire_projectile(from: Vector2, target, damage: float, tower_type: String):
	var proj = Node2D.new()
	proj.position = from
	proj.set("damage", damage)
	proj.set("lifetime", 2.0)
	
	var direction = (target.position - from).normalized()
	var speed = 400 if tower_type == "arrow" else 250
	proj.set("velocity", direction * speed)
	
	# 子弹外观
	var bullet = ColorRect.new()
	var color = Color(1, 1, 0.2)
	if tower_type == "cannon":
		bullet.size = Vector2(12, 12)
		bullet.color = Color(0.8, 0.4, 0.1)
	elif tower_type == "magic":
		bullet.size = Vector2(10, 10)
		bullet.color = Color(0.5, 0.3, 0.9)
	else:
		bullet.size = Vector2(8, 4)
		bullet.color = color
	
	proj.add_child(bullet)
	add_child(proj)
	projectiles.append(proj)

func _create_hit_effect(pos: Vector2):
	# 命中特效
	for i in range(6):
		var particle = Node2D.new()
		particle.position = pos
		var p = ColorRect.new()
		p.size = Vector2(6, 6)
		p.color = Color(1, 0.8, 0.2)
		particle.add_child(p)
		particle.set("lifetime", 0.3)
		particle.set("velocity", Vector2(randf() * 200 - 100, randf() * 200 - 100))
		add_child(particle)
		await get_tree().create_timer(0.01).timeout
		particle.queue_free()

func _spawn_enemy(type: String):
	var edata = ENEMY_TYPES.get(type, ENEMY_TYPES["normal"])
	var enemy = PixelMonster.create_monster(type)
	
	# 生命条
	var hp_bg = ColorRect.new()
	hp_bg.size = Vector2(40, 6)
	hp_bg.position = Vector2(-20, -38)
	hp_bg.color = Color(0.15, 0.15, 0.15)
	enemy.add_child(hp_bg)
	
	var hp_bar = ColorRect.new()
	hp_bar.size = Vector2(40, 6)
	hp_bar.position = Vector2(-20, -38)
	hp_bar.color = Color(0.2, 0.9, 0.2)
	hp_bar.set("hp_bar", true)
	enemy.add_child(hp_bar)
	
	enemy.set("enemy_type", type)
	enemy.set("max_health", edata.health)
	enemy.set("health", edata.health)
	enemy.set("speed", edata.speed)
	enemy.set("reward", edata.reward)
	enemy.set("path_index", 0)
	enemy.set("path_progress", 0.0)
	enemy.set("reached_end", false)
	enemy.set("is_dead", false)
	enemy.set("walk_timer", 0.0)
	enemy.set("walk_offset", 0.0)
	
	# 装甲和魔抗
	var armor = 0.0
	var magic_resist = 0.0
	if type == "armor":
		armor = 0.5
	elif type == "magic_resist":
		magic_resist = 0.5
	enemy.set("armor", armor)
	enemy.set("magic_resist", magic_resist)
	
	add_child(enemy)
	enemies.append(enemy)

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
	var colors = {"arrow": Color(0.3, 0.7, 0.3), "cannon": Color(0.9, 0.5, 0.2), "magic": Color(0.5, 0.3, 0.9)}
	var btns = {
		"arrow": $UI/TowerPanelBG/TowerPanel/TowerArrow, 
		"cannon": $UI/TowerPanelBG/TowerPanel/TowerCannon, 
		"magic": $UI/TowerPanelBG/TowerPanel/TowerMagic
	}
	for t in ["arrow", "cannon", "magic"]:
		btns[t].modulate = colors[t] if selected_tower_type == t else Color(1, 1, 1)

func _place_tower(pos: Vector2):
	var td = TOWER_TYPES.get(selected_tower_type)
	if not td or gold < td.cost:
		show_msg("金币不足！")
		return
	
	gold -= td.cost
	
	var tower = _create_pixel_tower(selected_tower_type, pos)
	tower.set("tower_type", selected_tower_type)
	tower.set("damage", td.damage)
	tower.set("range", td.range)
	tower.set("fire_rate", td.fire_rate)
	tower.set("fire_cooldown", 0.0)
	
	add_child(tower)
	towers.append(tower)
	_update_ui()
	show_msg("塔已放置！")

func _create_pixel_tower(type: String, pos: Vector2) -> Node2D:
	var td = TOWER_TYPES.get(type)
	var tower = Node2D.new()
	tower.position = pos
	
	var base = ColorRect.new()
	base.size = Vector2(45, 45)
	base.color = Color(0.25, 0.25, 0.3)
	tower.add_child(base)
	
	match type:
		"arrow":
			var body = ColorRect.new()
			body.size = Vector2(12, 30)
			body.position = Vector2(-6, -25)
			body.color = td.color
			tower.add_child(body)
			
			var tip = Polygon2D.new()
			tip.polygon = PackedVector2Array([Vector2(0, -35), Vector2(-8, -25), Vector2(8, -25)])
			tip.color = td.color.darkened(0.2)
			tower.add_child(tip)
			
		"cannon":
			var body = ColorRect.new()
			body.size = Vector2(28, 22)
			body.position = Vector2(-14, -22)
			body.color = td.color
			tower.add_child(body)
			
			var barrel = ColorRect.new()
			barrel.size = Vector2(10, 18)
			barrel.position = Vector2(-5, -40)
			barrel.color = td.color.darkened(0.3)
			tower.add_child(barrel)
			
		"magic":
			var body = ColorRect.new()
			body.size = Vector2(24, 24)
			body.position = Vector2(-12, -18)
			body.color = td.color
			tower.add_child(body)
			
			var crystal = Polygon2D.new()
			crystal.polygon = PackedVector2Array([Vector2(0, -38), Vector2(-10, -18), Vector2(10, -18)])
			crystal.color = td.color.lightened(0.3)
			tower.add_child(crystal)
	
	return tower

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

func _input(event: InputEvent):
	if event is InputEventScreenTouch and event.pressed:
		var pos = event.position
		if selected_tower_type != "" and pos.y < 600 and pos.y > 80:
			_place_tower(pos)

func _on_back():
	get_tree().change_scene_to_file("res://scenes/ui/level_select.tscn")

func _on_pause():
	get_tree().paused = !get_tree().paused
	show_msg("暂停" if get_tree().paused else "继续")

func _on_shop():
	var shop = load("res://scenes/ui/shop_panel.tscn").instantiate()
	shop.item_purchased.connect(_on_shop_item)
	add_child(shop)
	shop.show_shop(gold)

func _on_shop_item(item_type: String):
	match item_type:
		"heal":
			if gold >= 50 and lives < 100:
				gold -= 50
				lives = min(100, lives + 30)
				show_msg("❤️ 生命+30")
		"shield":
			if gold >= 100:
				gold -= 100
				lives += 50
				show_msg("🛡️ 生命+50")
		"speed":
			if gold >= 80:
				gold -= 80
				skill_bonus_speed *= 1.2
				show_msg("⚡ 攻速+20%")
		"damage":
			if gold >= 120:
				gold -= 120
				skill_bonus_damage *= 1.2
				show_msg("⚔️ 伤害+20%")
	_update_ui()

# 技能系统
func _on_skill_lightning():
	if skill_cooldowns["lightning"] > 0:
		show_msg("技能冷却中...")
		return
	skill_cooldowns["lightning"] = 15.0
	# 对所有敌人造成伤害
	for enemy in enemies:
		if is_instance_valid(enemy):
			enemy.take_damage(50 * skill_bonus_damage)
	_create_skill_effect("lightning")
	show_msg("⚡ 雷电打击！")

func _on_skill_freeze():
	if skill_cooldowns["freeze"] > 0:
		show_msg("技能冷却中...")
		return
	skill_cooldowns["freeze"] = 20.0
	for enemy in enemies:
		if is_instance_valid(enemy):
			enemy.apply_slow(0.9, 3.0)
	_create_skill_effect("freeze")
	show_msg("❄️ 冰冻！敌人减速3秒")

func _on_skill_heal():
	if skill_cooldowns["heal"] > 0:
		show_msg("技能冷却中...")
		return
	skill_cooldowns["heal"] = 30.0
	lives = min(100, lives + 30)
	_create_skill_effect("heal")
	show_msg("💚 治疗！生命+30")
	_update_ui()

func _update_skill_ui():
	$UI/SkillPanel/SkillLightning.text = "⚡%ds" % int(skill_cooldowns["lightning"])
	$UI/SkillPanel/SkillFreeze.text = "❄️%ds" % int(skill_cooldowns["freeze"])
	$UI/SkillPanel/SkillHeal.text = "💚%ds" % int(skill_cooldowns["heal"])
	
	$UI/SkillPanel/SkillLightning.disabled = skill_cooldowns["lightning"] > 0
	$UI/SkillPanel/SkillFreeze.disabled = skill_cooldowns["freeze"] > 0
	$UI/SkillPanel/SkillHeal.disabled = skill_cooldowns["heal"] > 0

func _create_skill_effect(type: String):
	# 技能特效
	var effect = Node2D.new()
	effect.position = Vector2(640, 360)
	add_child(effect)
	
	if type == "lightning":
		for i in range(5):
			var line = ColorRect.new()
			line.size = Vector2(1280, 4)
			line.color = Color(1, 1, 0.2, 0.8)
			line.position = Vector2(-640, randf() * 720 - 360)
			effect.add_child(line)
	elif type == "freeze":
		var circle = ColorRect.new()
		circle.size = Vector2(720, 720)
		circle.color = Color(0.5, 0.8, 1, 0.3)
		circle.position = Vector2(-360, -360)
		effect.add_child(circle)
	elif type == "heal":
		var heal = ColorRect.new()
		heal.size = Vector2(720, 720)
		heal.color = Color(0.2, 1, 0.3, 0.3)
		heal.position = Vector2(-360, -360)
		effect.add_child(heal)
	
	await get_tree().create_timer(0.5).timeout
	effect.queue_free()

func _on_toggle_music():
	var music = get("music_manager")
	if music:
		var enabled = music.toggle_sfx()
		show_msg("音效已开启" if enabled else "音效已关闭")

func _trigger_victory():
	game_over = true
	show_msg("🎉 通关胜利！")
	_update_ui()

func _update_ui():
	$UI/TopBarBG/TopBar/GoldLabel.text = "💰 %d" % gold
	$UI/TopBarBG/TopBar/LivesLabel.text = "❤️ %d" % lives
	$UI/TopBarBG/TopBar/WaveLabel.text = "🌊 %d/%d" % [wave, max_waves]

func show_msg(msg: String):
	$UI/MessageLabel.text = msg
	$UI/MessageLabel.visible = true
