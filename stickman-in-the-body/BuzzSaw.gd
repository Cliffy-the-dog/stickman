extends CharacterBody2D
@onready var fixed_position: Vector2 = global_position
func take_damage(damage):
	pass

func _process(delta: float) -> void:
	rotate(25*delta)
	
	# --- NEW: Snap it back to its starting spot every frame ---
	global_position = fixed_position
	velocity = Vector2.ZERO
