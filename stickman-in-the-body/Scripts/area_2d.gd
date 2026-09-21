extends Area2D

@onready var animated_sprite_2d: AnimatedSprite2D = $AnimatedSprite2D
@onready var Slime: AnimatedSprite2D = $AnimatedSprite2D
@export var lifetime: float = 1.5

var GOOINSTANCE = preload("res://assets/sprites/Goo.tscn")
var slowed_speed = 700
var xpos = position.x
var ypos = position.y
var GooCount = 0


# Removes this goo patch after a fixed spawn delay.
func _ready() -> void:
	await get_tree().create_timer(2.0).timeout
	queue_free()


# Counts down lifetime and removes the goo when it expires.
func _process(delta: float) -> void:
	lifetime -= delta
	if lifetime <= 0:
		queue_free()


# Slows enemies that enter the goo and can take damage.
func _on_area_entered(area: Area2D) -> void:
	if area.has_method("take_damage") and not area.has_method("flash_red"):
		area.speed = slowed_speed


# Restores normal speed when slowed enemies leave the goo.
func _on_area_exited(area: Area2D) -> void:
	if area.has_method("take_damage") and not area.has_method("flash_red"):
		area.speed = 1200


# Placeholder hook for future goo behavior; currently unused.
func GITGUD() -> void:
	pass
