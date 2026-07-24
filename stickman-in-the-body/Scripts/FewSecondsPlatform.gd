extends TileMapLayer

@onready var collision_shape_2d: StaticBody2D = $"Floor Hitbox"
@export var StandDuration = 0.75 #CRITICAL: THIS IS IN SECONDS. THE LOWER THE HARDER
@export var RegenerationDuration = 1 #CRITICAL: THIS IS IN SECONDS. THE HIGHER THE HARDER

func _ready() -> void:
	show()
	collision_shape_2d.set_collision_layer_value(2, true)
	collision_shape_2d.set_collision_mask_value(2, true)


func passage():
	pass


func _on_area_2d_area_entered(area: Area2D) -> void:
	await get_tree().create_timer(StandDuration).timeout
	hide()
	collision_shape_2d.set_collision_layer_value(2, false)
	collision_shape_2d.set_collision_mask_value(2, true)
	await get_tree().create_timer(RegenerationDuration).timeout
	show()
	collision_shape_2d.set_collision_layer_value(2, true)
	collision_shape_2d.set_collision_mask_value(2, true)
