extends Node2D

var enemy_type: String = "normal"
var enemy_name: String = "普通"
var enemy_icon: String = "👹"
var max_health: float = 100.0
var health: float = 100.0
var speed: float = 100.0
var reward: int = 10
var armor: float = 0.0      # Physical damage reduction
var magic_resist: float = 0.0  # Magic damage reduction
var path_index: int = 0
var path_progress: float = 0.0
var reached_end: bool = false
var slowed: float = 0.0
var slow_timer: float = 0.0

var game_node: Node

@onready var health_bar: ProgressBar = $HealthBar
@onready var enemy_sprite: ColorRect = $EnemySprite
@onready var type_icon: Label = $TypeIcon

func _ready() -> void:
	health_bar.max_value = max_health
	health_bar.value = health
	
	# Set color based on type
	var colors = {
		"normal": Color(0.9, 0.3, 0.3),
		"armor": Color(0.5, 0.5, 0.6),
		"magic_resist": Color(0.4, 0.2, 0.6),
		"fast": Color(1.0, 0.8, 0.2)
	}
	enemy_sprite.color = colors.get(enemy_type, colors.normal)
	
	# Set icon
	type_icon.text = enemy_icon
	type_icon.tooltip_text = enemy_name
	
	game_node = get_parent()

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
	
	if not is_instance_valid(game_node):
		return
	
	var path = game_node.path_points
	if path_index >= len(path) - 1:
		reached_end = true
		return
	
	var p1 = path[path_index]
	var p2 = path[path_index + 1]
	var segment_length = p1.distance_to(p2)
	
	if path_progress >= segment_length:
		path_progress -= segment_length
		path_index += 1
		if path_index >= len(path) - 1:
			reached_end = true
			return
	
	# Interpolate position
	var t = path_progress / segment_length if segment_length > 0 else 0
	global_position = p1.lerp(p2, t)

func take_damage(amount: float, damage_type: String = "physical") -> void:
	var final_damage = amount
	
	# Apply armor/magic resist
	if damage_type == "physical" or damage_type == "explosive":
		final_damage *= (1.0 - armor)
	elif damage_type == "magic":
		final_damage *= (1.0 - magic_resist)
	
	final_damage = max(1, final_damage)  # Minimum 1 damage
	health -= final_damage
	health_bar.value = health
	
	if health <= 0:
		die()

func take_damage_no_type(amount: float) -> void:
	# For projectiles without damage type
	health -= amount
	health_bar.value = health
	
	if health <= 0:
		die()

func apply_slow(amount: float, duration: float) -> void:
	slowed = min(0.8, amount)  # Max 80% slow
	slow_timer = duration

func die() -> void:
	if is_instance_valid(game_node):
		game_node.gold += reward
		game_node._update_ui()
	
	queue_free()
