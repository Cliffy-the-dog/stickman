extends CharacterBody2D
@onready var healthbar: ProgressBar = $Healthbar
@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var target: CharacterBody2D = %Player

var sped = 500
const SPEED = 300.0
const JUMP_VELOCITY = -400.0
var can_move = 1
var negative_value = 1

func _physics_process(delta: float) -> void:
	if can_move == 1:
		look_at(target.global_position)
		velocity = transform.x * sped * negative_value
		sprite.play("Fly")
		move_and_slide()
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
	if sprite.flip_h == false:
		direction = -1
	else:
		direction = 0
	if healthbar.value == 0:
		can_move = 0
		$CollisionShape2D.queue_free()
		sprite.play("Die")
		await sprite.animation_finished
		queue_free()
