extends AnimatedSprite2D

@export var damage: int = 10 
var direction = Vector2.ZERO
var speed = 1300.0
var homing_strength = 1.5 
var player_ref: Node2D = null
var is_armed: bool = false

func _ready():
	var hitbox = $Area2D as Area2D
	if hitbox:
		# Connect BOTH physics body and Area2D signals
		if not hitbox.body_entered.is_connected(_on_hit):
			hitbox.body_entered.connect(_on_hit)
		if not hitbox.area_entered.is_connected(_on_hit):
			hitbox.area_entered.connect(_on_hit)
	else:
		push_error("Limb Projectile is missing its child Area2D!")

	# Small grace period so it clears the boss before triggering collisions
	await get_tree().create_timer(0.05).timeout
	is_armed = true

func set_direction(dir: Vector2, target_player: Node2D):
	direction = dir.normalized()
	rotation = direction.angle() 
	player_ref = target_player
	play()

func _physics_process(delta):
	if player_ref and is_instance_valid(player_ref):
		var target_dir = global_position.direction_to(player_ref.global_position)
		direction = direction.slerp(target_dir, homing_strength * delta).normalized()
		rotation = direction.angle()
		
	global_position += direction * speed * delta

func _on_hit(target: Node):
	if target == null: return
		
	# Ignore Boss body and Boss child nodes
	if target.has_method("pick_random_attack") or (target.get_parent() and target.get_parent().has_method("pick_random_attack")):
		return

	# 1. Try standard take_damage
	if target.has_method("take_damage"):
		target.take_damage(damage)
	elif target.get_parent() and target.get_parent().has_method("take_damage"):
		target.get_parent().take_damage(damage)
		
	# 2. Try your specific Fazed Hitbox setup! 
	# (Notice the 'self' added inside the parentheses here)
	elif target.has_method("_on_fazed_hitbox_area_entered"):
		target._on_fazed_hitbox_area_entered(self)
	elif target.name == "Fazed Hitbox" and target.get_parent() and target.get_parent().has_method("_on_fazed_hitbox_area_entered"):
		target.get_parent()._on_fazed_hitbox_area_entered(self)
		
	# Only the LimbProjectile needs this bottom part! 
	# IF YOU ARE PASTING THIS INTO THE SPIKE SCRIPT, DELETE THESE BOTTOM TWO LINES:
	if has_method("set_direction"): 
		queue_free()
func take_damage(amount):
	queue_free()
