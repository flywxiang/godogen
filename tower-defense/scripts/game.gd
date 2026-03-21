extends Node2D

# Game State
var gold: int = 200
var lives: int = 20
var wave: int = 0
var game_over: bool = false
var wave_in_progress: bool = false

# Tower definitions
const TOWER_TYPES = {
	"arrow": {"cost": 50, "damage": 10, "range": 150, "fire_rate": 1.0, "color": Color(0.2, 0.6, 0.2)},
	"cannon": {"cost": 100, "damage": 30, "range": 120, "fire_rate": 0.5, "color": Color(0.8, 0.4, 0.1)},
	"magic": {"cost": 80, "damage": 15, "range": 180, "fire_rate": 0.8, "color": Color(0.4, 0.2, 0.8), "slow": 0.5}
}

var selected_tower: String = ""
var towers: Array = []
var enemies: Array = []
var projectiles: Array = []

# Path waypoints
var path_points: Array = [
	Vector2(0, 300), Vector2(200, 300), Vector2(200, 500),
	Vector2(500, 500), Vector2(500, 200), Vector2(800, 200),
	Vector2(800, 400), Vector2(1100, 400), Vector2(1100, 300),
	Vector2(1300, 300)
]

# UI References
@onready var gold_label: Label = $UI/GoldLabel
@onready var lives_label: Label = $UI/LivesLabel
@onready var wave_label: Label = $UI/WaveLabel
@onready var message_label: Label = $UI/MessageLabel
@onready var tower_panel: Control = $UI/TowerPanel
var path_line: Line2D

func _ready() -> void:
	randomize()
	path_line = $PathLine
	_setup_path()
	_update_ui()
	show_message("Click tower button to select, then click on map to place!")

func _setup_path() -> void:
	path_line.clear_points()
	for point in path_points:
		path_line.add_point(point)

func _process(_delta: float) -> void:
	if game_over:
		return
	
	# Update enemies
	var to_remove_enemies = []
	for enemy in enemies:
		if enemy and is_instance_valid(enemy):
			enemy.move_along_path(path_points)
			if enemy.reached_end:
				lives -= 1
				_update_ui()
				to_remove_enemies.append(enemy)
				if lives <= 0:
					trigger_game_over()
		else:
			to_remove_enemies.append(enemy)
	
	for enemy in to_remove_enemies:
		enemies.erase(enemy)
		if enemy and is_instance_valid(enemy):
			enemy.queue_free()
	
	# Update towers
	for tower in towers:
		if tower and is_instance_valid(tower):
			tower.find_target(enemies)
			tower.fire_if_ready()
	
	# Update projectiles
	var to_remove_projectiles = []
	for proj in projectiles:
		if proj and is_instance_valid(proj):
			proj.move_projectile()
			if proj.hit or proj.expired:
				to_remove_projectiles.append(proj)
		else:
			to_remove_projectiles.append(proj)
	
	for proj in to_remove_projectiles:
		projectiles.erase(proj)
		if proj and is_instance_valid(proj):
			proj.queue_free()
	
	# Check wave completion
	if wave_in_progress and enemies.is_empty() and not game_over:
		wave_in_progress = false
		show_message("Wave %d complete! Gold bonus: +50" % wave)
		gold += 50
		_update_ui()

func _input(event: InputEvent) -> void:
	if game_over:
		return
	
	if event.is_action_pressed("place_tower") and selected_tower != "":
		var mouse_pos = get_global_mouse_position()
		attempt_place_tower(mouse_pos)
	
	if event.is_action_pressed("delete_tower"):
		var mouse_pos = get_global_mouse_position()
		attempt_remove_tower(mouse_pos)

func attempt_place_tower(pos: Vector2) -> bool:
	if selected_tower == "":
		return false
	
	var tower_data = TOWER_TYPES.get(selected_tower)
	if not tower_data:
		return false
	
	if gold < tower_data.cost:
		show_message("Not enough gold! Need %d" % tower_data.cost)
		return false
	
	# Check if position is valid (not on path, within bounds)
	if not _is_valid_position(pos):
		show_message("Cannot place tower here!")
		return false
	
	# Check for overlapping towers
	for tower in towers:
		if tower and is_instance_valid(tower):
			if tower.global_position.distance_to(pos) < 40:
				show_message("Too close to another tower!")
				return false
	
	gold -= tower_data.cost
	var tower = _create_tower(selected_tower, pos)
	towers.append(tower)
	_update_ui()
	show_message("%s tower placed!" % selected_tower.capitalize())
	return true

func _is_valid_position(pos: Vector2) -> bool:
	# Check bounds
	if pos.x < 50 or pos.x > 1200 or pos.y < 50 or pos.y > 650:
		return false
	
	# Check distance from path (simplified)
	for i in range(path_points.size() - 1):
		var p1 = path_points[i]
		var p2 = path_points[i + 1]
		var dist = _distance_to_segment(pos, p1, p2)
		if dist < 35:
			return false
	
	return true

func _distance_to_segment(p: Vector2, a: Vector2, b: Vector2) -> float:
	var ap = p - a
	var ab = b - a
	var t = clamp(ap.dot(ab) / ab.dot(ab), 0, 1)
	var closest = a + ab * t
	return p.distance_to(closest)

func attempt_remove_tower(pos: Vector2) -> void:
	for tower in towers:
		if tower and is_instance_valid(tower):
			if tower.global_position.distance_to(pos) < 25:
				var refund = TOWER_TYPES[tower.tower_type].cost / 2
				gold += refund
				towers.erase(tower)
				tower.queue_free()
				show_message("Tower sold! Refund: %d gold" % refund)
				_update_ui()
				return

func _create_tower(type: String, pos: Vector2) -> Node2D:
	var tower_scene = load("res://scenes/tower.tscn")
	var tower = tower_scene.instantiate()
	tower.tower_type = type
	tower.setup(TOWER_TYPES[type], pos)
	add_child(tower)
	return tower

func start_wave() -> void:
	if wave_in_progress:
		show_message("Wave already in progress!")
		return
	
	wave += 1
	wave_in_progress = true
	show_message("Wave %d incoming!" % wave)
	_update_ui()
	
	# Spawn enemies based on wave
	var enemy_count = 5 + wave * 2
	var enemy_health = 30 + wave * 10
	var spawn_delay = max(0.5, 2.0 - wave * 0.1)
	
	for i in range(enemy_count):
		await get_tree().create_timer(spawn_delay).timeout
		spawn_enemy(enemy_health)

func spawn_enemy(health: float) -> void:
	var enemy_scene = load("res://scenes/enemy.tscn")
	var enemy = enemy_scene.instantiate()
	enemy.max_health = health
	enemy.health = health
	enemy.speed = 80 + randi() % 40
	enemy.reward = 10 + wave * 2
	enemy.path_index = 0
	enemy.path_progress = 0.0
	enemy.reached_end = false
	add_child(enemy)
	enemies.append(enemy)

func trigger_game_over() -> void:
	game_over = true
	show_message("GAME OVER! You survived %d waves." % wave)
	$UI/GameOverPanel.visible = true

func restart_game() -> void:
	get_tree().reload_current_scene()

func _update_ui() -> void:
	gold_label.text = "Gold: %d" % gold
	lives_label.text = "Lives: %d" % lives
	wave_label.text = "Wave: %d" % wave

func show_message(msg: String) -> void:
	message_label.text = msg
	message_label.visible = true
	await get_tree().create_timer(3.0).timeout
	message_label.visible = false
