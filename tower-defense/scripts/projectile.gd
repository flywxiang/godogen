extends Node2D

var target: Node2D = null
var projectile_data: Dictionary = {}
var speed: float = 400.0
var lifetime: float = 0.0
var max_lifetime: float = 3.0
var hit: bool = false
var expired: bool = false

@onready var sprite: ColorRect = $Sprite

func setup(from: Vector2, to: Node2D, data: Dictionary) -> void:
	global_position = from
	target = to
	projectile_data = data
	sprite.color = data.color
	sprite.size = Vector2(6 + data.get("tower_level", 1) * 2, 6 + data.get("tower_level", 1) * 2)

func _process(delta: float) -> void:
	lifetime += delta
	if lifetime > max_lifetime:
		expired = true
		return
	
	if not is_instance_valid(target):
		expired = true
		return
	
	if hit:
		return
	
	# Move towards target
	var direction = (target.global_position - global_position).normalized()
	global_position += direction * speed * delta
	
	# Check hit
	if global_position.distance_to(target.global_position) < 10:
		hit = true
		_on_hit()

func _on_hit() -> void:
	if is_instance_valid(target):
		var damage_type = projectile_data.get("damage_type", "physical")
		var damage = projectile_data.get("damage", 10)
		
		# Call appropriate damage function
		if target.has_method("take_damage"):
			target.take_damage(damage, damage_type)
		
		# Apply slow if magic tower
		if projectile_data.get("effective_against") == "fast":
			target.apply_slow(0.3, 2.0)
	
	queue_free()
