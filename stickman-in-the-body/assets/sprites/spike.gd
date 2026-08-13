extends Sprite2D

@export var lifetime: float = 5.0
var damage: int = 15

func _ready():
	# Start the self-destruct timer
	await get_tree().create_timer(lifetime).timeout
	queue_free()

func _on_area_2d_body_entered(body):
	# Bulletproof check: Does it have health, and is it NOT the boss?
	if body.has_method("take_damage") and not "Boss" in body.name:
		if "is_pogoing" in body and body.is_pogoing and body.velocity.y > 0:
			# Player is pogoing! Block damage so the player script handles the bounce.
			return
		else:
			# Normal hit!
			body.take_damage(damage)

func take_damage(_amount):
	pass
