extends AnimatedSprite2D

@export var speed: float = 600.0
@export var lifetime: float = 4.0
@export var homing_strength: float = 2.5 # How sharply it can turn
var damage: int = 10

var direction: Vector2 = Vector2.ZERO
var target_ref: Node2D = null

func _ready():
	# Start the self-destruct timer
	await get_tree().create_timer(lifetime).timeout
	queue_free()

func _physics_process(delta):
	# True Homing: Steer towards the target if it exists
	if is_instance_valid(target_ref):
		var desired_dir = global_position.direction_to(target_ref.global_position)
		direction = direction.slerp(desired_dir, homing_strength * delta).normalized()
		rotation = direction.angle()
		
	position += direction * speed * delta

func set_direction(aim_dir: Vector2, target: Node2D):
	direction = aim_dir.normalized()
	rotation = direction.angle()
	target_ref = target

func _on_area_2d_body_entered(body):
	# Bulletproof check: Does it have health, and is it NOT the boss?
	if body.has_method("take_damage") and not "Boss" in body.name:
		if "is_pogoing" in body and body.is_pogoing and body.velocity.y > 0:
			# Player is pogoing! They bounce, we die.
			queue_free()
		else:
			# Normal hit!
			body.take_damage(damage)
			queue_free()
	elif body is TileMap or body is StaticBody2D:
		queue_free()

func take_damage(_amount):
	queue_free()
