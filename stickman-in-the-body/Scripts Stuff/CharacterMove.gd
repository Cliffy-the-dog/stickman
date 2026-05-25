extends CharacterBody2D

@onready var bloodbar: ProgressBar = $Bloodbar
@onready var character: AnimatedSprite2D = $AnimatedSprite2D
@onready var healthbar: ProgressBar = $Healthbar
@onready var management: Node = %Management
@onready var slash: AnimatedSprite2D = $Slash
@onready var pause_menu: Control = $Camera2D2/PauseMenu
@onready var node_2d: Node2D = $Node2D
@onready var particles = [$Node2D/CPUParticles2D, $Node2D/CPUParticles2D4, $Node2D/CPUParticles2D6, $Node2D/CPUParticles2D5]
@onready var dust_particles: GPUParticles2D = $GPUParticles2D
@onready var slash_area_2: Area2D = %SlashArea2
@export var particle_node: GPUParticles2D # or GPUParticles2D
@export var push_force = 100.0
@onready var process_mat = particle_node.process_material as ParticleProcessMaterial

const JUMP_VELOCITY = -2200.0
var money = 0
var skins = 0
var abletoheal = 1; var damage = 20; var last_checkpoint = Vector2.ZERO; var attackers: Array[Node2D] = []
var last_floor_pos = Vector2.ZERO; var pause_Idleanimationforce = 0; var damage_taken_in_the_past_0point4seconds = 0
var damage_value = 10; var butchering_in_progress = 0; var bouncing_in_progress = 0; var being_touched = 0
var health_upgrades = 1; var SPEED = 1200.0; var healthpause = 0; var is_safe_ground = true

func _ready():
	slash_area_2.hide()
	pause_menu.load_game()
	healthbar.health = 100 + 20 * management.health_upgrades
	bloodbar.value = 0; butchering_in_progress = 0
	for p in particles: 
		p.show(); p.emitting = false

func flash_red():
	var t = create_tween()
	t.tween_property(self, "modulate", Color.DARK_RED, 0.2)
	t.tween_property(self, "modulate", Color.WHITE, 0.4)

func _physics_process(delta):
	
	if character.flip_h == true:
		dust_particles.position.x = 44
		process_mat.direction.x = 5
	if character.flip_h == false:
		dust_particles.position.x = -44
		process_mat.direction.x = -5
	
	var is_moving = abs(velocity.x) > 10
	var on_ground = is_on_floor()
	dust_particles.emitting = is_moving and on_ground
	
	node_2d.global_position = global_position
	if not is_on_floor(): velocity += get_gravity() * delta * 5
	if is_on_floor() and Input.is_action_just_pressed("Heal") and healthbar.value < 100:
		while bloodbar.value > 0 and healthbar.value < 100 and abletoheal:
			for p in particles: p.emitting = true
			SPEED = 0; bloodbar.value -= 0.5; healthbar.value += 0.5
			await get_tree().create_timer(0.02).timeout
			healthbar.health = healthbar.value
		SPEED = 1200
		for p in particles: p.emitting = false

	if Input.is_action_just_pressed("Slash"): Cleave()
	if Input.is_action_just_pressed("Jump") and is_on_floor() and not butchering_in_progress:
		velocity.y = JUMP_VELOCITY

	var d := Input.get_axis("Walk Left", "Walk Right")
	if d: 
		character.flip_h = d < 0
		%SlashArea2.position.x = 145 if d > 0 else -145
	
	if not pause_Idleanimationforce:
		if d and is_on_floor(): character.play("Walking")
		elif not is_on_floor() and character.animation != "Butcher": character.play("Falling" if d == 0 else "Leap")
		elif d == 0 and is_on_floor(): character.play("Idle")

	velocity.x = d * SPEED if d else move_toward(velocity.x, 0, SPEED)
	
	# 1. Execute movement
	move_and_slide()

	# 2. Update our knowledge of the ground state ONLY when a collision occurs
	if is_on_floor():
		for i in get_slide_collision_count():
			var collision = get_slide_collision(i)
			
			# Check if the collision normal is pointing UP (meaning it's a floor surface)
			if collision.get_normal().y < -0.5:
				var collider = collision.get_collider()
				if collider:
					# It's a temporary platform if the collider OR its parent has "passage"
					var is_temporary = collider.has_method("passage") or (collider.get_parent() and collider.get_parent().has_method("passage"))
					is_safe_ground = not is_temporary
					
		# 3. Always save position as long as our cached ground state says it's safe
		if is_safe_ground:
			last_floor_pos = global_position

func _on_slash_area_2_body_entered(body):
	if body.has_method("take_damage") and slash.animation == "Slash" and slash.is_playing(): 
		body.take_damage(damage); bloodbar.value += 1

func _on_killzone_body_entered(_b):
	if healthbar.health > 0 and not damage_taken_in_the_past_0point4seconds: apply_damage(10)
	if healthbar.health > 0: global_position = last_floor_pos
	else: respawn_logic()

func respawn_logic():
	if last_checkpoint != Vector2.ZERO: global_position = last_checkpoint
	else: get_tree().reload_current_scene()

func apply_damage(val):
	abletoheal = 0; damage_taken_in_the_past_0point4seconds = 1; flash_red()
	healthbar.health -= val; healthbar.damage_bar.value = healthbar.health
	await get_tree().create_timer(0.4).timeout
	damage_taken_in_the_past_0point4seconds = 0; abletoheal = 1

func die_sequence():
	healthpause = 1; SPEED = 0; pause_Idleanimationforce = 1; character.play("Die")
	await character.animation_finished
	pause_Idleanimationforce = 0; healthpause = 0; SPEED = 1200; respawn_logic(); healthbar.health = healthbar.max_value

func _on_fazed_hitbox_body_entered(b):
	if b.has_method("take_damage") and not attackers.has(b): attackers.append(b)

func _on_fazed_hitbox_body_exited(b):
	if attackers.has(b): attackers.erase(b)

func _on_fazed_hitbox_area_entered(a):
	if a.name == "Damage" and healthbar.health > 0 and not damage_taken_in_the_past_0point4seconds and not healthpause: apply_damage(damage_value)
	if a.has_method("AreaIdentifier"):
		SPEED = 0
		while healthbar.value < healthbar.max_value: 
			healthbar.value += 1; await get_tree().create_timer(0.02).timeout
		healthbar.health = healthbar.max_value; SPEED = 1200; last_checkpoint = global_position; pause_menu.save_game()
	if a.has_method("GITGUD"): 
		SPEED = 700; await get_tree().create_timer(0.2).timeout; SPEED = 1200

func Cleave():
	if not butchering_in_progress:
		if is_on_floor():
			slash_area_2.show()
			pause_Idleanimationforce = 1; butchering_in_progress = 1; %SlashArea2.monitoring = true
			character.play("Butcher"); if slash: slash.play("Slash")
			await character.animation_finished
			%SlashArea2.monitoring = false; pause_Idleanimationforce = 0
			slash_area_2.hide()
		character.play("Idle"); await get_tree().create_timer(0.25).timeout; butchering_in_progress = 0

func _process(_delta):
	if attackers.size() > 0 and healthbar.health > 0 and not damage_taken_in_the_past_0point4seconds and not healthpause: apply_damage(damage_value)
	if healthbar.health < 1 and not healthpause: die_sequence()
	healthbar.health = healthbar.value
