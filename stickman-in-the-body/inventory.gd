extends Control

var HIDDEN = true

func _ready() -> void:
	HIDDEN = true
	hide()

func _process(delta: float) -> void:
	if Input.is_action_just_pressed("Inventory") and HIDDEN:
		show()
	elif Input.is_action_just_pressed("Interact") and not HIDDEN:
		hide()
	if not HIDDEN:
		Engine.time_scale = 0
		Engine.time_scale = 1
