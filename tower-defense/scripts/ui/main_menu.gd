extends CanvasLayer

func _ready():
	$VBox/StartButton.pressed.connect(_on_start)
	$VBox/EndlessButton.pressed.connect(_on_endless)
	$VBox/QuitButton.pressed.connect(_on_quit)

func _on_start():
	get_tree().change_scene_to_file("res://scenes/ui/level_select.tscn")

func _on_endless():
	get_tree().change_scene_to_file("res://scenes/game.tscn")

func _on_quit():
	get_tree().quit()
