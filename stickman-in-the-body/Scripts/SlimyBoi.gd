extends Node2D
@onready var r: RayCast2D = $R
@onready var l: RayCast2D = $L

@onready var healthbar: ProgressBar = $Healthbar

var speed = 900
var direction = 1

func _physics_process(delta: float) -> void:
	if r.is_colliding():
		direction = -1
	if l.is_colliding():
		direction = 1
	position.x += speed * delta * direction

func take_damage(damage):
	healthbar.health -= damage
	healthbar.value -= damage
