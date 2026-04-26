extends Node

@onready var player: CharacterBody2D = %Player
@onready var health: ProgressBar = %Healthbar




func _on_blood_hotspring_thing_area_entered(area: Area2D) -> void:
	print("Touching",area)
