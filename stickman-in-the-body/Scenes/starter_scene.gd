extends Node2D

@onready var pause_menu: Control = $CanvasModulate/Management/Player/Camera2D2/PauseMenu
@onready var canvas_modulate: CanvasModulate = $CanvasModulate



var paused = false

func _ready() -> void:
	Color(1,1,1)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if Input.is_action_just_pressed("Pause"):
		pauseMenu()

func pauseMenu():
	if paused == true:
		pause_menu.hide()
		Engine.time_scale = 1
	else:
		pause_menu.show()
		Engine.time_scale = 0
	paused = !paused
