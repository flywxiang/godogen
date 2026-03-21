extends Node2D

# 像素艺术资源生成器

const TOWER_COLORS = {
	"arrow": {"base": Color(0x2d5a27), "accent": Color(0x4a8f3c), "weapon": Color(0x8b4513)},
	"cannon": {"base": Color(0x8b4513), "accent": Color(0xcd853f), "weapon": Color(0x2f2f2f)},
	"magic": {"base": Color(0x4a1c6b), "accent": Color(0x7b4ba8), "weapon": Color(0x9b59b6)}
}

const ENEMY_COLORS = {
	"normal": {"body": Color(0x8b0000), "eye": Color(0xffff00)},
	"armor": {"body": Color(0x4a4a4a), "accent": Color(0x6a6a6a)},
	"magic_resist": {"body": Color(0x4a1c6b), "accent": Color(0x9b59b6)},
	"fast": {"body": Color(0xffd700), "accent": Color(0xffa500)}
}

func create_tower_texture(type: String, size: Vector2) -> Image:
	var img = Image.create(size.x, size.y, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	
	var colors = TOWER_COLORS.get(type, TOWER_COLORS["arrow"])
	
	match type:
		"arrow":
			_draw_arrow_tower(img, size, colors)
		"cannon":
			_draw_cannon_tower(img, size, colors)
		"magic":
			_draw_magic_tower(img, size, colors)
	
	return img

func _draw_arrow_tower(img: Image, size: Vector2, colors: Dictionary):
	var cx = size.x / 2
	var cy = size.y / 2
	
	# 基座 - 圆形平台
	for y in range(size.y * 0.5, size.y * 0.8):
		for x in range(size.x * 0.2, size.x * 0.8):
			var dist = Vector2(x - cx, y - cy).length()
			if dist < size.x * 0.35:
				img.set_pixel(x, y, colors.base)
	
	# 塔身 - 绿色方块
	for y in range(size.y * 0.3, size.y * 0.6):
		for x in range(size.x * 0.3, size.x * 0.7):
			img.set_pixel(x, y, colors.accent)
	
	# 顶部 - 弓箭
	for y in range(size.y * 0.1, size.y * 0.35):
		for x in range(size.x * 0.45, size.x * 0.55):
			img.set_pixel(x, y, colors.weapon)
	
	# 弓弦
	for i in range(10):
		var t = float(i) / 10.0
		var x = cx + (t - 0.5) * size.x * 0.3
		var y = size.y * 0.2 + sin(t * PI) * size.y * 0.1
		img.set_pixel(x, y, colors.weapon)

func _draw_cannon_tower(img: Image, size: Vector2, colors: Dictionary):
	var cx = size.x / 2
	var cy = size.y / 2
	
	# 基座 - 方形平台
	for y in range(size.y * 0.5, size.y * 0.8):
		for x in range(size.x * 0.2, size.x * 0.8):
			img.set_pixel(x, y, colors.base)
	
	# 炮台底座
	for y in range(size.y * 0.35, size.y * 0.55):
		for x in range(size.x * 0.25, size.x * 0.75):
			img.set_pixel(x, y, colors.accent)
	
	# 炮管
	for y in range(size.y * 0.15, size.y * 0.35):
		for x in range(size.x * 0.4, size.x * 0.6):
			img.set_pixel(x, y, colors.weapon)
	
	# 炮口
	img.set_pixel(cx, size.y * 0.15, Color(0xff0000))

func _draw_magic_tower(img: Image, size: Vector2, colors: Dictionary):
	var cx = size.x / 2
	var cy = size.y / 2
	
	# 水晶基座
	for y in range(size.y * 0.5, size.y * 0.8):
		for x in range(size.x * 0.3, size.x * 0.7):
			img.set_pixel(x, y, colors.base)
	
	# 水晶核心
	for y in range(size.y * 0.2, size.y * 0.55):
		for x in range(size.x * 0.35, size.x * 0.65):
			var dist = Vector2(x - cx, y - cy * 0.7).length()
			if dist < size.x * 0.2:
				img.set_pixel(x, y, colors.accent)
	
	# 魔法粒子
	for i in range(8):
		var angle = i * PI / 4
		var px = cx + cos(angle) * size.x * 0.25
		var py = size.y * 0.35 + sin(angle) * size.y * 0.1
		img.set_pixel(px, py, colors.weapon)

func create_enemy_texture(type: String, size: Vector2) -> Image:
	var img = Image.create(size.x, size.y, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	
	var colors = ENEMY_COLORS.get(type, ENEMY_COLORS["normal"])
	
	match type:
		"normal":
			_draw_normal_enemy(img, size, colors)
		"armor":
			_draw_armor_enemy(img, size, colors)
		"magic_resist":
			_draw_magic_enemy(img, size, colors)
		"fast":
			_draw_fast_enemy(img, size, colors)
	
	return img

func _draw_normal_enemy(img: Image, size: Vector2, colors: Dictionary):
	var cx = size.x / 2
	var cy = size.y / 2
	
	# 身体
	for y in range(size.y * 0.3, size.y * 0.8):
		for x in range(size.x * 0.25, size.x * 0.75):
			img.set_pixel(x, y, colors.body)
	
	# 眼睛
	img.set_pixel(cx - size.x * 0.15, cy - size.y * 0.1, colors.eye)
	img.set_pixel(cx + size.x * 0.15, cy - size.y * 0.1, colors.eye)

func _draw_armor_enemy(img: Image, size: Vector2, colors: Dictionary):
	var cx = size.x / 2
	var cy = size.y / 2
	
	# 身体 - 方形带角
	for y in range(size.y * 0.2, size.y * 0.85):
		for x in range(size.x * 0.2, size.x * 0.8):
			img.set_pixel(x, y, colors.body)
	
	# 装甲纹路
	for y in range(size.y * 0.3, size.y * 0.5):
		img.set_pixel(size.x * 0.3, y, colors.accent)
		img.set_pixel(size.x * 0.7, y, colors.accent)

func _draw_magic_enemy(img: Image, size: Vector2, colors: Dictionary):
	var cx = size.x / 2
	var cy = size.y / 2
	
	# 魔法护盾身体
	for y in range(size.y * 0.25, size.y * 0.8):
		for x in range(size.y * 0.25, size.x * 0.75):
			var dist = Vector2(x - cx, y - cy).length()
			if dist < size.x * 0.35:
				img.set_pixel(x, y, colors.body)
	
	# 魔法光环
	for i in range(12):
		var angle = i * PI / 6
		var px = cx + cos(angle) * size.x * 0.4
		var py = cy + sin(angle) * size.y * 0.3
		img.set_pixel(px, py, colors.accent)

func _draw_fast_enemy(img: Image, size: Vector2, colors: Dictionary):
	var cx = size.x / 2
	var cy = size.y / 2
	
	# 流线型身体
	for y in range(size.y * 0.35, size.y * 0.7):
		for x in range(size.x * 0.15, size.x * 0.85):
			img.set_pixel(x, y, colors.body)
	
	# 速度线条
	for i in range(3):
		img.set_pixel(size.x * 0.1, cy + (i - 1) * size.y * 0.15, colors.accent)
