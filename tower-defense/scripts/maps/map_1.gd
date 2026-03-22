extends MapBase

func _init():
	map_name = "新手村"
	map_level = 1
	map_color = Color(0.2, 0.6, 0.2)
	
	# 新手村路径 - 简单S形
	path_points = [
		Vector2(-50, 300), Vector2(150, 300), Vector2(150, 500),
		Vector2(400, 500), Vector2(400, 250), Vector2(700, 250),
		Vector2(700, 400), Vector2(1000, 400), Vector2(1000, 300),
		Vector2(1250, 300)
	]
	spawn_position = Vector2(-50, 300)
