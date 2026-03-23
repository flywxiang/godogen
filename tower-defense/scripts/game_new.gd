extends Node2D

var current_map: Node2D = null
var particles_effects: Array = []
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
	"arrow": {"cost": 50, "damage": 10, "range": 150, "fire_rate": 1.2, "color": Color(0.3, 0.7, 0.3), "icon": "🏹"},
	"cannon": {"cost": 100, "damage": 30, "range": 120, "fire_rate": 0.5, "color": Color(0.9, 0.5, 0.2), "icon": "💣"},
	"magic": {"cost": 80, "damage": 15, "range": 180, "fire_rate": 0.8, "color": Color(0.5, 0.3, 0.9), "icon": "✨"}
}

const ENEMY_TYPES = {
	"normal": {"health": 100, "speed": 100, "reward": 10, "icon": "👹", "color": Color(0.9, 0.3, 0.3)},
	"fast": {"health": 60, "speed": 160, "reward": 15, "icon": "⚡", "color": Color(1, 0.8, 0.2)},
	"armor": {"health": 200, "speed": 60, "reward": 25, "icon": "🛡️", "color": Color(0.5, 0.5, 0.6)},
	"magic_resist": {"health": 120, "speed": 90, "reward": 20, "icon": "🔮", "color": Color(0.4, 0.2, 0.6)}
}

func _ready():
	randomize()
	_setup_buttons()
	_load_map()
	
	# 添加音乐管理器
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

func _load_map():
	var map_path = Global.selected_map
	if map_path.is_empty():
		map_path = "res://scenes/maps/map_1.tscn"
	
	var map_scene = load(map_path)
	if map_scene:
		current_map = map_scene.instantiate()
		$MapContainer.add_child(current_map)
		
		if current_map.has("map_name"):
			$UI/TopBar/HBox/LevelName.text = current_map.map_name
	else:
		print("Failed to load map: ", map_path)
	
	_update_ui()

func _process(_delta: float):
	if game_over or wave_in_progress:
		return
	
	for e in enemies:
		if is_instance_valid(e):
			e.move_along_path(current_map.get_path_points() if current_map else [])
	
	# 更新特效
	_update_particles(_delta)

func _update_particles(delta: float):
	var to_remove = []
	for p in particles_effects:
		if is_instance_valid(p):
			var lifetime = p.get("lifetime", 1.0)
			lifetime -= delta
			p.set("lifetime", lifetime)
			if lifetime <= 0:
				to_remove.append(p)
				p.queue_free()
		else:
			to_remove.append(p)
	for p in to_remove:
		particles_effects.erase(p)

func _create_hit_effect(pos: Vector2, color: Color):
	# 打击特效 - 扩散圆圈
	for i in range(8):
		var particle = Node2D.new()
		particle.position = pos
		particle.set("lifetime", 0.3)
		particle.set("dir", Vector2(cos(i * PI / 4), sin(i * PI / 4)))
		particle.set("color", color)
		add_child(particle)
		particles_effects.append(particle)
		
		var circle = ColorRect.new()
		circle.size = Vector2(8, 8)
		circle.color = color
		particle.add_child(circle)

func _create_death_effect(pos: Vector2, color: Color):
	# 死亡特效 - 大爆炸
	for i in range(12):
		var particle = Node2D.new()
		particle.position = pos
		particle.set("lifetime", 0.5)
		particle.set("dir", Vector2(cos(i * PI / 6), sin(i * PI / 6)))
		particle.set("color", color)
		particle.set("speed", 150.0)
		add_child(particle)
		particles_effects.append(particle)
		
		var circle = ColorRect.new()
		circle.size = Vector2(12, 12)
		circle.color = color
		particle.add_child(circle)

func _create_coin_effect(pos: Vector2):
	# 金币特效 - 向上飘的金币图标
	var coin = Label.new()
	coin.text = "💰"
	coin.position = pos + Vector2(-10, -20)
	coin.set("lifetime", 1.0)
	coin.set("velocity", Vector2(0, -50))
	add_child(coin)
	particles_effects.append(coin)

func _input(event: InputEvent):
	if event is InputEventMouseButton and event.pressed:
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
	var colors = {"arrow": Color(0.3, 0.7, 0.3), "cannon": Color(0.9, 0.5, 0.2), "magic": Color(0.5, 0.3, 0.9)}
	var btns = {"arrow": $UI/TowerPanelBG/TowerPanel/TowerArrow, "cannon": $UI/TowerPanelBG/TowerPanel/TowerCannon, "magic": $UI/TowerPanelBG/TowerPanel/TowerMagic}
	for t in ["arrow", "cannon", "magic"]:
		btns[t].modulate = colors[t] if selected_tower_type == t else Color(1, 1, 1)

