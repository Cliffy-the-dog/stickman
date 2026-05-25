extends CharacterBody2D

@onready var particles: Array = [
	$CPUParticles2D, $CPUParticles2D2, $CPUParticles2D3, $CPUParticles2D4,
	$CPUParticles2D5, $CPUParticles2D6, $CPUParticles2D7, $CPUParticles2D8,
	$CPUParticles2D9, $CPUParticles2D10, $CPUParticles2D11, $CPUParticles2D12,
	$CPUParticles2D13, $CPUParticles2D14, $CPUParticles2D15
]

@onready var healthbar: ProgressBar = $Healthbar
@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var target: CharacterBody2D = %Player
@onready var music_manager: Node = %MusicManager

# 1. Preload the skin shred scene
var skinshred_scene = preload("res://Sprites/skin_shred.tscn")

var sped = 500
const SPEED = 300.0
const JUMP_VELOCITY = -400.0
var can_move = 1
var negative_value = 1
var player = null
var is_chasing = false
var detection_range = 1100

# 2. Add the is_dead flag
var is_dead = false

func _ready():
	player = get_tree().root.find_child("Player", true, false)
	set_particles_emitting(false) # Start with particles off

func _physics_process(delta: float) -> void:
	# Stop processing physics and movement if the enemy is dead
	if is_dead:
		return
		
	if player:
		var distance = global_position.distance_to(player.global_position)
		
		if distance < detection_range and not is_chasing:
			is_chasing = true
			set_particles_emitting(true) # Turn on when chasing starts
			music_manager.start_chase(get_instance_id()) 

	if can_move == 1 and is_chasing == true:
		look_at(target.global_position)
		velocity = transform.x * sped * negative_value
		sprite.play("Fly")
		move_and_slide()
		if global_position.distance_to(target.global_position) < 1:
			negative_value = -1
			await get_tree().create_timer(0.15).timeout
			negative_value = 1
	
	if can_move == 1 and is_chasing == false:
		sprite.play("Idle")
		set_particles_emitting(false) # Ensure off if not chasing

func set_particles_emitting(emit: bool) -> void:
	for p in particles:
		if p: p.emitting = emit

func take_damage(damage) -> void:
	# Ignore damage if already dying
	if is_dead:
		return
		
	healthbar.value -= damage
	if healthbar.value <= 0:
		healthbar.value = 0
	
	negative_value = -1
	await get_tree().create_timer(0.15).timeout
	negative_value = 1
	
	# Trigger the death function if health is depleted
	if healthbar.value == 0 and not is_dead:
		die()

# 3. Centralized death function with the drop logic
func die() -> void:
	is_dead = true
	set_particles_emitting(false) # Turn off on death
	music_manager.stop_chase(get_instance_id())
	can_move = 0
	
	# Instantiate and drop the skin shred
	if skinshred_scene:
		var shred = skinshred_scene.instantiate()
		shred.global_position = global_position
		get_parent().call_deferred("add_child", shred)
	
	sprite.play("Die")
	await sprite.animation_finished
	queue_free()
