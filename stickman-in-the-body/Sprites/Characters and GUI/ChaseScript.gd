extends RigidBody2D
@onready var healthbar: ProgressBar = $Healthbar
@export var speed = 700.0
@export var detection_range = 1000.0

# This looks for your AnimatedSprite2D child node
@onready var sprite = $AnimatedSprite2D 

var player = null
var is_chasing = false

func _ready():
	# Find the player by its unique name
	player = get_tree().root.find_child("Player", true, false)
	# Keeps the enemy from rolling over
	lock_rotation = true

func _physics_process(_delta):
	if player:
		var distance = global_position.distance_to(player.global_position)
		
		# Trigger the chase when too close
		if distance < detection_range:
			is_chasing = true
		
		if is_chasing:
			# Get direction (-1 or 1)
			var direction = sign(player.global_position.x - global_position.x)
			
			# Move the RigidBody
			linear_velocity.x = direction * speed
			
			# Flip and play animation
			if sprite:
				sprite.flip_h = direction < 0
				# Optional: Play your "run" animation
				sprite.play("Run")
		else:
			linear_velocity.x = 0
			# Optional: Play your "idle" animation
			sprite.play("Idle")
