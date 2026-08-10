extends Sprite2D

@export var damage: int = 20
@export var lifetime: float = 1.2 

func _ready():
	var hitbox = $Area2D as Area2D
	if hitbox:
		# Connect BOTH physics body and Area2D signals
		if not hitbox.body_entered.is_connected(_on_hit):
			hitbox.body_entered.connect(_on_hit)
		if not hitbox.area_entered.is_connected(_on_hit):
			hitbox.area_entered.connect(_on_hit)
			
		# Check for players already standing on the spike when it spawns
		await get_tree().process_frame
		if is_instance_valid(hitbox):
			for body in hitbox.get_overlapping_bodies():
				_on_hit(body)
			for area in hitbox.get_overlapping_areas():
				_on_hit(area)
	else:
		push_error("Spike is missing its child Area2D!")
	
	get_tree().create_timer(lifetime).timeout.connect(queue_free)

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
