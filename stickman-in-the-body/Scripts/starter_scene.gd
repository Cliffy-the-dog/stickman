extends Node2D

@onready var pause_menu: Control = $DirectionalLight2D/Management/Player/Camera2D2/PauseMenu
@onready var control: Control = $DirectionalLight2D/Management/Player/Camera2D2/Control

var paused: bool = false


# Listens for the pause action and toggles the pause menu.
func _process(_delta: float) -> void:
	if Input.is_action_just_pressed("Pause"):
		pauseMenu()
		control.mouse_filter = Control.MOUSE_FILTER_PASS
		pause_menu.mouse_filter = Control.MOUSE_FILTER_PASS


# Shows or hides the pause menu and adjusts Engine.time_scale.
func pauseMenu() -> void:
	if paused:
		pause_menu.hide()
		Engine.time_scale = 1
	else:
		pause_menu.show()
		Engine.time_scale = 0
	paused = not paused
