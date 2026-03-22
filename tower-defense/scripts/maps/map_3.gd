extends MapBase

func _init():
	map_name = "魔法山谷"
	map_level = 3
	map_color = Color(0.4, 0.3, 0.7)
	
	path_points = [
		Vector2(-50, 350), Vector2(100, 350), Vector2(100, 150),
		Vector2(300, 150), Vector2(300, 500), Vector2(550, 500),
		Vector2(550, 250), Vector2(800, 250), Vector2(800, 450),
		Vector2(1050, 450), Vector2(1050, 300), Vector2(1300, 300)
	]
	spawn_position = Vector2(-50, 350)
