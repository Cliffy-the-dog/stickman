extends RigidBody2D

@onready var healthbar: ProgressBar = $Healthbar
@export var speed = 600.0
@export var detection_range = 1000.0
@onready var music_manager: Node = %MusicManager

var damage_value = 20

@onready var sprite = $AnimatedSprite2D 
var player = null
var is_chasing = false

func _ready():
	# Add enemy to group for detection
	add_to_group("enemy")
	
	player = get_tree().root.find_child("Player", true, false)
	lock_rotation = true
	healthbar.value = healthbar.max_value

func _physics_process(_delta):
	if player:
		var distance = global_position.distance_to(player.global_position)
		if distance < detection_range and not is_chasing:
			is_chasing = true
			music_manager.start_chase(get_instance_id()) 
		
		if distance < detection_range:
			is_chasing = true
		
		if is_chasing:
			var direction = sign(player.global_position.x - global_position.x)
			linear_velocity.x = direction * speed
			
			if sprite:
				sprite.flip_h = direction < 0
				sprite.play("Run")
		else:
			pass

func Enemy_take_damage(amount):
	healthbar.value -= amount
	print("Enemy took ", amount, " damage! Health left: ", healthbar.value)
	
	# Visual feedback
	modulate = Color.RED
	await get_tree().create_timer(0.1).timeout
	modulate = Color.WHITE
	
	# Update damage bar if you have one
	if healthbar.has_node("damage_bar"):
		healthbar.damage_bar.value = healthbar.value
	
	if healthbar.value <= 0:
		die()

func die():
	print("Enemy died!")
	queue_free()
