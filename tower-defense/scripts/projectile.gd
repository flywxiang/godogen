extends Node2D

var target: Node2D = null
var tower_data: Dictionary = {}
var speed: float = 400.0
var lifetime: float = 0.0
var max_lifetime: float = 3.0
var hit: bool = false
var expired: bool = false

@onready var sprite: ColorRect = $Sprite

func setup(from: Vector2, to: Node2D, data: Dictionary) -> void:
	global_position = from
	target = to
	tower_data = data
	sprite.color = data.color
	sprite.size = Vector2(6, 6)

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
		target.take_damage(tower_data.damage)
		
		# Apply slow if magic tower
		if tower_data.has("slow"):
			target.apply_slow(tower_data.slow, 2.0)
	
	queue_free()
