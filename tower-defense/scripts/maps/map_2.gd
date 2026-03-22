extends MapBase

func _init():
	map_name = "森林要塞"
	map_level = 2
	map_color = Color(0.3, 0.7, 0.3)
	
	path_points = [
		Vector2(-50, 500), Vector2(200, 500), Vector2(200, 200),
		Vector2(500, 200), Vector2(500, 450), Vector2(800, 450),
		Vector2(800, 150), Vector2(1100, 150), Vector2(1100, 350),
		Vector2(1300, 350)
	]
	spawn_position = Vector2(-50, 500)
