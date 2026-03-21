extends Node2D

var max_health: float = 100.0
var health: float = 100.0
var speed: float = 100.0
var reward: int = 10
var path_index: int = 0
var path_progress: float = 0.0
var reached_end: bool = false
var slowed: float = 0.0
var slow_timer: float = 0.0

@onready var health_bar: ProgressBar = $HealthBar
@onready var enemy_sprite: ColorRect = $EnemySprite

func _ready() -> void:
	health_bar.max_value = max_health
	health_bar.value = health
	enemy_sprite.color = Color(0.9, 0.3, 0.3)

func _process(delta: float) -> void:
	if reached_end:
		return
	
	# Handle slow effect
	if slow_timer > 0:
		slow_timer -= delta
	else:
		slowed = 0.0
	
	var current_speed = speed * (1.0 - slowed)
	
	# Move along path
	path_progress += current_speed * delta
	
	if path_index >= len(get_parent().path_points) - 1:
		reached_end = true
		return
	
	var p1 = get_parent().path_points[path_index]
	var p2 = get_parent().path_points[path_index + 1]
	var segment_length = p1.distance_to(p2)
	
	if path_progress >= segment_length:
		path_progress -= segment_length
		path_index += 1
		if path_index >= len(get_parent().path_points) - 1:
			reached_end = true
			return
	
	# Interpolate position
	var t = path_progress / segment_length if segment_length > 0 else 0
	global_position = p1.lerp(p2, t)

func take_damage(amount: float) -> void:
	health -= amount
	health_bar.value = health
	
	if health <= 0:
		die()

func apply_slow(amount: float, duration: float) -> void:
	slowed = amount
	slow_timer = duration

func die() -> void:
	# Award gold
	var game = get_parent()
	if game and has_node(".."):
		game.gold += reward
		game._update_ui()
	
	queue_free()
