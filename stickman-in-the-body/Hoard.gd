extends CharacterBody2D

@onready var Target: CharacterBody2D = %Player
@onready var healthbar: ProgressBar = $Healthbar
@onready var Respawnpoint: Area2D = $"../Area2D2"
@onready var character: AnimatedSprite2D = $Character


var cooldown = 0
const SPEED = 1200.0
const JUMP_VELOCITY = -1800.0
var distance
var awakened = 0
var side

# 1. Preload the "Head" scene
var head_scene = preload("res://Head.tscn")

func _ready() -> void:
	velocity.x = 0
	velocity.y = 0
	healthbar.value = healthbar.max_value

func _physics_process(delta: float) -> void:
	# Vector from you to target
	var to_target = Target.global_position - global_position

	# 'transform.x' is your local right vector in 2D
	side = sign(transform.x.dot(to_target))
	
	# Add the gravity.
	if not is_on_floor():
		velocity += get_gravity() * delta
	
	distance = global_position.distance_to(Target.global_position)
	
	# Awakening logic
	if not distance < 1200 and awakened == 0:
		character.play("Unawakened")
	
	if distance < 1200 and awakened == 0:
		character.play("Awakening")
		await character.animation_finished
		awakened = 1
	
	# Start Fight logic
	if awakened == 1 and cooldown == 0:
		cooldown = 1
		Fight()
		character.play("Idle")
	move_and_slide()
	if Target.healthbar.value == 0:
		healthbar.value = healthbar.max_value
		awakened = 0
		global_position = Respawnpoint.global_position
		character.play("Unawakened")

func Jump():
	velocity.y = JUMP_VELOCITY
	velocity.x = randi_range(-100,100)

func Projectile(target_node: Node2D):
	var head_instance = head_scene.instantiate()
	add_child(head_instance)
	head_instance.global_position = global_position
	var speed = 1400.0 
	var dist = global_position.distance_to(target_node.global_position)
	var duration = dist / speed
	var tween = create_tween()
	tween.tween_property(head_instance, "global_position", target_node.global_position, duration)
	tween.tween_callback(head_instance.queue_free)

func Dash():
	velocity.x = SPEED * side
	await get_tree().create_timer(0.3).timeout
	velocity.x = 0

func Fight():
	var RNG = randi_range(1, 5)
	
	if RNG == 1 or RNG == 2:
		Dash()
	elif RNG == 3 or RNG == 4:
		Projectile(Target)
	elif RNG == 5:
		Jump()
		# Wait a tiny bit so is_on_floor() becomes false after leaving the ground
		await get_tree().create_timer(0.1).timeout 
		while not is_on_floor():
			await get_tree().process_frame 
	
	# Wait the 3 seconds AFTER the action is done
	await get_tree().create_timer(0.3).timeout
	# Now the next Fight() can't start until this is reached
	cooldown = 0

func take_damage():
	healthbar.value -= 20
