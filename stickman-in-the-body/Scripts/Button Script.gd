extends AnimatedSprite2D



var buttondown = 0

func _ready() -> void:
	play("Not Pressed")

func _on_area_2d_body_entered(body: Node2D) -> void:
	if body.has_method("flash_red") and buttondown == 0:
		buttondown = 1
		play("Press")
		await animation_finished
		play("Pressed")
