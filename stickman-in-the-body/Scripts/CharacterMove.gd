extends CharacterBody2D

@onready var grounder_hitbox: CollisionShape2D = $"Grounder Hitbox"
@onready var inventory: Node2D = $Inventory
@export var projectile_scene: PackedScene 
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
@export var particle_node: GPUParticles2D 
@export var push_force = 100.0
@onready var moneyLabel: Label = $Camera2D2/Money
@onready var process_mat = particle_node.process_material as ParticleProcessMaterial
const CHAIN_TOSS = preload("uid://cvoqnry8ssqo6")

var health
var hasbloodbind = false
var bootson = true
const JUMP_VELOCITY = -2200.0
var money = 0.0
var skins = 0
var abletoheal = 1; var damage = 20; var last_checkpoint = Vector2.ZERO; var attackers: Array[Node2D] = []
var last_floor_pos = Vector2.ZERO; var pause_Idleanimationforce = 0; var damage_taken_in_the_past_0point4seconds = 0
var damage_value = 10; var butchering_in_progress = 0; var bouncing_in_progress = 0; var being_touched = 0
var health_upgrades = 1; var SPEED = 1200.0; var healthpause = 0; var is_safe_ground = true
var max_health = 100 + 20 * health_upgrades
var bloodbind_in_progress = 0 
var goo_spawn_cooldown = 0.0

var is_crouching = false
var crouch_cooldown = 0.0

# Dash variables
var is_dashing = false
var dash_timer = 0.0
var dash_direction = 1
var dash_cooldown_timer = 0.0

# Store the default Y position of the hitbox so we can safely return to it when standing
@onready var default_hitbox_pos_y = grounder_hitbox.position.y

func _ready():
	slash_area_2.hide()
	pause_menu.load_game()
	healthbar.max_value = 100 + 20 * management.health_upgrades
	healthbar.value = healthbar.max_value
	healthbar.health = healthbar.max_value
	bloodbar.value = 100; butchering_in_progress = 0
	for p in particles: 
		p.show(); p.emitting = false

func flash_red():
	var t = create_tween()
	t.tween_property(self, "modulate", Color.DARK_RED, 0.2)
	t.tween_property(self, "modulate", Color.WHITE, 0.4)

