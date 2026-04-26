extends CharacterBody2D



@onready var healthbar: ProgressBar = $Healthbar
@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var target: CharacterBody2D = %Player
@onready var music_manager: Node = %MusicManager

var sped = 500
const SPEED = 300.0
const JUMP_VELOCITY = -400.0
var can_move = 1
var negative_value = 1
var player = null
var is_chasing = false
var detection_range = 1100

func _ready():
	player = get_tree().root.find_child("Player", true, false)

func _physics_process(delta: float) -> void:
	if player:
		var distance = global_position.distance_to(player.global_position)
		
		# Triggers music once when entering range
		if distance < detection_range and not is_chasing:
			is_chasing = true
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

func take_damage(damage_amount) -> void:
	healthbar.value -= 20
	if healthbar.value < 0:
		healthbar.value = 0
	
	negative_value = -1
	await get_tree().create_timer(0.15).timeout
	negative_value = 1
	
	var direction = 0
	if sprite.flip_h == true:
		direction = 1
	elif sprite.flip_h == false:
		direction = -1
		
	if healthbar.value == 0:
		# Tells Music Manager this specific enemy is no longer chasing
		music_manager.stop_chase(get_instance_id())
		
		can_move = 0
		sprite.play("Die")
		await sprite.animation_finished
		queue_free()
