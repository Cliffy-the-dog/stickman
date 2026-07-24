extends Button
@onready var pause_menu: Control = $"../../../Camera2D2/PauseMenu"




func _on_pressed() -> void:
	pause_menu.save_game()
	get_tree().paused = false # <-- ADD THIS HERE
	Engine.time_scale = 1
	get_tree().change_scene_to_file("res://Scenes/levels/MainMenu.tscn")
