extends CharacterBody2D

@export var spin_speed: float = 4.0

@onready var raycast: RayCast2D = $RayCast2D
@onready var fixed_position: Vector2 = global_position


## Buzz saws ignore damage and cannot be destroyed.
func take_damage(damage) -> void:
	pass


## Spins the saw visual each physics frame at a fixed rad/sec rate.
func _physics_process(delta: float) -> void:
	rotation += spin_speed * delta
