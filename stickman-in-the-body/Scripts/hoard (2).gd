extends CharacterBody2D

@onready var particles: Array = [
	$CPUParticles2D, $CPUParticles2D2, $CPUParticles2D3, $CPUParticles2D4,
	$CPUParticles2D5, $CPUParticles2D6, $CPUParticles2D7, $CPUParticles2D8,
	$CPUParticles2D9, $CPUParticles2D10, $CPUParticles2D11, $CPUParticles2D12,
	$CPUParticles2D13, $CPUParticles2D14, $CPUParticles2D15
]

@onready var healthbar: ProgressBar = $Healthbar
@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D

# Removed % unique node syntax to prevent null instances on runtime spawn
var target: CharacterBody2D = null
var music_manager: Node = null

var skinshred_scene = preload("res://assets/sprites/skin_shred.tscn")

var sped = 500
const SPEED = 300.0
const JUMP_VELOCITY = -400.0
var can_move = 1
var negative_value = 1
var player = null
var is_chasing = false
var detection_range = 1100
var is_dead = false

var is_stunned: bool = false

func _ready():
	# Dynamically locate nodes in the scene root
	player = get_tree().root.find_child("Player", true, false) as CharacterBody2D
	target = player
	music_manager = get_tree().root.find_child("MusicManager", true, false)
	
	set_particles_emitting(false) 

func apply_knockback(force: Vector2) -> void:
	velocity = force
	is_stunned = true
	await get_tree().create_timer(0.5).timeout
	is_stunned = false

func _physics_process(delta: float) -> void:
	if is_dead:
		return
		
	if player:
		var distance = global_position.distance_to(player.global_position)
		
		if distance < detection_range and not is_chasing:
			is_chasing = true
			set_particles_emitting(true) 
			if music_manager and music_manager.has_method("start_chase"):
				music_manager.start_chase(get_instance_id()) 

	# --- MOVEMENT LOGIC ---
	if not is_stunned:
		if can_move == 1 and is_chasing and target:
			look_at(target.global_position)
			velocity = transform.x * sped * negative_value
			sprite.play("Fly")
			move_and_slide()
			if global_position.distance_to(target.global_position) < 1:
				negative_value = -1
				await get_tree().create_timer(0.15).timeout
				negative_value = 1
		
		if can_move == 1 and not is_chasing:
			sprite.play("Idle")
			set_particles_emitting(false) 
	else:
		velocity += get_gravity() * delta
		velocity.x = move_toward(velocity.x, 0, 800 * delta)
		move_and_slide()

func set_particles_emitting(emit: bool) -> void:
	for p in particles:
		if p: p.emitting = emit

func take_damage(damage) -> void:
	if is_dead:
		return
		
	healthbar.value -= damage
	if healthbar.value <= 0:
		healthbar.value = 0
	
	negative_value = -1
	await get_tree().create_timer(0.15).timeout
	negative_value = 1
	
	if healthbar.value == 0 and not is_dead:
		die()

func die() -> void:
	is_dead = true
	set_particles_emitting(false)
	
	if music_manager and music_manager.has_method("stop_chase"):
		music_manager.stop_chase(get_instance_id())
		
	can_move = 0
	
	if skinshred_scene:
		var shred = skinshred_scene.instantiate()
		shred.global_position = global_position
		get_parent().call_deferred("add_child", shred)
	
	sprite.play("Die")
	await sprite.animation_finished
	queue_free()
