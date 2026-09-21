extends TileMapLayer

@onready var hoard: CharacterBody2D = $"../../../../../Former Guardian"


## Removes this layer when the Former Guardian boss is defeated or missing.
func _process(delta: float) -> void:
	if is_instance_valid(hoard):
		if hoard.healthbar.value == 0:
			queue_free()

	if not is_instance_valid(hoard):
		queue_free()
