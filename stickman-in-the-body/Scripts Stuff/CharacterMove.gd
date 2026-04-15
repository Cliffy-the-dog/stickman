extends CharacterBody2D

@onready var animated_sprite_2d: AnimatedSprite2D = $AnimatedSprite2D
@onready var character: AnimatedSprite2D = $AnimatedSprite2D
@onready var healthbar: ProgressBar = $Healthbar
@onready var management: Node = %Management

# Attack variables
@export var attack_damage = 20
@export var attack_cooldown = 0.5

var can_attack = true
var attack_timer = 0.0
var damage_taken_in_the_past_0point4seconds = 0
var damage_value = 10
var butchering_in_progress = 0
var bouncing_in_progress = 0

@onready var slash_area = $SlashArea

const SPEED = 1200.0
const JUMP_VELOCITY = -2200.0

func _ready():
	healthbar.health = 100 + 20 * management.health_upgrades
	butchering_in_progress = 0
	if slash_area:
		print("SlashArea found, monitoring = ", slash_area.monitoring)
		# Force connect signal in code as backup
		if not slash_area.body_entered.is_connected(_on_slash_area_body_entered):
			slash_area.body_entered.connect(_on_slash_area_body_entered)
			print("Signal connected via code")
	if slash_area and not slash_area.body_entered.is_connected(_on_slash_area_body_entered):
		slash_area.body_entered.connect(_on_slash_area_body_entered)
		print("Signal connected manually")
	
	# Make sure slash_area starts disabled
	if slash_area:
		slash_area.monitoring = false

func _physics_process(delta: float) -> void:
	# Handle attack cooldown
	if not can_attack:
		attack_timer -= delta
		if attack_timer <= 0:
			can_attack = true
	
	# Add the gravity
	if not is_on_floor():
		velocity += get_gravity() * delta * 5
	
	# Handle Slash attack
	if Input.is_action_just_pressed("Slash") and can_attack and butchering_in_progress == 0 and is_on_floor():
		perform_attack()
	
	# Handle Jump
	if Input.is_action_just_pressed("Jump") and is_on_floor():
		velocity.y = JUMP_VELOCITY
		bouncing_in_progress = 1
		character.play("Jump")
		await is_on_floor()
		character.play("Idle")
		bouncing_in_progress = 0
	
	# Movement
	var direction := Input.get_axis("Walk Left", "Walk Right")
	if direction > 0:
		character.flip_h = false
	elif direction < 0:
		character.flip_h = true
	
	# Animation handling
	if direction == 0 and butchering_in_progress == 0 and bouncing_in_progress == 0 and can_attack:
		character.play("Idle")
	elif is_on_floor() and butchering_in_progress == 0 and bouncing_in_progress == 0:
		if direction != 0:
			character.play("Walking")
	elif not is_on_floor():
		character.play("Falling")
	
	# Apply movement
	if direction:
		velocity.x = direction * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)
	
	move_and_slide()
	
	# Enemy collision damage
	for i in get_slide_collision_count():
		var collision = get_slide_collision(i)
		if collision:
			var collider = collision.get_collider()
			if collider is RigidBody2D and collider.is_in_group("enemy"):
				if healthbar.health > 0 and damage_taken_in_the_past_0point4seconds == 0:
					damage_taken_in_the_past_0point4seconds = 1
					for a in range(damage_value):
						healthbar.health = healthbar.health - 1
						await get_tree().create_timer(0.02).timeout
					damage_taken_in_the_past_0point4seconds = 0
					healthbar.damage_bar.value = healthbar.health

func perform_attack():
	print("Attack performed!")  # Confirm attack triggers
	can_attack = false
	attack_timer = attack_cooldown
	butchering_in_progress = 1
	
	character.play("Butcher")
	
	if slash_area:
		print("Enabling slash_area monitoring")  # Debug
		slash_area.monitoring = true
		await get_tree().create_timer(0.15).timeout
		print("Disabling slash_area monitoring")  # Debug
		slash_area.monitoring = false
	
	await character.animation_finished
	character.play("Idle")
	butchering_in_progress = 0

func _on_slash_area_body_entered(body):
	print("Slash hit: ", body.name)  # Debug line
	if body.is_in_group("enemy"):
		print("Hit enemy with slash!")  # Debug line
		body.Enemy_take_damage(attack_damage)
