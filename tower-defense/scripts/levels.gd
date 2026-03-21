extends Node

static func get_level_data(level: int) -> Dictionary:
	var LEVELS = {
		1: {
			"name": "新手村", "waves": 10, "start_gold": 200, "start_lives": 20,
			"enemy_types": ["normal", "fast"], "spawn_interval": 1.5,
			"wave_multiplier": 1.0, "boss_wave": 5, "boss_type": "boss_normal",
			"reward": 100, "map_color": Color(0.2, 0.6, 0.2), "description": "训练场"
		},
		2: {
			"name": "森林要塞", "waves": 10, "start_gold": 300, "start_lives": 25,
			"enemy_types": ["normal", "fast", "armor"], "spawn_interval": 1.3,
			"wave_multiplier": 1.3, "boss_wave": 5, "boss_type": "boss_armor",
			"reward": 200, "map_color": Color(0.3, 0.7, 0.3), "description": "装甲敌人"
		},
		3: {
			"name": "魔法山谷", "waves": 10, "start_gold": 400, "start_lives": 30,
			"enemy_types": ["normal", "fast", "armor", "magic_resist"], "spawn_interval": 1.2,
			"wave_multiplier": 1.6, "boss_wave": 5, "boss_type": "boss_magic",
			"reward": 350, "map_color": Color(0.4, 0.3, 0.7), "description": "魔抗敌人"
		},
		4: {
			"name": "钢铁前线", "waves": 10, "start_gold": 500, "start_lives": 35,
			"enemy_types": ["normal", "fast", "armor", "magic_resist"], "spawn_interval": 1.0,
			"wave_multiplier": 2.0, "boss_wave": 5, "boss_type": "boss_armor",
			"reward": 500, "map_color": Color(0.5, 0.5, 0.5), "description": "全面强化"
		},
		5: {
			"name": "最终决战", "waves": 10, "start_gold": 600, "start_lives": 40,
			"enemy_types": ["normal", "fast", "armor", "magic_resist"], "spawn_interval": 0.8,
			"wave_multiplier": 2.5, "boss_wave": 5, "boss_type": "boss_final",
			"reward": 1000, "map_color": Color(0.8, 0.2, 0.2), "description": "最终BOSS"
		}
	}
	return LEVELS.get(level, LEVELS[1])

static func get_boss_data(boss_type: String) -> Dictionary:
	var BOSSES = {
		"boss_normal": {"name": "哥布林首领", "health_multiply": 10, "speed_multiply": 0.7, "damage": 3, "reward": 100, "color": Color(0.6, 0.3, 0.1), "size_multiply": 2.0},
		"boss_armor": {"name": "铁甲巨兽", "health_multiply": 20, "speed_multiply": 0.5, "damage": 5, "reward": 150, "color": Color(0.4, 0.4, 0.5), "size_multiply": 2.5},
		"boss_magic": {"name": "黑暗法师", "health_multiply": 15, "speed_multiply": 0.6, "damage": 4, "reward": 150, "color": Color(0.3, 0.1, 0.5), "size_multiply": 2.0},
		"boss_final": {"name": "龙领主", "health_multiply": 30, "speed_multiply": 0.8, "damage": 8, "reward": 300, "color": Color(0.9, 0.1, 0.1), "size_multiply": 3.0}
	}
	return BOSSES.get(boss_type, BOSSES["boss_normal"])

static func get_total_levels() -> int:
	return 5
