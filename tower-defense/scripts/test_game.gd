extends SceneTree

var tests_passed = 0
var tests_failed = 0
var errors = []
var game: Node = null

func _init():
	print("========================================")
	print("🎮 塔防游戏自动化测试")
	print("========================================")
	
	# 加载主场景
	var packed_scene = load("res://scenes/main.tscn")
	if packed_scene:
		game = packed_scene.instantiate()
		get_root().add_child(game)
		await create_timer(0.5).timeout
	else:
		fail_test("无法加载主场景")
		print_results()
		quit()
		return
	
	# 运行测试
	test_game_initialization()
	test_gold_system()
	test_wave_system()
	test_path()
	
	# 清理并输出结果
	game.queue_free()
	print_results()
	quit()

func test_game_initialization():
	print("\n📋 测试1: 游戏初始化")
	if game:
		var g = game.get("gold")
		var l = game.get("lives")
		if g != null and l != null and g >= 0 and l > 0:
			pass_test("gold=%d, lives=%d" % [g, l])
		else:
			fail_test("状态异常: gold=%s, lives=%s" % [str(g), str(l)])
	else:
		fail_test("Game节点为空")

func test_gold_system():
	print("\n📋 测试2: 金币系统")
	if game and game.has_method("add_gold"):
		var g = game.gold
		game.add_gold(100)
		var g2 = game.gold
		if g2 == g + 100:
			pass_test("add_gold正常: %d + 100 = %d" % [g, g2])
		else:
			fail_test("金币计算错误: %d + 100 = %d (got %d)" % [g, g + 100, g2])
	else:
		fail_test("找不到add_gold方法")

func test_wave_system():
	print("\n📋 测试3: 波次系统")
	if game:
		var w = game.get("wave")
		if w == 0:
			pass_test("波次初始值正确: %d" % w)
		else:
			fail_test("波次初始值错误: %d" % w)

func test_path():
	print("\n📋 测试4: 路径点")
	if game:
		var p = game.get("path_points")
		if p and p.size() >= 2:
			pass_test("路径点数量: %d" % p.size())
		else:
			fail_test("路径点无效")

func pass_test(msg: String):
	tests_passed += 1
	print("  ✅ %s" % msg)

func fail_test(msg: String):
	tests_failed += 1
	errors.append(msg)
	print("  ❌ %s" % msg)

func print_results():
	print("\n========================================")
	print("📊 测试结果")
	print("========================================")
	print("通过: %d" % tests_passed)
	print("失败: %d" % tests_failed)
	if tests_failed > 0:
		print("\n失败:")
		for e in errors:
			print("  - %s" % e)
	print("========================================")
	if tests_failed > 0:
		print("❌ 测试未全部通过!")
	else:
		print("✅ 所有测试通过!")
