extends CharacterBody2D

@export var speed: float = 400.0
@export var spin_speed: float = 4.0

var direction: int = 1

@onready var saw_visual = $Circular


## Buzz saws ignore damage and cannot be destroyed.
func take_damage(damage) -> void:
	pass


## Spins the saw visual, moves horizontally, and reverses on wall contact.
func _physics_process(delta: float) -> void:
	if saw_visual:
		saw_visual.rotation += spin_speed * delta

	velocity.x = direction * speed
	move_and_slide()

	if is_on_wall():
		direction *= -1
