extends CharacterBody2D

@export var push_force = 100.0
@onready var animated_sprite_2d: AnimatedSprite2D = $AnimatedSprite2D
@onready var character: AnimatedSprite2D = $AnimatedSprite2D
@onready var healthbar: ProgressBar = $Healthbar
@onready var PhD: Area2D = $Damage
@onready var management: Node = %Management
@onready var slash: AnimatedSprite2D = $Slash
@onready var killzone: Area2D = %Killzone


var damage = 400
var last_checkpoint
var attackers: Array[Node2D] = []
var last_floor_pos: Vector2 = Vector2.ZERO
var pause_Idleanimationforce = 0
var damage_taken_in_the_past_0point4seconds = 0
var damage_value = 10
var butchering_in_progress = 0
var bouncing_in_progress = 0
var being_touched = 0
var health_upgrades = 1
var SPEED = 0.0
const JUMP_VELOCITY = -2200.0
var healthpause = 0

func _ready():
	healthbar.health = 100 + 20 * management.health_upgrades
	butchering_in_progress = 0

func flash_red():
	var tween = create_tween()
	tween.tween_property(self, "modulate", Color.DARK_RED, 0.2)
	tween.tween_property(self, "modulate", Color.WHITE, 0.4)

func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity += get_gravity() * delta * 5

	if Input.is_action_just_pressed("Slash"):
		Cleave()

	if Input.is_action_just_pressed("Jump") and is_on_floor():
		if butchering_in_progress == 0:
			velocity.y = JUMP_VELOCITY
			bouncing_in_progress = 1
			character.play("Jump")
			bouncing_in_progress = 0

	var direction := Input.get_axis("Walk Left", "Walk Right")
	if direction > 0:
		character.flip_h = false
		%SlashArea2.position.x = 145
	elif direction < 0:
		character.flip_h = true
		%SlashArea2.position.x = -145
	if pause_Idleanimationforce == 0:
		if is_on_floor():
			last_floor_pos = global_position
			if direction != 0 and pause_Idleanimationforce == 0 and is_on_floor():
				character.play("Walking")
				last_floor_pos = global_position
		if not is_on_floor() and character.animation != "Butcher":
			if direction == 0:
				character.play("Falling")
			if direction != 0:
				character.play("Leap")
		elif direction == 0 and is_on_floor():
			character.play("Idle")
		



	if direction:
		velocity.x = direction * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)
		if pause_Idleanimationforce == 0:
			character.play("Idle")

	move_and_slide()
	


func _on_slash_area_2_body_entered(body: Node2D) -> void:
	if body.has_method("take_damage") and slash.animation == "Slash" and slash.is_playing(): 
		body.take_damage(damage)


func _on_killzone_body_entered(body: Node2D) -> void:
	if healthbar.health > 0 and damage_taken_in_the_past_0point4seconds == 0:
		if healthbar.health - 10 > -1:
			damage_taken_in_the_past_0point4seconds = 1
			flash_red()
			for a in range(10):
				healthbar.health = healthbar.health - 1
				await get_tree().create_timer(0.02).timeout
			damage_taken_in_the_past_0point4seconds = 0
			healthbar.damage_bar.value = healthbar.health
	if healthbar.health != 0:
		global_position = last_floor_pos
	if healthbar.health == 0:
		global_position = last_checkpoint


func _on_fazed_hitbox_body_entered(body: Node2D) -> void:
	if body.has_method("take_damage") and not attackers.has(body):
		attackers.append(body)

func _on_fazed_hitbox_body_exited(body: Node2D) -> void:
	if body.has_method("take_damage"):
		if attackers.has(body):
			attackers.erase(body)

func _process(delta: float) -> void:
	if attackers.size() > 0:
		if healthbar.health > 0 and damage_taken_in_the_past_0point4seconds == 0 and healthpause == 0:
			if healthbar.health - 10 > -1:
				damage_taken_in_the_past_0point4seconds = 1
				flash_red()
				for a in range(damage_value):
					healthbar.health = healthbar.health - 1
					await get_tree().create_timer(0.07).timeout
				damage_taken_in_the_past_0point4seconds = 0
				healthbar.damage_bar.value = healthbar.health
	if healthbar.value < 1:
		healthpause = 1
		SPEED = 0
		pause_Idleanimationforce = 1
		character.play("Die")
		await character.animation_finished
		pause_Idleanimationforce = 0
		healthpause = 0
		SPEED = 1200
		global_position = last_checkpoint
		Cleave()
	healthbar.health = healthbar.value


func _on_fazed_hitbox_area_entered(area: Area2D) -> void:
	print("Touching ",area)
	if area.name == "Damage":
		if healthbar.health > 0 and damage_taken_in_the_past_0point4seconds == 0 and healthpause == 0:
			if healthbar.health - 10 > -1:
				damage_taken_in_the_past_0point4seconds = 1
				flash_red()
				for a in range(damage_value):
					healthbar.health = healthbar.health - 1
					await get_tree().create_timer(0.07).timeout
				damage_taken_in_the_past_0point4seconds = 0
				healthbar.damage_bar.value = healthbar.health
	if healthbar.value < 1:
		healthpause = 1
		SPEED = 0
		pause_Idleanimationforce = 1
		character.play("Die")
		await character.animation_finished
		pause_Idleanimationforce = 0
		healthpause = 0
		SPEED = 1200
		global_position = last_checkpoint
		Cleave()
	healthbar.health = healthbar.value
	if area.has_method("AreaIdentifier"):
		print("Area is Checkpoint")
		SPEED = 0
		while healthbar.value != healthbar.max_value:
			healthbar.value = healthbar.value + 1
			healthbar.health = healthbar.health + 1
			await get_tree().create_timer(0.02).timeout

		healthbar.health = healthbar.max_value
		healthbar.value = healthbar.max_value
		SPEED = 1200
		last_checkpoint = global_position
		character.play("Idle")
func Cleave():
	if butchering_in_progress == 0:
		if is_on_floor():
			pause_Idleanimationforce = 1
			butchering_in_progress = 1
			%SlashArea2.monitoring = true
			character.play("Butcher")
			await character.animation_finished
			%SlashArea2.monitoring = false
			pause_Idleanimationforce = 0
		character.play("Idle")
		await get_tree().create_timer(0.25).timeout
		butchering_in_progress = 0
		await get_tree().create_timer(0.25).timeout
