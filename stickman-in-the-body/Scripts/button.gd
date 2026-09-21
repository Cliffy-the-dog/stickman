extends Button

@onready var pause_menu: Control = $"../../../Camera2D2/PauseMenu"


# Saves the game and returns to the main menu scene.
func _on_pressed() -> void:
	pause_menu.save_game()
	get_tree().paused = false
	Engine.time_scale = 1
	get_tree().change_scene_to_file("res://scenes/levels/MainMenu.tscn")
