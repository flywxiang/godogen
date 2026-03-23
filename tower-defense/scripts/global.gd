extends Node

var selected_level: int = 1
var selected_map: String = "res://scenes/maps/map_1.tscn"
var is_endless_mode: bool = false
var is_daily_challenge: bool = false

var player_gold: int = 200
var player_lives: int = 20
var current_wave: int = 0

var save_data: Dictionary = {
	"level_progress": [1],
	"star_ratings": {},
	"achievements": [],
	"total_gold": 0,
	"total_kills": 0,
	"endless_best_wave": 0,
	"high_score": 0
}

func _ready():
	_load_save()

func _load_save():
	var f = FileAccess.open("user://save.dat", FileAccess.READ)
	if f:
		var data = JSON.parse_string(f.get_as_text())
		if data:
			save_data = data
		f.close()

func _save_game():
	var f = FileAccess.open("user://save.dat", FileAccess.WRITE)
	if f:
		f.store_string(JSON.stringify(save_data))
		f.close()

func unlock_level(level: int):
	if not level in save_data["level_progress"]:
		save_data["level_progress"].append(level)
		_save_game()

func set_star_rating(level: int, stars: int):
	var key = "level_%d" % level
	if save_data["star_ratings"].get(key, 0) < stars:
		save_data["star_ratings"][key] = stars
		_save_game()

func add_gold(amount: int):
	save_data["total_gold"] += amount
	_save_game()

func get_level_progress() -> Array:
	return save_data.get("level_progress", [1])

func get_star_rating(level: int) -> int:
	var key = "level_%d" % level
	return save_data["star_ratings"].get(key, 0)

func get_total_gold() -> int:
	return save_data.get("total_gold", 0)
