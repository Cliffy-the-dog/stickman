extends Control
@onready var settings: Control = $Settings


func _ready() -> void:
	settings.z_index = -110

#In case something goes wrong, starter scene path is res://Scenes/starter_scene.tscn

func _on_play_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/levels/starter_scene.tscn")


func _on_quit_pressed() -> void:
	get_tree().quit()


func _on_settings_pressed() -> void:
	settings.z_index = 100
