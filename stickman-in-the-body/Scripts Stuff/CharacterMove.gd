extends CharacterBody2D
@onready var character: AnimatedSprite2D = $AnimatedSprite2D


const SPEED = 1000.0
const JUMP_VELOCITY = -2000.0


func _physics_process(delta: float) -> void:
	# Add the gravity.
	if not is_on_floor():
		velocity += get_gravity() * delta * 5

	# Handle jump.
	if Input.is_action_just_pressed("Jump") and is_on_floor():
		velocity.y = JUMP_VELOCITY

	# Get the input direction and handle the movement/deceleration.
	# As good practice, you should replace UI actions with custom gameplay actions.
	var direction := Input.get_axis("Walk Left", "Walk Right")
	if direction > 0:
		character.flip_h = false
	elif direction < 0:
		character.flip_h = true
	
	if direction == 0:
		character.play("Idle")
	else:
		character.play("Walking")
	
	
	if direction:
		print("direction: ", direction, "  SPEED: ", SPEED)
		velocity.x = direction * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)
	

	move_and_slide()
