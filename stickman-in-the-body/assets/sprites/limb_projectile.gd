extends AnimatedSprite2D

@export var speed: float = 600.0
@export var lifetime: float = 4.0
@export var homing_strength: float = 2.5 
var damage: int = 10

var direction: Vector2 = Vector2.ZERO
var target_ref: Node2D = null

func _ready():
	await get_tree().create_timer(lifetime).timeout
	queue_free()

func _physics_process(delta):
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
	_handle_collision(body)

func _on_area_2d_area_entered(area):
	var target = area if area.has_method("take_damage") else area.get_parent()
	_handle_collision(target)

func _handle_collision(target):
	if target and target.has_method("take_damage") and not target.has_method("pick_random_attack"):
		var is_pogoing_now = "is_pogoing" in target and target.is_pogoing and target.velocity.y > 0
		var is_bouncing_now = "bouncing_in_progress" in target and target.bouncing_in_progress > 0
		
		if is_pogoing_now or is_bouncing_now:
			queue_free()
		else:
			target.take_damage(damage)
			queue_free()
	elif target is TileMap or target is StaticBody2D:
		queue_free()

func take_damage(amount):
	queue_free()
