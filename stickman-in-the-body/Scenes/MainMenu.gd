extends Control




#In case something goes wrong, starter scene path is res://Scenes/starter_scene.tscn

func _on_play_pressed() -> void:
	get_tree().change_scene_to_file("res://Scenes/starter_scene.tscn")


func _on_settings_pressed() -> void:
	pass # Replace with function body.


func _on_quit_pressed() -> void:
	get_tree().quit()
