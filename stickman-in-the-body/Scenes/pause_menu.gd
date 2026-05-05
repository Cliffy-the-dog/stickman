extends Control


@onready var color_rect: ColorRect = $"../ColorRect"
@onready var starter_scene: Node2D = $"../../../../.."
@onready var control: Control = $"../Control"







func _ready() -> void:
	hide()



#Options is in the Control node underneath Options




func _process(_delta: float) -> void:
	if color_rect.local_hide == 1:
		hide()
	if color_rect.local_hide == 0:
		show()


func _on_resume_pressed() -> void:
	starter_scene.pauseMenu()


func _on_quit_to_menu_pressed() -> void:
	get_tree().change_scene_to_file("res://Scenes/control.tscn")
	Engine.time_scale = 1
