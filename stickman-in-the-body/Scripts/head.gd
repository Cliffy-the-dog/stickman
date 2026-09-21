extends CharacterBody2D

@export var speed: float = 600.0
@export var lifetime: float = 6.0
var damage: int = 20
var direction: Vector2 = Vector2.ZERO


# Removes the projectile after its lifetime expires.
func _ready() -> void:
	await get_tree().create_timer(lifetime).timeout
	queue_free()


# Moves the head projectile along its launch direction.
func _physics_process(_delta: float) -> void:
	velocity = direction * speed
	move_and_slide()


# Sets the normalized travel direction for this projectile.
func launch(aim_dir: Vector2, _target: Node2D) -> void:
	direction = aim_dir.normalized()


# Handles collisions with physics bodies.
func _on_area_2d_body_entered(body) -> void:
	_handle_collision(body)


# Handles collisions with areas, resolving damageable parents when needed.
func _on_area_2d_area_entered(area) -> void:
	var target = area if area.has_method("take_damage") else area.get_parent()
	_handle_collision(target)


# Applies damage or destroys the head on valid hits, walls, and bounce states.
func _handle_collision(target) -> void:
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


# Destroys the head when it is hit by other damage sources.
func take_damage(amount) -> void:
	queue_free()
