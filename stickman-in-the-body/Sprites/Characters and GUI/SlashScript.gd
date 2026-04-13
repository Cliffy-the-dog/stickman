extends AnimatedSprite2D



# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	hide()


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if Input.is_action_just_pressed("Walk Left"):
		position = Vector2(-130, 0) 
		flip_h = true
	if Input.is_action_just_pressed("Walk Right"):
		position = Vector2(130, 0) 
		flip_h = false
	
	if Input.is_action_just_pressed("Slash"):
		show()
		play("Slash")
		await animation_finished
		hide()
