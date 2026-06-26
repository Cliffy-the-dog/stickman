extends AnimatedSprite2D

var slashing_counts = 0


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	hide()


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if Input.is_action_just_pressed("Walk Left"):
		position = Vector2(-130, 0) 
		flip_h = false
	if Input.is_action_just_pressed("Walk Right"):
		position = Vector2(130, 0) 
		flip_h = true
	
	if Input.is_action_just_pressed("Slash"):
		if get_parent().is_on_floor():
			if slashing_counts == 0:
				slashing_counts = 1
				show()
				play("Slash")
				await animation_finished
				hide()
				await get_tree().create_timer(0.25).timeout
				slashing_counts = 0
				await get_tree().create_timer(0.25).timeout


#================================================================================================#
#                                   End of Script
