extends CharacterBody2D
@onready var l: RayCast2D = $L
@onready var r: RayCast2D = $R
@onready var player: CharacterBody2D = %Player
@onready var healthbar: ProgressBar = $Healthbar
@onready var animated_sprite_2d: AnimatedSprite2D = $AnimatedSprite2D

var direction = 1
const SPEED = 30000.0
const JUMP_VELOCITY = -400.0
var goo_scene = preload("res://assets/sprites/Goo.tscn")
var goo_cooldown = 0.0

# --- NEW STUN VARIABLE ---
var is_stunned: bool = false

# --- NEW KNOCKBACK FUNCTION ---
func apply_knockback(force: Vector2) -> void:
	velocity = force
	is_stunned = true
	await get_tree().create_timer(0.5).timeout
	is_stunned = false

func _physics_process(delta: float) -> void:
	# --- UPDATED MOVEMENT LOGIC ---
	if not is_stunned:
		if l.is_colliding():
			direction = 1
			animated_sprite_2d.flip_h = false
		if r.is_colliding():
			direction = -1
			animated_sprite_2d.flip_h = true
		
		velocity.x = direction * SPEED * delta
	else:
		if not is_on_floor():
			velocity += get_gravity() * delta
		velocity.x = move_toward(velocity.x, 0, 800 * delta)
		
	move_and_slide()
	
	if goo_cooldown > 0:
		goo_cooldown -= delta

	if velocity.length() > 0 and goo_cooldown <= 0 and not is_stunned:
		var goo_instance = goo_scene.instantiate()
		var floor_offset = Vector2(0, 50) 
		goo_instance.global_position = global_position + floor_offset
		get_parent().add_child(goo_instance)
		goo_cooldown = 0.2

func take_damage(damage):
	healthbar.health -= damage
	healthbar.value -= damage
	if healthbar.value < 1:
		queue_free()
