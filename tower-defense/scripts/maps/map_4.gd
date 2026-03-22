extends MapBase

func _init():
	map_name = "钢铁前线"
	map_level = 4
	map_color = Color(0.5, 0.5, 0.5)
	
	path_points = [
		Vector2(-50, 200), Vector2(150, 200), Vector2(150, 450),
		Vector2(350, 450), Vector2(350, 150), Vector2(600, 150),
		Vector2(600, 400), Vector2(850, 400), Vector2(850, 200),
		Vector2(1100, 200), Vector2(1100, 350), Vector2(1300, 350)
	]
	spawn_position = Vector2(-50, 200)
