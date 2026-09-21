extends Control

@onready var settings: Control = $Settings


# Places the settings panel behind other main menu UI elements.
func _ready() -> void:
	settings.z_index = -110


# Starts the game by loading the starter scene.
func _on_play_pressed() -> void:
	$AudioStreamPlayer.queue_free()
	get_tree().change_scene_to_file("res://scenes/levels/starter_scene.tscn")


# Exits the application.
func _on_quit_pressed() -> void:
	get_tree().quit()


# Brings the settings panel to the front.
func _on_settings_pressed() -> void:
	settings.z_index = 100
