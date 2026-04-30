extends CharacterBody2D
@onready var CHARACTER: CharacterBody2D = $"."



func _ready() -> void:
	look_at(CHARACTER.global_position)

func _physics_process(_delta: float):
	# move_and_slide() returns true if it hits a wall/body
	var collided = move_and_slide()
	
	if collided:
		queue_free()
func take_damage():
	queue_free()
