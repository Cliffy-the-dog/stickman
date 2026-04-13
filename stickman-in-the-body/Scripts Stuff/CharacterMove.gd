extends CharacterBody2D
@onready var animated_sprite_2d: AnimatedSprite2D = $AnimatedSprite2D
@onready var character: AnimatedSprite2D = $AnimatedSprite2D
@onready var healthbar: ProgressBar = $Healthbar
@onready var management: Node = %Management
var damage_taken_in_the_past_0point4seconds = 0
var damage_value = 10
var butchering_in_progress = 0
var bouncing_in_progress = 0
func _ready():
	healthbar.health = 100 + 20 * management.health_upgrades

const SPEED = 1200.0
const JUMP_VELOCITY = -2200.0


func _physics_process(delta: float) -> void:
	# Add the gravity.
	if not is_on_floor():
		velocity += get_gravity() * delta * 5
		

	# Handle jump.
	if Input.is_action_just_pressed("Jump") and is_on_floor():
		velocity.y = JUMP_VELOCITY
		bouncing_in_progress = 1
		character.play("Jump")
		if is_on_floor():
			bouncing_in_progress = 0
		await is_on_floor()
		bouncing_in_progress = 0
	if Input.is_action_just_pressed("Slash"):
		if bouncing_in_progress == 0:
			butchering_in_progress = 1
			character.play("Butcher")
			await character.animation_finished
			butchering_in_progress = 0
	# Get the input direction and handle the movement/deceleration.
	var direction := Input.get_axis("Walk Left", "Walk Right")
	if direction > 0:
		character.flip_h = false
	elif direction < 0:
		character.flip_h = true
	
	if direction == 0 and butchering_in_progress == 0 and bouncing_in_progress == 0:
		character.play("Idle")
	elif is_on_floor():
		if butchering_in_progress == 0 and bouncing_in_progress == 0:
			character.play("Walking")
	if not is_on_floor():
		if JUMP_VELOCITY < 0:
			character.play("Falling")
	
	if direction:
		velocity.x = direction * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)
		


	move_and_slide()
	
	
	# Check every object the player is currently touching
	for i in get_slide_collision_count():
		var collision = get_slide_collision(i)
	
	# ONLY proceed if the collision actually exists
		if collision:
			var collider = collision.get_collider()
		
		# Now it's safe to check if it's the enemy
			if collider is RigidBody2D:
				print("Player is touching the enemy!")
				if healthbar.health > 0 and damage_taken_in_the_past_0point4seconds == 0:
					if healthbar.health - 10 > -1:
						damage_taken_in_the_past_0point4seconds = 1
						for a in range(damage_value):
							healthbar.health = healthbar.health - 1
							await get_tree().create_timer(0.02).timeout
						damage_taken_in_the_past_0point4seconds = 0
						healthbar.damage_bar.value = healthbar.health

					else:
						print("Bro you're already dead.")
#End of script