func _physics_process(delta):
	# Tick down the cooldown and dash timers
	if crouch_cooldown > 0.0:
		crouch_cooldown -= delta
		
	if dash_cooldown_timer > 0.0:
		dash_cooldown_timer -= delta
		
	if is_dashing:
		dash_timer -= delta
		if dash_timer <= 0.0:
			is_dashing = false

	moneyLabel.text = "$" + str(money)
	if character.flip_h == true:
		dust_particles.position.x = 44
		process_mat.direction.x = 5
	if character.flip_h == false:
		dust_particles.position.x = -44
		process_mat.direction.x = -5
	
	dust_particles.emitting = false
	
	node_2d.global_position = global_position
	
	# --- PREVENT GRAVITY WHILE BLOODINDING OR DASHING ---
	if not is_on_floor() and not bloodbind_in_progress and not is_dashing: 
		velocity += get_gravity() * delta * 5
	elif bloodbind_in_progress or is_dashing:
		velocity.y = 0 # Lock Y axis to prevent falling during dash/cast
	
	if is_on_floor() and Input.is_action_just_pressed("Heal") and healthbar.value < healthbar.max_value:
		while bloodbar.value > 0 and healthbar.value < healthbar.max_value and abletoheal:
			for p in particles: p.emitting = true
			SPEED = 0
			bloodbar.value -= 1.0 
			healthbar.value += 1.0 
			await get_tree().create_timer(0.02).timeout
			healthbar.health = healthbar.value
		SPEED = 1200
		for p in particles: p.emitting = false

	# --- BLOCKED NORMAL ACTIONS IF CROUCHING ---
	if Input.is_action_just_pressed("Slash") and not is_crouching: Cleave()
	if Input.is_action_just_pressed("Jump") and is_on_floor() and not butchering_in_progress and not bloodbind_in_progress and not is_crouching:
		velocity.y = JUMP_VELOCITY

	# --- DASH FROM CROUCH ---
	if is_crouching and not is_dashing and dash_cooldown_timer <= 0.0 and (Input.is_action_just_pressed("Jump") or Input.is_action_just_pressed("Slash")):
		is_dashing = true
		dash_timer = 0.2 # 0.2 seconds * 2500 speed = 500 pixels
		dash_direction = -1 if character.flip_h else 1
		dash_cooldown_timer = 1.0 # 1-second cooldown before you can dash again

	# --- PREVENT WALKING INPUTS WHILE BLOODINDING/DASHING ---
	var d := 0.0
	if not bloodbind_in_progress and not is_dashing:
		d = Input.get_axis("Walk Left", "Walk Right")
	
	if d: 
		character.flip_h = d < 0
		%SlashArea2.position.x = 145 if d > 0 else -145
		
	# --- CROUCHING TOGGLE LOGIC ---
	if Input.is_action_just_pressed("Crouch") and is_on_floor() and not bloodbind_in_progress and not butchering_in_progress:
		if crouch_cooldown <= 0.0:
			is_crouching = not is_crouching 
			crouch_cooldown = 0.3 # Lock state changes for 0.3 seconds
		
	# Auto-uncrouch if the player falls off a ledge (ignored if mid-dash)
	if not is_on_floor() and crouch_cooldown <= 0.0 and not is_dashing:
		is_crouching = false
	
	# --- HITBOX SCALING & POSITION FIX ---
	if is_crouching:
		grounder_hitbox.scale.y = 0.75
		grounder_hitbox.position.y = 40.0 
	else:
		grounder_hitbox.scale.y = 1.5
		grounder_hitbox.position.y = default_hitbox_pos_y
	
	# --- ANIMATION PRIORITY ---
	if not pause_Idleanimationforce:
		if is_dashing:
			character.play("CrawlMove") 
		elif is_crouching: 
			character.play("CrawlMove" if d != 0 else "CrouchIdle")
		elif d and is_on_floor(): 
			character.play("Walking")
		elif not is_on_floor() and character.animation != "Butcher": 
			character.play("Falling" if d == 0 else "Leap")
		elif d == 0 and is_on_floor(): 
			character.play("Idle")

	# --- FORCE VELOCITY TO DASH OR CAST ---
	if bloodbind_in_progress:
		velocity = Vector2.ZERO
	elif is_dashing:
		velocity.x = dash_direction * 2500.0 
	else:
		velocity.x = d * SPEED if d else move_toward(velocity.x, 0, SPEED)
	
	move_and_slide()
	
	if is_on_floor():
		for i in get_slide_collision_count():
			var collision = get_slide_collision(i)
			if collision.get_normal().y < -0.5:
				var collider = collision.get_collider()
				if collider:
					var is_temporary = collider.has_method("passage") or (collider.get_parent() and collider.get_parent().has_method("passage"))
					is_safe_ground = not is_temporary
					
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
	health = healthbar.value
	if Input.is_action_just_pressed("BloodSpell") and not bloodbind_in_progress: 
		if bloodbar.value >= 10.0: 
			bloodbar.value -= 10.0 
			shoot_projectile()     

func shoot_projectile() -> void:
	if projectile_scene == null:
		push_error("Projectile scene is not assigned in the inspector!")
		return
		
	bloodbind_in_progress = 1
	pause_Idleanimationforce = 1
	SPEED = 0
	character.play("BloodbindLaunch")
		
	var proj = projectile_scene.instantiate()
	
	proj.is_flipped = character.flip_h
	proj.global_position = global_position
	proj.player_ref = self
	
	if character.flip_h == true:
		proj.direction = Vector2.LEFT
	else:
		proj.direction = Vector2.RIGHT
		
	get_tree().current_scene.add_child(proj)

func finish_bloodbind() -> void:
	bloodbind_in_progress = 0
	pause_Idleanimationforce = 0
	SPEED = 1200
	character.play("Idle")

func trigger_endlag_punishment() -> void:
	$AudioStreamPlayer2D.play()
	character.position.y = -100
	character.play("Endlag")

	await character.animation_finished
	character.position.y = 0
	$AudioStreamPlayer2D.playing = false
	finish_bloodbind()
