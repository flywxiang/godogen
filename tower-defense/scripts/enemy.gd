extends Node2D

var enemy_type: String = "normal"
var enemy_name: String = "普通"
var enemy_icon: String = "👹"
var max_health: float = 100.0
var health: float = 100.0
var speed: float = 100.0
var reward: int = 10
var armor: float = 0.0
var magic_resist: float = 0.0
var path_index: int = 0
var path_progress: float = 0.0
var reached_end: bool = false
var slowed: float = 0.0
var slow_timer: float = 0.0
var is_boss: bool = false
var boss_data: Dictionary = {}
var enemy_path: Array = []

# 特殊能力
var is_shadow: bool = false  # 隐身
var is_healer: bool = false  # 治疗
var is_elite: bool = false  # 精英
var heal_timer: float = 0.0
var invisible_timer: float = 0.0
var is_invisible: bool = false
var teleport_timer: float = 0.0
var particles_emitted: bool = false

@onready var health_bar: ProgressBar = $HealthBar
@onready var enemy_sprite: ColorRect = $EnemySprite
@onready var type_icon: Label = $TypeIcon

func _ready() -> void:
	health_bar.max_value = max_health
	health_bar.value = health
	
	var colors = {
		"normal": Color(0.9, 0.3, 0.3),
		"armor": Color(0.5, 0.5, 0.6),
		"magic_resist": Color(0.4, 0.2, 0.6),
		"fast": Color(1.0, 0.8, 0.2),
		"shadow": Color(0.2, 0.1, 0.3),
		"healer": Color(0.2, 0.8, 0.4),
		"elite": Color(0.8, 0.5, 0.1)
	}
	enemy_sprite.color = colors.get(enemy_type, colors.normal)
	type_icon.text = enemy_icon
	
	# 特殊能力初始化
	is_shadow = (enemy_type == "shadow")
	is_healer = (enemy_type == "healer")
	is_elite = (enemy_type == "elite")
	
	if is_shadow:
		is_invisible = true
		invisible_timer = randf_range(2.0, 4.0)
	
	if is_healer:
		heal_timer = 3.0
	
	if is_elite:
		# 精英怪属性翻倍
		max_health *= 2.0
		health = max_health
		armor = min(0.7, armor + 0.2)
		magic_resist = min(0.7, magic_resist + 0.2)
		reward *= 2

func _process(delta: float) -> void:
	if reached_end:
		return
	
	# 隐身逻辑
	if is_shadow:
		invisible_timer -= delta
		if invisible_timer <= 0:
			is_invisible = !is_invisible
			invisible_timer = randf_range(2.0, 4.0)
		
		# 隐身时降低透明度
		var target_alpha = 0.3 if is_invisible else 1.0
		var current_alpha = enemy_sprite.modulate.a
		enemy_sprite.modulate.a = lerp(current_alpha, target_alpha, delta * 5)
	
	# 治疗逻辑
	if is_healer:
		heal_timer -= delta
		if heal_timer <= 0:
			health = min(max_health, health + max_health * 0.1)
			health_bar.value = health
			heal_timer = 5.0
	
	# 减速处理
	if slow_timer > 0:
		slow_timer -= delta
	else:
		slowed = 0.0
	
	var current_speed = speed * (1.0 - slowed)
	path_progress += current_speed * delta
	
	if path_index >= 11 - 1:
		reached_end = true
		return
	
	if enemy_path.is_empty():
		return
	
	if path_index >= enemy_path.size() - 1:
		reached_end = true
		return
	
	var p1 = enemy_path[path_index]
	var p2 = enemy_path[path_index + 1]
	var segment_length = p1.distance_to(p2)
	
	if path_progress >= segment_length:
		path_progress -= segment_length
		path_index += 1
		if path_index >= enemy_path.size() - 1:
			reached_end = true
			return
	
	var t = path_progress / segment_length if segment_length > 0 else 0
	global_position = p1.lerp(p2, t)

func take_damage(amount: float, damage_type: String = "physical") -> void:
	if is_invisible and is_shadow:
		amount *= 0.5  # 隐身时受伤害减半
	
	var final_damage = amount
	
	if damage_type == "physical" or damage_type == "explosive":
		final_damage *= (1.0 - armor)
	elif damage_type == "magic":
		final_damage *= (1.0 - magic_resist)
	
	final_damage = max(1, final_damage)
	health -= final_damage
	health_bar.value = health
	
	# 治疗怪受伤时重置治疗计时
	if is_healer:
		heal_timer = 5.0
	
	if health <= 0:
		die()

func apply_slow(amount: float, duration: float) -> void:
	slowed = min(0.8, amount)
	slow_timer = duration

func die() -> void:
	get_parent().add_gold(reward)
	get_parent().add_kill()
	# 死亡特效 - 闪光
	get_parent().show_screen_flash(enemy_sprite.color)
	queue_free()
