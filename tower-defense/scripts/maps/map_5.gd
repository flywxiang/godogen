extends MapBase

func _init():
	map_name = "最终决战"
	map_level = 5
	map_color = Color(0.8, 0.2, 0.2)
	
	path_points = [
		Vector2(-50, 400), Vector2(100, 400), Vector2(100, 150),
		Vector2(300, 150), Vector2(300, 500), Vector2(500, 500),
		Vector2(500, 200), Vector2(700, 200), Vector2(700, 450),
		Vector2(900, 450), Vector2(900, 250), Vector2(1100, 250),
		Vector2(1100, 350), Vector2(1300, 350)
	]
	spawn_position = Vector2(-50, 400)
