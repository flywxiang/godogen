extends Node2D

# 粒子特效系统

class Particle:
	var pos: Vector2
	var vel: Vector2
	var life: float
	var max_life: float
	var color: Color
	var size: float
	
	func _init(p: Vector2, v: Vector2, l: float, c: Color, s: float):
		pos = p
		vel = v
		life = l
		max_life = l
		color = c
		size = s

var particles: Array = []

func _ready():
	pass

func _process(delta: float):
	# Update particles
	var to_remove = []
	for i in range(particles.size()):
		var p = particles[i]
		p.pos += p.vel * delta
		p.life -= delta
		if p.life <= 0:
			to_remove.append(i)
	
	# Remove dead particles
	for i in range(to_remove.size() - 1, -1, -1):
		particles.remove_at(to_remove[i])

func _draw():
	for p in particles:
		var alpha = p.life / p.max_life
		var current_size = p.size * alpha
		var c = Color(p.color.r, p.color.g, p.color.b, alpha)
		draw_circle(p.pos, current_size, c)

# 发射粒子爆炸
func explosion(pos: Vector2, color: Color, count: int = 20, speed: float = 100.0):
	for i in range(count):
		var angle = randf() * TAU
		var spd = speed * (0.5 + randf() * 0.5)
		var vel = Vector2(cos(angle), sin(angle)) * spd
		var life = 0.3 + randf() * 0.3
		var size = 3.0 + randf() * 3.0
		particles.append(Particle.new(pos, vel, life, color, size))

# 发射魔法光环
func magic_circle(pos: Vector2, color: Color, count: int = 12):
	for i in range(count):
		var angle = i * TAU / count
		var vel = Vector2(cos(angle), sin(angle)) * 50
		var life = 0.5
		var size = 4.0
		particles.append(Particle.new(pos, vel, life, color, size))

# 发射箭矢轨迹
func arrow_trail(pos: Vector2, color: Color):
	var vel = Vector2.ZERO
	var life = 0.2
	var size = 2.0
	particles.append(Particle.new(pos, vel, life, color, size))

# 发射敌人死亡效果
func enemy_death(pos: Vector2, color: Color):
	explosion(pos, color, 30, 150)
	# 添加闪光
	for i in range(5):
		var offset = Vector2(randf_range(-10, 10), randf_range(-10, 10))
		var vel = Vector2.ZERO
		var life = 0.2
		var size = 8.0
		particles.append(Particle.new(pos + offset, vel, life, Color(1, 1, 1), size))

# 发射金币获得效果
func gold_effect(pos: Vector2):
	for i in range(5):
		var angle = -PI / 2 + randf_range(-0.5, 0.5)
		var vel = Vector2(cos(angle), sin(angle)) * 80
		var life = 0.4
		var size = 3.0
		particles.append(Particle.new(pos, vel, life, Color(0xffd700), size))

# 发射升级效果
func upgrade_effect(pos: Vector2):
	for i in range(20):
		var angle = randf() * TAU
		var vel = Vector2(cos(angle), sin(angle)) * 60
		var life = 0.6
		var size = 4.0
		var colors = [Color(0xffd700), Color(0xffa500), Color(0xffff00)]
		var c = colors[randi() % colors.size()]
		particles.append(Particle.new(pos, vel, life, c, size))
