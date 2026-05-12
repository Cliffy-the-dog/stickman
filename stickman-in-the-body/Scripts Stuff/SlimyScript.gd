extends CharacterBody2D
@onready var l: RayCast2D = $L
@onready var r: RayCast2D = $R
@onready var player: CharacterBody2D = %Player
@onready var healthbar: ProgressBar = $Healthbar
@onready var animated_sprite_2d: AnimatedSprite2D = $AnimatedSprite2D

var direction = 1
const SPEED = 30000.0
const JUMP_VELOCITY = -400.0
var goo_scene = preload("res://Sprites/Goo.tscn")

# Tracks the remaining cooldown time
var goo_cooldown = 0.0

func _physics_process(delta: float) -> void:
	if l.is_colliding():
		direction = 1
		animated_sprite_2d.flip_h = false
	if r.is_colliding():
		direction = -1
		animated_sprite_2d.flip_h = true
	
	velocity.x = direction * SPEED * delta
	move_and_slide()
	
	# Reduce the cooldown timer by elapsed frame time
	if goo_cooldown > 0:
		goo_cooldown -= delta

	# Check velocity and ensure cooldown has finished
	if velocity.length() > 0 and goo_cooldown <= 0:
		var goo_instance = goo_scene.instantiate()
		
		# Offset downwards. Adjust '32' to match half your character's height.
		var floor_offset = Vector2(0, 50) 
		goo_instance.global_position = global_position + floor_offset
		
		get_parent().add_child(goo_instance)
		
		# Reset the timer to 0.2 seconds
		goo_cooldown = 0.2

func take_damage(damage):
	healthbar.health -= damage
	healthbar.value -= damage
	if healthbar.value < 1:
		queue_free()
