extends Node

func _ready():
	# 等待游戏就绪
	await get_tree().create_timer(0.1).timeout
	var game = get_parent()
	
	# 连接关卡按钮
	var level_buttons = []
	for i in range(1, 6):
		var btn = get_node_or_null("/root/Game/UI/LevelPanel/VBox/Grid/Level%d" % i)
		if btn:
			var level_num = i
			btn.pressed.connect(_on_level.bind(level_num, game))
	
	# 连接塔按钮
	var arrow_btn = get_node_or_null("/root/Game/UI/TowerArrow")
	var cannon_btn = get_node_or_null("/root/Game/UI/TowerCannon")
	var magic_btn = get_node_or_null("/root/Game/UI/TowerMagic")
	var start_btn = get_node_or_null("/root/Game/UI/StartWaveButton")
	var level_btn = get_node_or_null("/root/Game/UI/LevelButton")
	
	if arrow_btn:
		arrow_btn.pressed.connect(_on_tower.bind(0, game))
	if cannon_btn:
		cannon_btn.pressed.connect(_on_tower.bind(1, game))
	if magic_btn:
		magic_btn.pressed.connect(_on_tower.bind(2, game))
	if start_btn:
		start_btn.pressed.connect(_on_start_wave.bind(game))
	if level_btn:
		level_btn.pressed.connect(_on_show_level.bind(game))
	
	# 连接消息定时器
	var msg_timer = get_node_or_null("/root/Game/UI/MessageLabel/Timer")
	if msg_timer:
		msg_timer.timeout.connect(_on_message_timer.bind(game))

func _on_level(level_num: int, game):
	if game:
		game._on_level_pressed(level_num)

func _on_tower(type_idx: int, game):
	if game:
		game._select_tower(type_idx)

func _on_start_wave(game):
	if game:
		game.start_wave()

func _on_show_level(game):
	if game:
		game.show_level_select()

func _on_message_timer(game):
	if game:
		game._on_message_timer_timeout()
