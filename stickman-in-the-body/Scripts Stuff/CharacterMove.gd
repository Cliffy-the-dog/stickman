extends CharacterBody2D

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

var hasbloodbind = false
var bootson = true
const JUMP_VELOCITY = -2200.0
var money = 0.0
var skins = 0
var abletoheal = 1; var damage = 20; var last_checkpoint = Vector2.ZERO; var attackers: Array[Node2D] = []
var last_floor_pos = Vector2.ZERO; var pause_Idleanimationforce = 0; var damage_taken_in_the_past_0point4seconds = 0
var damage_value = 10; var butchering_in_progress = 0; var bouncing_in_progress = 0; var being_touched = 0
var health_upgrades = 1; var SPEED = 1200.0; var healthpause = 0; var is_safe_ground = true

var bloodbind_in_progress = 0 
var goo_spawn_cooldown = 0.0

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
	moneyLabel.text = "$" + str(money)
	if character.flip_h == true:
		dust_particles.position.x = 44
		process_mat.direction.x = 5
	if character.flip_h == false:
		dust_particles.position.x = -44
		process_mat.direction.x = -5
	
	dust_particles.emitting = false
	
	node_2d.global_position = global_position
	
	# --- PREVENT GRAVITY WHILE BLOODINDING ---
	if not is_on_floor() and not bloodbind_in_progress: 
		velocity += get_gravity() * delta * 5
	elif bloodbind_in_progress:
		velocity = Vector2.ZERO
	
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

	if Input.is_action_just_pressed("Slash"): Cleave()
	
	if Input.is_action_just_pressed("Jump") and is_on_floor() and not butchering_in_progress and not bloodbind_in_progress:
		velocity.y = JUMP_VELOCITY

	# --- PREVENT WALKING INPUTS WHILE BLOODINDING ---
	var d := 0.0
	if not bloodbind_in_progress:
		d = Input.get_axis("Walk Left", "Walk Right")
	
	if d: 
		character.flip_h = d < 0
		%SlashArea2.position.x = 145 if d > 0 else -145
	
	if not pause_Idleanimationforce:
		if d and is_on_floor(): character.play("Walking")
		elif not is_on_floor() and character.animation != "Butcher": character.play("Falling" if d == 0 else "Leap")
		elif d == 0 and is_on_floor(): character.play("Idle")

	# --- FORCE VELOCITY TO ZERO IF CASTING ---
	if bloodbind_in_progress:
		velocity = Vector2.ZERO
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
