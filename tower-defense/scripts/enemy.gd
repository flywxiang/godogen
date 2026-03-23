extends Node2D

var enemy_type: String = "normal"
var max_health: float = 100.0
var health: float = 100.0
var speed: float = 100.0
var reward: int = 10
var path_index: int = 0
var path_progress: float = 0.0
var reached_end: bool = false
var is_dead: bool = false
var walk_timer: float = 0.0
var walk_offset: float = 0.0
var armor: float = 0.0
var magic_resist: float = 0.0
var slow_amount: float = 0.0
var slow_timer: float = 0.0

func move_along_path(path_points: Array):
	if path_points.is_empty():
		return
	
	if path_index >= path_points.size() - 1:
		reached_end = true
		return
	
	# 更新减速状态
	if slow_timer > 0:
		slow_timer -= get_process_delta_time()
	else:
		slow_amount = 0.0
	
	var current_speed = speed * (1.0 - slow_amount)
	
	var p1 = path_points[path_index]
	var p2 = path_points[path_index + 1]
	var segment_length = p1.distance_to(p2)
	
	path_progress += current_speed * get_process_delta_time()
	
	if path_progress >= segment_length:
		path_progress -= segment_length
		path_index += 1
		if path_index >= path_points.size() - 1:
			reached_end = true
			return
	
	var t = path_progress / segment_length if segment_length > 0 else 0
	global_position = p1.lerp(p2, t)
	
	# 行走动画
	walk_timer += get_process_delta_time()
	walk_offset = sin(walk_timer * 10) * 2
	
	# 更新生命条
	for child in get_children():
		if child.has("hp_bar") and child.hp_bar:
			child.size.x = 40 * (health / max_health) if max_health > 0 else 0

func apply_slow(amount: float, duration: float):
	slow_amount = max(slow_amount, amount)
	slow_timer = duration

func take_damage(amount: float):
	# 考虑护甲
	var final_damage = amount * (1.0 - armor)
	final_damage = max(1, final_damage)
	health -= final_damage
	
	if health <= 0 and not is_dead:
		is_dead = true
		die()

func die():
	# 死亡特效
	var death_effect = Node2D.new()
	death_effect.position = position
	
	for i in range(8):
		var particle = ColorRect.new()
		particle.size = Vector2(10, 10)
		particle.color = Color(0.9, 0.3, 0.3)
		particle.position = Vector2(randf() * 30 - 15, randf() * 30 - 15)
		death_effect.add_child(particle)
	
	get_parent().add_child(death_effect)
	
	# 延迟删除
	await get_tree().create_timer(0.5).timeout
	death_effect.queue_free()
	
	queue_free()
