extends Node2D

class_name Tower

var tower_type: String = "arrow"
var tower_data: Dictionary = {}
var target: Node2D = null
var fire_timer: float = 0.0
var cooldown: float = 0.0

@onready var range_circle: Area2D = $RangeCircle
@onready var tower_base: ColorRect = $TowerBase
@onready var tower_top: ColorRect = $TowerTop

func setup(data: Dictionary, pos: Vector2) -> void:
	tower_data = data
	global_position = pos
	
	# Visual setup
	tower_base.size = Vector2(30, 30)
	tower_base.color = data.color
	
	tower_top.size = Vector2(20, 20)
	tower_top.color = data.color.lightened(0.3)
	tower_top.position = Vector2(-10, -25)
	
	# Range circle
	range_circle/CollisionShape2D.shape.radius = data.range
	range_circle.visible = false
	
	# Set cooldown
	cooldown = 1.0 / data.fire_rate if data.fire_rate > 0 else 1.0

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
		if dist <= tower_data.range and dist < closest_dist:
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
	proj.setup(global_position, target, tower_data)
	get_parent().add_child(proj)
	get_parent().projectiles.append(proj)

func _on_body_entered(body: Node2D) -> void:
	pass

func _on_body_exited(body: Node2D) -> void:
	if body == target:
		target = null
