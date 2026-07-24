extends CharacterBody2D

var move_dir = Vector2.ZERO
var speed = 1400.0

func launch(dir):
	move_dir = dir

func _physics_process(delta):
	if move_dir != Vector2.ZERO:
		# Use move_and_collide to detect collisions
		var collision = move_and_collide(move_dir * speed * delta)
		
		# Identify the object hit
		if collision:
			var hit_object = collision.get_collider()
			if hit_object.has_method("_on_fazed_hitbox_area_entered"):
				hit_object._on_fazed_hitbox_area_entered()
			queue_free() # Destroy projectile
