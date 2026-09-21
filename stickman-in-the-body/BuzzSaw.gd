extends CharacterBody2D

@export var spin_speed: float = 4.0

@onready var fixed_position: Vector2 = global_position


## Buzz saws ignore damage and cannot be destroyed.
func take_damage(damage) -> void:
	pass


## Spins the saw in place and resets position so it stays anchored.
func _physics_process(delta: float) -> void:
	rotation += spin_speed * delta
	global_position = fixed_position
	velocity = Vector2.ZERO
