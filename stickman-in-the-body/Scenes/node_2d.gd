extends CPUParticles2D

@onready var player: CharacterBody2D = %Player



# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	global_position.x = player.global_position.x + 15
	global_position.y = player.global_position.y + 25
