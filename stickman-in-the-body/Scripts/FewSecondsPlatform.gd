extends TileMapLayer

@onready var collision_shape_2d: StaticBody2D = $"Floor Hitbox"
@export var StandDuration = 0.75 # CRITICAL: seconds before the platform hides; lower = harder
@export var RegenerationDuration = 1 # CRITICAL: seconds before the platform returns; higher = harder


# Makes the platform visible and enables its floor collision on spawn.
func _ready() -> void:
	show()
	collision_shape_2d.set_collision_layer_value(2, true)
	collision_shape_2d.set_collision_mask_value(2, true)


# Reserved hook for future passage logic; currently unused.
func passage() -> void:
	pass


# Hides the platform after a stand delay, then restores it after regeneration.
func _on_area_2d_area_entered(_area: Area2D) -> void:
	await get_tree().create_timer(StandDuration).timeout
	hide()
	collision_shape_2d.set_collision_layer_value(2, false)
	collision_shape_2d.set_collision_mask_value(2, true)
	await get_tree().create_timer(RegenerationDuration).timeout
	show()
	collision_shape_2d.set_collision_layer_value(2, true)
	collision_shape_2d.set_collision_mask_value(2, true)
