extends CharacterBody2D

@onready var character: AnimatedSprite2D = $Character
@export var head: PackedScene
@onready var zealpoint: Area2D = $"../Area2D"
@onready var healthbar: ProgressBar = $Healthbar
@onready var Target: CharacterBody2D = %Player

# Has 4 Moves:
# 1. Roll: Rolls at you
# 2. Jump: Jumps up
# 3. Hurl: Throws 3 heads at you.
# 4. Zeal: Starts spewing heads at you, 3 at a time

var zeal_in_progress = 0
var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")
var awakened = 0
var distance
const JUMP_VELOCITY = -400.0
var gravity_on = 1
var speed = 1000


## Handles awakening, idle/combat states, and zeal attack movement.
func _physics_process(delta: float) -> void:
	if not is_on_floor() and gravity_on == 1:
		velocity.y += gravity * delta
	distance = global_position.distance_to(Target.global_position)
	if not distance < 1200 and awakened == 0:
		character.play("Unawakened")
	if distance < 1200 and awakened == 0:
		character.play("Awakening")
		await character.animation_finished
		awakened = 1
	if awakened == 1 and zeal_in_progress == 0:
		battle()
	if zeal_in_progress == 0 and awakened == 1:
		character.play("Idle")
	if zeal_in_progress == 1:
		character.play("Zeal")
		gravity_on = 0
		look_at(zealpoint.global_position)
		velocity.x = 1200
		move_and_slide()
		await zealpoint.global_position == global_position
		velocity.x = 0
		while character.is_playing() == true:
			await get_tree().create_timer(0.2).timeout
			zealHurl()
			await get_tree().create_timer(0.2).timeout
			zealHurl()
			await get_tree().create_timer(0.2).timeout
			zealHurl()
			await get_tree().create_timer(1).timeout


## Dashes horizontally toward the player for a short burst.
func dash():
	var direction = Target.global_position.x - global_position.x

	if direction < 0:
		velocity.x = -2500
	elif direction > 0:
		velocity.x = 2500

	move_and_slide()
	await get_tree().create_timer(0.3).timeout
	velocity.x = 0
	velocity.y = 0


## Jumps with random horizontal velocity until landing.
func jump():
	velocity.y = JUMP_VELOCITY
	velocity.x = randi_range(-100, 100)
	await is_on_floor()
	velocity.x = 0
	velocity.y = 0


## Throws a single head projectile at the player.
func Battle_hurl():
	var b = head.instantiate()
	look_at(Target.global_position)
	get_tree().root.add_child(b)
	await get_tree().create_timer(0.3).timeout


## Randomly chooses dash, jump, or hurl as the next attack.
func battle():
	var RNG = randi_range(1, 3)
	if RNG == 1:
		dash()
	if RNG == 2:
		jump()
	if RNG == 3:
		Battle_hurl()


## Spawns a head projectile during the zeal attack phase.
func zealHurl():
	var b = head.instantiate()
	look_at(Target.global_position)
	position += speed
	get_tree().root.add_child(b)


## Applies damage and removes the boss when health reaches zero.
func take_damage(damage_amount) -> void:
	healthbar.value -= 20
	if healthbar.value == 0:
		queue_free()
