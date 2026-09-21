extends Sprite2D

@export var lifetime: float = 5.0
var damage: int = 15


## Despawns the spike after its lifetime expires.
func _ready():
	await get_tree().create_timer(lifetime).timeout
	queue_free()


## Damages a body that enters the spike's hit area.
func _on_area_2d_body_entered(body):
	_handle_collision(body)


## Damages an area (or its parent) that enters the spike's hit area.
func _on_area_2d_area_entered(area):
	var target = area if area.has_method("take_damage") else area.get_parent()
	_handle_collision(target)


## Applies damage unless the target is pogoing or bouncing off the spike.
func _handle_collision(target):
	if target and target.has_method("take_damage") and not target.has_method("pick_random_attack"):
		var is_pogoing_now = "is_pogoing" in target and target.is_pogoing and target.velocity.y > 0
		var is_bouncing_now = "bouncing_in_progress" in target and target.bouncing_in_progress > 0

		if is_pogoing_now or is_bouncing_now:
			return
		else:
			target.take_damage(damage)


## Spikes are indestructible and ignore incoming damage.
func take_damage(amount):
	pass
