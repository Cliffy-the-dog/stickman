extends Control


@onready var starter_scene: Node2D = $"../../../../"


func _ready() -> void:
	hide()

func _on_resume_pressed() -> void:
	starter_scene.pauseMenu()


func _on_options_pressed() -> void:
	pass # Replace with function body.


func _on_quit_to_menu_pressed() -> void:
	get_tree().change_scene_to_file("res://Scenes/control.tscn")
