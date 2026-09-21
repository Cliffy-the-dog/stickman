extends CPUParticles2D

@onready var player: CharacterBody2D = %Player


# Keeps particle emission offset behind and above the player each frame.
func _process(_delta: float) -> void:
	global_position.x = player.global_position.x - 25
	global_position.y = player.global_position.y - 35
