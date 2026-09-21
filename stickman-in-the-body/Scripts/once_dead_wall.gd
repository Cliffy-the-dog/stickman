extends TileMapLayer

@onready var hoard: CharacterBody2D = $"../../../Hoard"


# Removes this wall once the hoard boss is defeated or no longer exists.
func _process(_delta: float) -> void:
	if is_instance_valid(hoard):
		if hoard.healthbar.value == 0:
			queue_free()

	if not is_instance_valid(hoard):
		queue_free()
