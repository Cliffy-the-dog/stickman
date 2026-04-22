extends RigidBody2D

@onready var healthbar: ProgressBar = $Healthbar
@export var speed = 600.0
@export var detection_range = 1000.0
@onready var music_manager: Node = %MusicManager
@onready var animatedSprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var sprite = $AnimatedSprite2D 

var multiplier = 1
var not_dying = 1
var movable = 1
var damage_value = 20
var player = null
var is_chasing = false

func _ready():
	player = get_tree().root.find_child("Player", true, false)
	lock_rotation = true

func _physics_process(_delta):
	if player:
		var distance = global_position.distance_to(player.global_position)
		
		# Moved music call here so it triggers ONCE when the chase begins
		if distance < detection_range and not is_chasing:
			is_chasing = true
			music_manager.start_chase(get_instance_id()) 
		
		if is_chasing:
			var direction = sign(player.global_position.x - global_position.x)
			linear_velocity.x = direction * speed * movable * multiplier
			
			if sprite and not_dying == 1:
				sprite.flip_h = direction < 0
				sprite.play("Run")

	if healthbar.value < 0:
		if healthbar.value - 10 > -1:
			for a in range(damage_value):
				healthbar.value = healthbar.value - 1
				await get_tree().create_timer(0.02).timeout
				healthbar.damage_bar.value = healthbar.value

@warning_ignore("unused_parameter")
func take_damage(damage_amount) -> void:
	healthbar.value -= 20
	multiplier = -1
	await get_tree().create_timer(0.15).timeout
	multiplier = 1
	
	if healthbar.value < 0:
		healthbar.value = 0
		
	@warning_ignore("unused_variable")
	var direction = 0
	if sprite.flip_h == true:
		direction = 1
	elif sprite.flip_h == false: # Changed to elif for logic clarity
		direction = -1
		
	if healthbar.value == 0:
		# Moved stop_chase here so it only triggers ONCE upon death
		music_manager.stop_chase(get_instance_id())
		movable = 0
		not_dying = 0
		animatedSprite.play("Die")
		await animatedSprite.animation_finished
		queue_free()
