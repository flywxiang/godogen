extends Node2D

# 地图基础类 - 所有地图继承此类
class_name MapBase

signal enemy_spawned(enemy)
signal path_completed()

# 路径点 - 子类需要重写
var path_points: Array = [
	Vector2(-50, 360), Vector2(200, 360), Vector2(200, 550),
	Vector2(450, 550), Vector2(450, 200), Vector2(700, 200),
	Vector2(700, 400), Vector2(950, 400), Vector2(950, 300),
	Vector2(1150, 300), Vector2(1300, 300)
]

# 出生点位置
var spawn_position: Vector2 = Vector2(-50, 360)

# 地图配置 - 子类重写
var map_name: String = "默认地图"
var map_level: int = 1
var map_color: Color = Color(0.2, 0.3, 0.2)

func _ready():
	_setup_path_visual()

func _setup_path_visual():
	var line = Line2D.new()
	line.width = 50.0
	line.default_color = Color(0.3, 0.3, 0.2, 0.9)
	line.joint_mode = Line2D.LINE_JOINT_ROUND
	line.begin_cap_mode = Line2D.LINE_CAP_ROUND
	line.end_cap_mode = Line2D.LINE_CAP_ROUND
	
	for p in path_points:
		line.add_point(p)
	
	add_child(line)
	
	# 出生点标记
	var spawn_marker = ColorRect.new()
	spawn_marker.size = Vector2(40, 40)
	spawn_marker.color = Color(0.9, 0.3, 0.3, 0.8)
	spawn_marker.position = spawn_position - Vector2(20, 20)
	add_child(spawn_marker)

func get_path_points() -> Array:
	return path_points

func get_spawn_position() -> Vector2:
	return spawn_position
