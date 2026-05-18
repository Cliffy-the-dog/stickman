extends CharacterBody2D

@onready var bloodbar: ProgressBar = $Bloodbar
@export var push_force = 100.0
@onready var animated_sprite_2d: AnimatedSprite2D = $AnimatedSprite2D
@onready var character: AnimatedSprite2D = $AnimatedSprite2D
@onready var healthbar: ProgressBar = $Healthbar
@onready var PhD: Area2D = $Damage
@onready var management: Node = %Management
@onready var slash: AnimatedSprite2D = $Slash
@onready var pause_menu: Control = $Camera2D2/PauseMenu
@onready var Particle1: CPUParticles2D = $Node2D/CPUParticles2D
@onready var Particle2: CPUParticles2D = $Node2D/CPUParticles2D4
@onready var Particle3: CPUParticles2D = $Node2D/CPUParticles2D6
@onready var Particle4: CPUParticles2D = $Node2D/CPUParticles2D5
@onready var node_2d: Node2D = $Node2D

@onready var killzone: Area2D = %Killzone

var abletoheal = 1
var damage = 20
var last_checkpoint: Vector2 = Vector2.ZERO 
var attackers: Array[Node2D] = []
var last_floor_pos: Vector2 = Vector2.ZERO
var pause_Idleanimationforce = 0
var damage_taken_in_the_past_0point4seconds = 0
var damage_value = 10
var butchering_in_progress = 0
var bouncing_in_progress = 0
var being_touched = 0
var health_upgrades = 1
var SPEED = 1200.0
const JUMP_VELOCITY = -2200.0
var healthpause = 0
var savegroundpos = 1

func _ready():
	pause_menu.load_game()
	healthbar.health = 100 + 20 * management.health_upgrades
	butchering_in_progress = 0
	bloodbar.value = 0
	# Ensure particles start off
	Particle1.emitting = false
	Particle2.emitting = false
	Particle3.emitting = false
	Particle4.emitting = false
	Particle1.show()
	Particle2.show()
	Particle3.show()
	Particle4.show()

func flash_red():
	var tween = create_tween()
	tween.tween_property(self, "modulate", Color.DARK_RED, 0.2)
	tween.tween_property(self, "modulate", Color.WHITE, 0.4)

func _physics_process(delta: float) -> void:
	node_2d.global_position = global_position
	if not is_on_floor():
		velocity += get_gravity() * delta * 5
		

	if is_on_floor() and Input.is_action_just_pressed("Heal"):
		# Ensure they are visible AND forced to start from scratch

		if not healthbar.value == 100:
			while bloodbar.value > 0:
				Particle1.emitting = true
				Particle2.emitting = true
				Particle3.emitting = true
				Particle4.emitting = true
				SPEED = 0
				bloodbar.value -= 0.25
				healthbar.value += 0.25
				if healthbar.value == 100:
					break
				if bloodbar.value == 0:
					break
				if abletoheal == 0:
					break
				await get_tree().create_timer(0.02).timeout
				healthbar.health += 0.25

				if healthbar.value == 100:
					break
				if bloodbar.value == 0:
					break
				if abletoheal == 0:
					break

					
			SPEED = 1200
			# Stop them when healing ends
			Particle1.emitting = false
			Particle2.emitting = false
			Particle3.emitting = false
			Particle4.emitting = false

	if Input.is_action_just_pressed("Slash"):
		Cleave()

	if Input.is_action_just_pressed("Jump") and is_on_floor():
		if butchering_in_progress == 0:
			velocity.y = JUMP_VELOCITY
			character.play("Jump")

	var direction := Input.get_axis("Walk Left", "Walk Right")
	if direction > 0:
		character.flip_h = false
		%SlashArea2.position.x = 145
	elif direction < 0:
		character.flip_h = true
		%SlashArea2.position.x = -145
	
	if pause_Idleanimationforce == 0:
		if direction != 0 and is_on_floor():
				character.play("Walking")
		if not is_on_floor() and character.animation != "Butcher":
			character.play("Falling" if direction == 0 else "Leap")
		elif direction == 0 and is_on_floor():
			character.play("Idle")

	velocity.x = direction * SPEED if direction else move_toward(velocity.x, 0, SPEED)
	move_and_slide()

func _on_slash_area_2_body_entered(body: Node2D) -> void:
	if body.has_method("take_damage") and slash.animation == "Slash" and slash.is_playing(): 
		body.take_damage(damage)
		bloodbar.value += 1

func _on_killzone_body_entered(_body: Node2D) -> void:
	if healthbar.health > 0 and damage_taken_in_the_past_0point4seconds == 0:
		apply_damage(10)
	
	if healthbar.health > 0:
		global_position = last_floor_pos
	else:
		respawn_logic()

func respawn_logic():
	if last_checkpoint != Vector2.ZERO:
		global_position = last_checkpoint
	else:
		get_tree().reload_current_scene()

func apply_damage(val):
	abletoheal = 0
	damage_taken_in_the_past_0point4seconds = 1
	flash_red()
	healthbar.health -= val
	healthbar.damage_bar.value = healthbar.health
	await get_tree().create_timer(0.4).timeout
	damage_taken_in_the_past_0point4seconds = 0
	abletoheal = 1

func die_sequence():
	healthpause = 1
	SPEED = 0
	pause_Idleanimationforce = 1
	character.play("Die")
	await character.animation_finished
	pause_Idleanimationforce = 0
	healthpause = 0
	SPEED = 1200
	respawn_logic()
	healthbar.health = healthbar.max_value

func _on_fazed_hitbox_body_entered(body: Node2D) -> void:
	if body.has_method("take_damage") and not attackers.has(body):
		attackers.append(body)
	if body.has_method("passage"):
		savegroundpos = 1

func _on_fazed_hitbox_body_exited(body: Node2D) -> void:
	if attackers.has(body):
		attackers.erase(body)
	if body.has_method("passage"):
		savegroundpos = 0

func _on_fazed_hitbox_area_entered(area: Area2D) -> void:
	if area.name == "Damage":
		if healthbar.health > 0 and damage_taken_in_the_past_0point4seconds == 0 and healthpause == 0:
			apply_damage(damage_value)
	
	if area.has_method("AreaIdentifier"):
		SPEED = 0
		while healthbar.value < healthbar.max_value:
			healthbar.value += 1
			await get_tree().create_timer(0.02).timeout
		healthbar.health = healthbar.max_value
		SPEED = 1200
		last_checkpoint = global_position
		pause_menu.save_game()
	
	if area.has_method("GITGUD"):
		SPEED = 700
		await get_tree().create_timer(0.2).timeout
		SPEED = 1200

func Cleave():
	if butchering_in_progress == 0:
		if is_on_floor():
			pause_Idleanimationforce = 1
			butchering_in_progress = 1
			%SlashArea2.monitoring = true
			character.play("Butcher")
			if slash: slash.play("Slash")
			await character.animation_finished
			%SlashArea2.monitoring = false
			pause_Idleanimationforce = 0
		character.play("Idle")
		await get_tree().create_timer(0.25).timeout
		butchering_in_progress = 0

func _process(_delta: float) -> void:
	if attackers.size() > 0:
		if healthbar.health > 0 and damage_taken_in_the_past_0point4seconds == 0 and healthpause == 0:
			apply_damage(damage_value)

	if healthbar.health < 1 and healthpause == 0:
		die_sequence()
	
	healthbar.health = healthbar.value
	if is_on_floor() and savegroundpos == 1:
		last_floor_pos = global_position
