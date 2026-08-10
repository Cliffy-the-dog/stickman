extends CharacterBody2D

@export var speed: float = 1200.0
@export var max_lifetime: float = 1.5

var move_dir: Vector2 = Vector2.ZERO

func _ready():
	get_tree().create_timer(max_lifetime).timeout.connect(func():
		if is_instance_valid(self):
			queue_free()
	)

func launch(initial_dir: Vector2, _target_player: Node2D = null):
	move_dir = initial_dir.normalized()
	rotation = move_dir.angle()

func _physics_process(delta):
	if move_dir != Vector2.ZERO:
		var collision = move_and_collide(move_dir * speed * delta)
		if collision:
			var hit_object = collision.get_collider()
			
			if hit_object and hit_object.has_method("take_damage"):
				hit_object.take_damage(15)
			elif hit_object and hit_object.has_method("_on_fazed_hitbox_area_entered"):
				hit_object._on_fazed_hitbox_area_entered()
				
			# Breaks instantly on collision
			queue_free()

func take_damage(amount):
	# The instant it takes damage from a pogo or slash, it deletes itself!
	queue_free()
