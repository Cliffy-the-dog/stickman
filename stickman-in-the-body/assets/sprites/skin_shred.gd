extends Node2D

func _on_area_2d_area_entered(area: Area2D) -> void:
	# Get the parent of the Area2D that collided with us
	var area_parent = area.get_parent()
	
	# Check if the parent exists and has the method
	if area_parent and area_parent.has_method("flash_red"):
		area_parent.skins += 1
		print(area_parent	.skins)
		queue_free()

func _on_area_2d_body_entered(body: Node2D) -> void:
	# If the body itself has the script (e.g. it is a CharacterBody2D with the Player script)
	if body.has_method("flash_red"):
		body.skins += 1
		queue_free()
	# Alternatively, if the script is on the body's parent
	elif body.get_parent() and body.get_parent().has_method("flash_red"):
		body.get_parent().skins += 1
		print(body.get_parent().skins)
		queue_free()
