extends TileMapLayer

@onready var hoard: CharacterBody2D = $"../../Hoard"

func _process(delta: float) -> void:
	if hoard.healthbar.value == 0:
		queue_free()
