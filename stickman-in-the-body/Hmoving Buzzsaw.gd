extends CharacterBody2D

# Grab a reference to your RayCast node (Make sure the name matches your scene!)
@onready var raycast: RayCast2D = $RayCast2D 
@onready var fixed_position: Vector2 = global_position

func take_damage(damage):
	pass

# Change this to _physics_process so it syncs with the RayCast!
func _physics_process(delta: float) -> void:
	rotate(25 * delta)
	
