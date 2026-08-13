extends CharacterBody2D

@export var speed: float = 600.0
@export var lifetime: float = 6.0
var damage: int = 20
var direction: Vector2 = Vector2.ZERO

func _ready():
	# Start the self-destruct timer
	await get_tree().create_timer(lifetime).timeout
	queue_free()

func _physics_process(_delta):
	velocity = direction * speed
	move_and_slide()

func launch(aim_dir: Vector2, _target: Node2D):
	direction = aim_dir.normalized()
	
func _on_area_2d_body_entered(body):
	# Bulletproof check: Does it have health, and is it NOT the boss?
	if body.has_method("take_damage") and not "Boss" in body.name:
		if "is_pogoing" in body and body.is_pogoing and body.velocity.y > 0:
			queue_free()
		else:
			body.take_damage(damage)
			queue_free()
	elif body is TileMap or body is StaticBody2D:
		queue_free()

func take_damage(_amount):
	queue_free()
