extends Node2D

# 像素风格怪物工厂类
class_name PixelMonster

# 怪物类型配置
static func get_monster_config(monster_type: String) -> Dictionary:
	var configs = {
		"normal": {
			"color": Color(0.85, 0.25, 0.25),  # 红色
			"size": 1.0,
			"shape": "blob",  # 圆胖型
			"name": "史莱姆"
		},
		"fast": {
			"color": Color(1.0, 0.85, 0.2),  # 黄色
			"size": 0.8,
			"shape": "triangle",  # 三角形-快速
			"name": "幽灵"
		},
		"armor": {
			"color": Color(0.4, 0.5, 0.7),  # 蓝色
			"size": 1.3,
			"shape": "square",  # 方块-装甲
			"name": "石像鬼"
		},
		"magic_resist": {
			"color": Color(0.5, 0.3, 0.8),  # 紫色
			"size": 1.0,
			"shape": "diamond",  # 菱形-魔抗
			"name": "魔法师"
		}
	}
	return configs.get(monster_type, configs["normal"])

# 创建像素怪物节点
static func create_monster(monster_type: String) -> Node2D:
	var config = get_monster_config(monster_type)
	
	# 加载enemy脚本并创建节点
	var enemy_scene = load("res://scripts/enemy.gd")
	var monster = Node2D.new()
	monster.set_script(enemy_scene)
	
	monster.set("enemy_type", monster_type)
	monster.set("config", config)
	
	# 创建像素身体
	var body = _create_body(config)
	monster.add_child(body)
	
	# 创建眼睛
	var eyes = _create_eyes(config)
	monster.add_child(eyes)
	
	# 创建脚（行走动画用）
	var feet = _create_feet(config)
	monster.add_child(feet)
	
	return monster

static func _create_body(config: Dictionary) -> Node2D:
	var body = Node2D.new()
	var shape = config["shape"]
	var color = config["color"]
	var size = config["size"]
	
	match shape:
		"blob":
			# 圆胖型怪物 - 用多个圆组成
			var main = ColorRect.new()
			main.size = Vector2(24 * size, 20 * size)
			main.color = color
			body.add_child(main)
			
			var head = ColorRect.new()
			head.size = Vector2(18 * size, 16 * size)
			head.position = Vector2(3 * size, -12 * size)
			head.color = color.lightened(0.1)
			body.add_child(head)
			
		"triangle":
			# 三角形幽灵
			var tri = Polygon2D.new()
			tri.polygon = PackedVector2Array([
				Vector2(12 * size, -16 * size),
				Vector2(-12 * size, 12 * size),
				Vector2(12 * size, 12 * size)
			])
			tri.color = color
			body.add_child(tri)
			
		"square":
			# 方块装甲怪
			var main = ColorRect.new()
			main.size = Vector2(28 * size, 28 * size)
			main.color = color.darkened(0.2)
			body.add_child(main)
			
			var detail = ColorRect.new()
			detail.size = Vector2(20 * size, 20 * size)
			detail.position = Vector2(4 * size, 4 * size)
			detail.color = color
			body.add_child(detail)
			
		"diamond":
			# 菱形魔法怪
			var diamond = Polygon2D.new()
			diamond.polygon = PackedVector2Array([
				Vector2(0, -18 * size),
				Vector2(14 * size, 0),
				Vector2(0, 18 * size),
				Vector2(-14 * size, 0)
			])
			diamond.color = color
			body.add_child(diamond)
			
			# 魔法光环
			var glow = Polygon2D.new()
			glow.polygon = PackedVector2Array([
				Vector2(0, -22 * size),
				Vector2(18 * size, 0),
				Vector2(0, 22 * size),
				Vector2(-18 * size, 0)
			])
			glow.color = Color(color.r, color.g, color.b, 0.3)
			body.add_child(glow)
	
	return body

static func _create_eyes(config: Dictionary) -> Node2D:
	var eyes = Node2D.new()
	var size = config["size"]
	
	# 左眼
	var left_eye = ColorRect.new()
	left_eye.size = Vector2(6 * size, 6 * size)
	left_eye.position = Vector2(-5 * size, -8 * size)
	left_eye.color = Color.WHITE
	eyes.add_child(left_eye)
	
	# 右眼
	var right_eye = ColorRect.new()
	right_eye.size = Vector2(6 * size, 6 * size)
	right_eye.position = Vector2(4 * size, -8 * size)
	right_eye.color = Color.WHITE
	eyes.add_child(right_eye)
	
	# 左瞳孔
	var left_pupil = ColorRect.new()
	left_pupil.size = Vector2(3 * size, 3 * size)
	left_pupil.position = Vector2(-4 * size, -7 * size)
	left_pupil.color = Color.BLACK
	eyes.add_child(left_pupil)
	
	# 右瞳孔
	var right_pupil = ColorRect.new()
	right_pupil.size = Vector2(3 * size, 3 * size)
	right_pupil.position = Vector2(5 * size, -7 * size)
	right_pupil.color = Color.BLACK
	eyes.add_child(right_pupil)
	
	return eyes

static func _create_feet(config: Dictionary) -> Node2D:
	var feet = Node2D.new()
	feet.set("is_feet", true)
	var size = config["size"]
	
	# 左脚
	var left_foot = ColorRect.new()
	left_foot.size = Vector2(8 * size, 6 * size)
	left_foot.position = Vector2(-8 * size, 16 * size)
	left_foot.color = config["color"].darkened(0.3)
	feet.add_child(left_foot)
	feet.set("left_foot", left_foot)
	
	# 右脚
	var right_foot = ColorRect.new()
	right_foot.size = Vector2(8 * size, 6 * size)
	right_foot.position = Vector2(4 * size, 16 * size)
	right_foot.color = config["color"].darkened(0.3)
	feet.add_child(right_foot)
	feet.set("right_foot", right_foot)
	
	return feet
