extends CharacterBody2D

@export var speed: float = 600.0
@export var lifetime: float = 6.0
var damage: int = 20
var direction: Vector2 = Vector2.ZERO

func _ready():
	await get_tree().create_timer(lifetime).timeout
	queue_free()

func _physics_process(_delta):
	velocity = direction * speed
	move_and_slide()

func launch(aim_dir: Vector2, _target: Node2D):
	direction = aim_dir.normalized()
	
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
