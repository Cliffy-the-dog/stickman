extends Node


# Logs when an area enters the blood hotspring trigger.
func _on_blood_hotspring_thing_area_entered(area: Area2D) -> void:
	print("Touching", area)
