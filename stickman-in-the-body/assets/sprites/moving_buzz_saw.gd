extends CharacterBody2D

@export var speed: float = 1200.0
var direction: int = 1 # 1 moves right, -1 moves left

# Make sure you have a Sprite2D (or AnimatedSprite2D) as a child node!
# Change "Sprite2D" to whatever your saw's image node is named.
@onready var saw_visual = $Circular

# Required by your prompt!
func take_damage(damage):
	pass

func _physics_process(delta: float) -> void:
	# 1. Spin ONLY the picture of the saw, not the physics body!
	if saw_visual:
		saw_visual.rotate(25 * delta)
		
	# 2. Set the speed based on our current direction
	velocity.x = direction * speed
	
	# 3. Move the saw (this calculates the physics)
	move_and_slide()
	
	# 4. If the saw bumps into something solid, flip the direction!
	if is_on_wall():
		direction *= -1