func _place_tower(pos: Vector2):
	var td = TOWER_TYPES.get(selected_tower_type)
	if not td or gold < td.cost:
		show_msg("金币不足！")
		return
	
	gold -= td.cost
	
	# 创建塔容器
	var tower = Node2D.new()
	tower.position = pos
	
	# 塔底座
	var base = ColorRect.new()
	base.size = Vector2(50, 50)
	base.color = Color(0.3, 0.3, 0.35)
	tower.add_child(base)
	
	# 塔图标（用Label模拟emoji）
	var icon = Label.new()
	icon.text = td.icon
	icon.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	icon.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	icon.size = Vector2(50, 50)
	icon.position = Vector2(0, -5)
	icon.add_theme_font_size_override("font_size", 36)
	tower.add_child(icon)
	
	tower.set("tower_type", selected_tower_type)
	tower.set("damage", td.damage)
	tower.set("range", td.range)
	tower.set("fire_rate", td.fire_rate)
	tower.set("fire_cooldown", 0.0)
	tower.set("tower_icon", td.icon)
	
	add_child(tower)
	towers.append(tower)
	_update_ui()
	show_msg("🏹 塔已放置！")
	
	# 播放放置音效
	var music = get("music_manager")
	if music: music.play_shoot()

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
	
	# 敌人底座
	var base = ColorRect.new()
	base.size = Vector2(35, 35)
	base.color = edata.color
	enemy.add_child(base)
	
	# 敌人图标
	var icon = Label.new()
	icon.text = edata.icon
	icon.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	icon.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	icon.size = Vector2(35, 35)
	icon.position = Vector2(0, -3)
	icon.add_theme_font_size_override("font_size", 28)
	enemy.add_child(icon)
	
	# 生命条背景
	var hp_bg = ColorRect.new()
	hp_bg.size = Vector2(35, 5)
	hp_bg.position = Vector2(-17, -25)
	hp_bg.color = Color(0.2, 0.2, 0.2)
	enemy.add_child(hp_bg)
	
	# 生命条
	var hp_bar = ColorRect.new()
	hp_bar.size = Vector2(35, 5)
	hp_bar.position = Vector2(-17, -25)
	hp_bar.color = Color(0.2, 0.9, 0.2)
	hp_bar.set("hp_bar", true)
	enemy.add_child(hp_bar)
	
	enemy.set("enemy_type", type)
	enemy.set("max_health", edata.health)
	enemy.set("health", edata.health)
	enemy.set("speed", edata.speed)
	enemy.set("reward", edata.reward)
	enemy.set("enemy_icon", edata.icon)
	enemy.set("path_index", 0)
	enemy.set("path_progress", 0.0)
	enemy.set("reached_end", false)
	
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
	
	# 更新生命条
	for child in get_children():
		if child.has("hp_bar") and child.hp_bar:
			var hp = self.get("health")
			var max_hp = self.get("max_health")
			child.size.x = 35 * (hp / max_hp) if max_hp > 0 else 0

# 特效动画更新
func _process_effects(delta: float):
	for p in particles_effects:
		if is_instance_valid(p) and p.has("dir"):
			var dir = p.get("dir", Vector2.ZERO)
			var speed = p.get("speed", 100.0)
			p.position += dir * speed * delta
			var lifetime = p.get("lifetime", 1.0)
			p.modulate.a = lifetime
		elif is_instance_valid(p) and p.has("velocity"):
			var vel = p.get("velocity", Vector2.ZERO)
			p.position += vel * delta
			var lifetime = p.get("lifetime", 1.0)
			p.modulate.a = lifetime
			var hp = self.get("health")
			var max_hp = self.get("max_health")
			child.size.x = 35 * (hp / max_hp) if max_hp > 0 else 0

func _on_back():
	get_tree().change_scene_to_file("res://scenes/ui/level_select.tscn")

func _on_pause():
	get_tree().paused = !get_tree().paused
	show_msg("⏸️ 暂停" if get_tree().paused else "▶ 继续")

func _on_shop():
	show_msg("🏪 商店功能开发中...")

func _on_toggle_music():
	var music = get("music_manager")
	if music:
		var enabled = music.toggle_sfx()
		show_msg("🔊 音效已开启" if enabled else "🔇 音效已关闭")

func _update_ui():
	$UI/TopBar/HBox/GoldLabel.text = "💰 %d" % gold
	$UI/TopBar/HBox/LivesLabel.text = "❤️ %d" % lives
	$UI/TopBar/HBox/WaveLabel.text = "🌊 %d/%d" % [wave, max_waves]

func show_msg(msg: String):
	$UI/MessageLabel.text = msg
	$UI/MessageLabel.visible = true
