extends AnimatedSprite2D

var slashing_counts = 0


## Hides the slash sprite until an attack is triggered.
func _ready() -> void:
	hide()


## Positions the slash sprite on input and plays a single slash animation.
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
