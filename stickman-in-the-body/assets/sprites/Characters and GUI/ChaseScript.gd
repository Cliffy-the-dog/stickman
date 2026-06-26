extends RigidBody2D

@onready var healthbar: ProgressBar = $Healthbar
@export var speed = 600.0
@export var detection_range = 1000.0
@onready var music_manager: Node = %MusicManager
@onready var animatedSprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var sprite = $AnimatedSprite2D 

var skinshred_scene = preload("res://assets/sprites/skin_shred.tscn") 

var multiplier = 1
var not_dying = 1
var movable = 1
var damage_value = 20
var player = null
var is_chasing = false
var dir = 1
var is_dead = false 

# --- NEW STUN VARIABLE ---
var is_stunned: bool = false

func _ready():
	player = get_tree().root.find_child("Player", true, false)
	lock_rotation = true
	contact_monitor = true
	max_contacts_reported = 4

# --- NEW KNOCKBACK FUNCTION ---
func apply_knockback(force: Vector2) -> void:
	linear_velocity = force
	is_stunned = true
	await get_tree().create_timer(0.5).timeout
	is_stunned = false

func _physics_process(_delta):
	if player and not is_dead:
		var distance = global_position.distance_to(player.global_position)
		
		if distance < detection_range and not is_chasing:
			is_chasing = true
			music_manager.start_chase(get_instance_id()) 
		
		# --- UPDATED MOVEMENT LOGIC ---
		if not is_stunned:
			if is_chasing:
				var direction = sign(player.global_position.x - global_position.x)
				linear_velocity.x = direction * speed * movable * multiplier
				sprite.flip_h = direction < 0
				if healthbar.value > 0:
					sprite.play("Run")

func take_damage(damage) -> void:
	if is_dead:
		return
		
	healthbar.value -= damage
	multiplier = -1
	await get_tree().create_timer(0.15).timeout
	multiplier = 1
	
	if healthbar.value <= 0:
		healthbar.value = 0
		die()

func die() -> void:
	is_dead = true
	music_manager.stop_chase(get_instance_id())
	movable = 0
	not_dying = 0
	
	if skinshred_scene:
		var shred = skinshred_scene.instantiate()
		shred.global_position = global_position
		get_parent().call_deferred("add_child", shred)
	
	animatedSprite.play("Die")
	await animatedSprite.animation_finished
	queue_free()
