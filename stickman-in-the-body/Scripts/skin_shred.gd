extends Node2D


## Awards one skin to the player when collected via area overlap.
func _on_area_2d_area_entered(area: Area2D) -> void:
	var area_parent = area.get_parent()

	if area_parent and area_parent.has_method("flash_red"):
		area_parent.skins += 1
		print(area_parent.skins)
		queue_free()


## Awards one skin to the player when collected via body collision.
func _on_area_2d_body_entered(body: Node2D) -> void:
	if body.has_method("flash_red"):
		body.skins += 1
		queue_free()
	elif body.get_parent() and body.get_parent().has_method("flash_red"):
		body.get_parent().skins += 1
		print(body.get_parent().skins)
		queue_free()
