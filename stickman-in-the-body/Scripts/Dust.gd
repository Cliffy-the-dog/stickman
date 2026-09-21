extends CPUParticles2D

@onready var player: CharacterBody2D = %Player


# Keeps dust particles offset slightly ahead and below the player each frame.
func _process(_delta: float) -> void:
	global_position.x = player.global_position.x + 15
	global_position.y = player.global_position.y + 25
