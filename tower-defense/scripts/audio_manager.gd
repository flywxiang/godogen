extends Node

# 音效管理器
var music_playing: bool = false

func _ready():
	# 设置音量
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Master"), 0)

func play_sound(sound_name: String):
	# 简化的音效播放（使用内置beep）
	var sine = AudioStreamPlayer.new()
	sine.stream = AudioStreamGenerator.new()
	add_child(sine)
	
	var pitch = 1.0
	match sound_name:
		"shoot": pitch = 0.8
		"hit": pitch = 0.5
		"death": pitch = 0.3
		"coin": pitch = 1.2
		"click": pitch = 1.0
	
	sine.play()
	await get_tree().create_timer(0.1).timeout
	sine.queue_free()

func play_music():
	if not music_playing:
		music_playing = true
		# 背景音乐需要实际音频文件，这里标记
		print("🎵 Background music would play here")

func stop_music():
	music_playing = false
