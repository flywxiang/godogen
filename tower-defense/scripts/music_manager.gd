extends Node

# 背景音乐和音效管理器
var music_enabled: bool = true
var sfx_enabled: bool = true

func _ready():
	# 可以在这里加载音频流
	pass

func toggle_music():
	music_enabled = !music_enabled
	return music_enabled

func toggle_sfx():
	sfx_enabled = !sfx_enabled
	return sfx_enabled

# 播放各种音效的提示音（使用简单的正弦波）
func play_shoot():
	if sfx_enabled:
		_play_tone(0.8, 0.1)

func play_hit():
	if sfx_enabled:
		_play_tone(0.5, 0.15)

func play_death():
	if sfx_enabled:
		_play_tone(0.3, 0.3)

func play_coin():
	if sfx_enabled:
		_play_tone(1.2, 0.1)

func play_wave_start():
	if sfx_enabled:
		_play_tone(1.0, 0.2)
		await get_tree().create_timer(0.1).timeout
		_play_tone(1.3, 0.2)

func play_level_complete():
	if sfx_enabled:
		_play_tone(1.0, 0.15)
		await get_tree().create_timer(0.15).timeout
		_play_tone(1.2, 0.15)
		await get_tree().create_timer(0.15).timeout
		_play_tone(1.5, 0.3)

func _play_tone(freq: float, duration: float):
	# 创建一个简单的音频流播放器
	var player = AudioStreamPlayer.new()
	player.volume_db = -10  # 降低音量
	
	# 创建简单的正弦波
	var stream = AudioStreamGenerator.new()
	stream.mix_rate = 44100
	player.stream = stream
	
	add_child(player)
	player.play()
	
	# 简单延迟后停止
	await get_tree().create_timer(duration).timeout
	player.queue_free()
