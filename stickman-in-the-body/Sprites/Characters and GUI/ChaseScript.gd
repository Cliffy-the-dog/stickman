extends RigidBody2D
@onready var healthbar: ProgressBar = $Healthbar
@export var speed = 600.0
@export var detection_range = 1000.0
@onready var music_manager: Node = %MusicManager
@onready var animatedSprite: AnimatedSprite2D = $AnimatedSprite2D

var not_dying = 1
var movable = 1
var damage_value = 20

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
		if distance < detection_range and not is_chasing:
			is_chasing = true
			# --- CHANGE THIS NAME TO YOUR AUTOLOAD NAME ---
			music_manager.start_chase(get_instance_id()) 

		
		
		# Trigger the chase when too close
		if distance < detection_range:
			is_chasing = true
		
		if is_chasing:
			# Get direction (-1 or 1)
			var direction = sign(player.global_position.x - global_position.x)
			
			# Move the RigidBody
			linear_velocity.x = direction * speed * movable
			
			# Flip and play animation
			if sprite and not_dying == 1:
				sprite.flip_h = direction < 0
				# Optional: Play your "run" animation
				sprite.play("Run")
		else:
			pass
			
	if healthbar.value < 0:
		if healthbar.value - 10 > -1:
			for a in range(damage_value):
				healthbar.value = healthbar.value - 1
				await get_tree().create_timer(0.02).timeout
				healthbar.damage_bar.value = healthbar.value

func take_damage(damage_amount) -> void:
	healthbar.value -= 20
	if healthbar.value < 0:
		healthbar.value = 0
	var direction = 0
	if sprite.flip_h == true:
		direction = 1
	if sprite.flip_h == false:
		direction = -1
	else:
		direction = 0
	if healthbar.value == 0:
		movable = 0
		not_dying = 0
		animatedSprite.play("Die")
		await animatedSprite.animation_finished
		queue_free()
