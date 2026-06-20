extends Area2D

@export var speed: float = 800.0
@export var max_distance: float = 400.0
@export var damage: int = 50

var direction := Vector2.ZERO
var player_ref: Node2D = null
var distance_traveled: float = 0.0
var is_returning: bool = false
var is_flipped: bool = false
var is_punching: bool = false 

var caught_targets: Array = []
@onready var chain_line: Line2D = $Line2D


func _ready() -> void:
	# Flip the graphic to match the player's facing direction
	if has_node("AnimatedSprite2D"):
		$AnimatedSprite2D.flip_h = is_flipped
	elif has_node("Sprite2D"):
		$Sprite2D.flip_h = is_flipped

func _physics_process(delta: float) -> void:
	if not is_returning:
		# 1. OUTWARD MOVEMENT
		var step = direction * speed * delta
		global_position += step
		distance_traveled += step.length()
		
		# Play Reeling animation when turning around
		if distance_traveled >= max_distance:
			is_returning = true
			if is_instance_valid(player_ref):
				player_ref.character.play("Reeling")
	else:
		# 2. RETURNING MOVEMENT
		if is_instance_valid(player_ref):
			if not is_punching:
				direction = (player_ref.global_position - global_position).normalized()
				global_position += direction * speed * delta
				
				# Stop 100 pixels away from the player to prevent collision damage
				if global_position.distance_to(player_ref.global_position) < 300.0:
					is_punching = true
					trigger_punch()
		else:
			if chain_line: chain_line.queue_free()
			queue_free()

	# 3. PULL CAUGHT TARGETS
	for target in caught_targets:
		if is_instance_valid(target):
			target.global_position = target.global_position.lerp(global_position, 0.5)

	update_chain_trail()

func trigger_punch() -> void:
	# Play the Bloodpunch animation
	if is_instance_valid(player_ref):
		player_ref.character.play("Bloodpunch")
		
	# The Cinematic Pause
	await get_tree().create_timer(0.25).timeout 
	
	if is_instance_valid(player_ref):
		for target in caught_targets:
			if is_instance_valid(target) and target.has_method("apply_knockback"):
				var push_dir = sign(target.global_position.x - player_ref.global_position.x)
				if push_dir == 0:
					push_dir = -1.0 if player_ref.character.flip_h else 1.0
					
				target.apply_knockback(Vector2(push_dir * 2400.0, -800.0))
		
		# Unlock the player's movement!
		player_ref.finish_bloodbind()
	
	if chain_line: chain_line.queue_free()
	queue_free()

func update_chain_trail() -> void:
	if chain_line and is_instance_valid(player_ref):
		# Ensure the line only ever manages exactly 2 points
		if chain_line.points.size() != 2:
			chain_line.clear_points()
			chain_line.add_point(Vector2.ZERO)
			chain_line.add_point(Vector2.ZERO)
		
		# Lock the endpoints securely between the player and the projectile
		chain_line.set_point_position(0, chain_line.to_local(player_ref.global_position))
		chain_line.set_point_position(1, chain_line.to_local(global_position))
func _on_body_entered(body: Node2D) -> void:
	if body == player_ref:
		return
		
	if body.has_method("take_damage") and not body in caught_targets:
		body.take_damage(damage)
		caught_targets.append(body)
