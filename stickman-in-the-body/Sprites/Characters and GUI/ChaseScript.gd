extends RigidBody2D
@onready var healthbar: ProgressBar = $Healthbar
@export var speed = 600.0
@export var detection_range = 1000.0
@onready var music_manager: Node = %MusicManager
@onready var slash_area_2: Area2D = %SlashArea2
@onready var collision_shape_2d: CollisionShape2D = $Slash/SlashArea2/CollisionShape2D



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
			linear_velocity.x = direction * speed
			
			# Flip and play animation
			if sprite:
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


func _on_detection_zone_area_entered(area: Area2D) -> void:
	print("Area entered: ", area.name)
	if area.name == "SlashArea" or area == slash_area_2:
		healthbar.value = healthbar.value - 20
		for a in range(damage_value):
			healthbar.value = healthbar.value - 1
			await get_tree().create_timer(0.02).timeout
			healthbar.damage_bar.value = healthbar.value


func _on_detection_zone_body_entered(body: Node2D) -> void:
	print("Body entered: ", body.name)
	if body.name == "collision_shape_2d":
		healthbar.value -=20
		for a in range(damage_value):
			healthbar.value -= 1
			await get_tree().create_timer(0.02).timeout
			healthbar.damage_bar.value = healthbar.value
