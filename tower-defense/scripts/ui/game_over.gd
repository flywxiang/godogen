extends CanvasLayer

var victory: bool = true
var stars: int = 3
var wave: int = 10
var lives: int = 20
var gold_earned: int = 0

func _ready():
	$VBox/NextButton.pressed.connect(_on_next)
	$VBox/RetryButton.pressed.connect(_on_retry)
	$VBox/MenuButton.pressed.connect(_on_menu)
	
	_setup_display()

func setup(is_victory: bool, wave_num: int, remaining_lives: int, earned_gold: int):
	victory = is_victory
	wave = wave_num
	lives = remaining_lives
	gold_earned = earned_gold
	
	# 计算星级
	if victory:
		if lives >= 15 and earned_gold >= 200:
			stars = 3
		elif lives >= 10:
			stars = 2
		else:
			stars = 1
	else:
		stars = 0

func _setup_display():
	# 标题
	$VBox/Title.text = "🎉 通关!" if victory else "💀 失败"
	$VBox/Title.modulate = Color(1, 0.9, 0.2) if victory else Color(1, 0.3, 0.3)
	
	# 星级
	var star_text = ""
	for i in range(stars):
		star_text += "⭐"
	for i in range(3 - stars):
		star_text += "☆"
	$VBox/Stars.text = star_text
	
	# 统计
	$VBox/Stats/WaveLabel.text = "波次: %d/%d" % [wave, 10]
	$VBox/Stats/LivesLabel.text = "剩余生命: %d" % lives
	$VBox/Stats/GoldLabel.text = "获得金币: +%d" % gold_earned
	
	# 按钮
	$VBox/NextButton.visible = victory
	if victory:
		$VBox/NextButton.text = "▶ 下一关"

func _on_next():
	# 保存进度
	Global.unlock_level(Global.selected_level + 1)
	Global.add_gold(gold_earned)
	Global.set_star_rating(Global.selected_level, stars)
	
	# 加载下一关
	Global.selected_level += 1
	get_tree().change_scene_to_file("res://scenes/game.tscn")

func _on_retry():
	Global.add_gold(gold_earned)
	Global.set_star_rating(Global.selected_level, stars)
	get_tree().change_scene_to_file("res://scenes/game.tscn")

func _on_menu():
	Global.add_gold(gold_earned)
	Global.set_star_rating(Global.selected_level, stars)
	get_tree().change_scene_to_file("res://scenes/ui/level_select.tscn")
