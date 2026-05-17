extends TileMapLayer

@onready var collision_shape_2d: StaticBody2D = $"Floor Hitbox"

func _ready() -> void:
	show()
	collision_shape_2d.set_collision_layer_value(2, true)
	collision_shape_2d.set_collision_mask_value(2, true)





func _on_area_2d_area_entered(area: Area2D) -> void:
	await get_tree().create_timer(1).timeout
	hide()
	collision_shape_2d.set_collision_layer_value(2, false)
	collision_shape_2d.set_collision_mask_value(2, true)
	await get_tree().create_timer(1).timeout
	show()
	collision_shape_2d.set_collision_layer_value(2, true)
	collision_shape_2d.set_collision_mask_value(2, true)
