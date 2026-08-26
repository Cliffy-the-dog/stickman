extends Sprite2D

@export var lifetime: float = 5.0
var damage: int = 15

func _ready():
	await get_tree().create_timer(lifetime).timeout
	queue_free()

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
			return # Spike doesn't destroy itself on bounce
		else:
			target.take_damage(damage)

func take_damage(amount):
	pass
