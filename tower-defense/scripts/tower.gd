extends Node2D

class_name Tower

var tower_type: String = "arrow"
var tower_data: Dictionary = {}
var level: int = 1
var max_level: int = 3
var target: Node2D = null
var fire_timer: float = 0.0
var cooldown: float = 1.0

# Upgraded stats
var current_damage: float = 10.0
var current_range: float = 150.0
var current_fire_rate: float = 1.0

@onready var range_circle: Area2D = $RangeCircle
@onready var tower_base: ColorRect = $TowerBase
@onready var tower_top: ColorRect = $TowerTop
@onready var level_label: Label = $LevelLabel

func setup(data: Dictionary, pos: Vector2) -> void:
	tower_data = data
	global_position = pos
	
	# Apply base stats
	tower_base.size = Vector2(30, 30)
	tower_base.color = data.color
	
	tower_top.size = Vector2(20, 20)
	tower_top.color = data.color.lightened(0.3)
	tower_top.position = Vector2(-10, -25)
	
	range_circle/CollisionShape2D.shape.radius = data.range
	range_circle.visible = false
	
	# Apply upgrade
	apply_stats()

func apply_stats() -> void:
	var bonus = 1.0 + (level - 1) * 0.3
	current_damage = tower_data.damage * bonus
	current_range = tower_data.range * bonus
	current_fire_rate = tower_data.fire_rate * bonus
	cooldown = 1.0 / current_fire_rate if current_fire_rate > 0 else 1.0
	
	# Update range circle
	range_circle/CollisionShape2D.shape.radius = current_range
	
	# Update visual
	var level_colors = [
		Color(1, 1, 1),
		Color(1, 0.8, 0.2),  # Gold
		Color(0.2, 0.8, 1),   # Blue
		Color(1, 0.3, 1)      # Purple
	]
	tower_base.color = tower_data.color * (1.0 + level * 0.2)
	
	# Update level label
	level_label.text = "Lv.%d" % level
	level_label.visible = true

func upgrade() -> void:
	if level >= max_level:
		return
	
	level += 1
	apply_stats()
	
	# Visual feedback
	var tween = create_tween()
	tween.tween_property(tower_base, "scale", Vector2(1.3, 1.3), 0.2)
	tween.tween_property(tower_base, "scale", Vector2(1.0, 1.0), 0.2)

func _ready() -> void:
	range_circle.body_entered.connect(_on_body_entered)
	range_circle.body_exited.connect(_on_body_exited)

func _process(delta: float) -> void:
	fire_timer -= delta
	if fire_timer < 0:
		fire_timer = 0
	
	# Rotate towards target
	if target and is_instance_valid(target):
		var angle = global_position.angle_to_point(target.global_position)
		tower_top.rotation = angle + PI/2

func find_target(enemies: Array) -> void:
	target = null
	var closest_dist = INF
	
	for enemy in enemies:
		if not is_instance_valid(enemy):
			continue
		var dist = global_position.distance_to(enemy.global_position)
		if dist <= current_range and dist < closest_dist:
			closest_dist = dist
			target = enemy

func fire_if_ready() -> void:
	if not target or not is_instance_valid(target):
		return
	if fire_timer > 0:
		return
	
	fire_timer = cooldown
	spawn_projectile()

func spawn_projectile() -> void:
	var proj_scene = load("res://scenes/projectile.tscn")
	var proj = proj_scene.instantiate()
	
	# Calculate damage with type effectiveness
	var damage = calculate_damage()
	
	proj.setup(global_position, target, {
		"damage": damage,
		"color": tower_data.color,
		"damage_type": tower_data.damage_type,
		"effective_against": tower_data.effective_against,
		"tower_level": level
	})
	
	get_parent().add_child(proj)
	get_parent().projectiles.append(proj)

func calculate_damage() -> float:
	# Base damage with upgrade bonus
	var base_damage = current_damage
	
	# Critical hit chance (10% per level, max 30%)
	var crit_chance = level * 0.1
	if randf() < crit_chance:
		base_damage *= 2.0
	
	return base_damage

func _on_body_entered(body: Node2D) -> void:
	pass

func _on_body_exited(body: Node2D) -> void:
	if body == target:
		target = null
