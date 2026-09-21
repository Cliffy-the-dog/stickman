extends Node2D

@onready var animated_sprite_2d: AnimatedSprite2D = $AnimatedSprite2D
@onready var static_body_2d: StaticBody2D = $"../StaticBody2D"
@onready var static_body_2d_2: StaticBody2D = $"../StaticBody2D2"
@onready var static_body_2d_3: StaticBody2D = $"../StaticBody2D3"

var buttondown = 0


## Initializes the button as unpressed and hides linked collision bodies.
func _ready() -> void:
	animated_sprite_2d.play("Not Pressed")
	static_body_2d.hide()
	static_body_2d_2.hide()
	static_body_2d_3.hide()
	static_body_2d.set_collision_mask_value(1, false)
	static_body_2d.set_collision_mask_value(2, false)
	static_body_2d_2.set_collision_mask_value(1, false)
	static_body_2d_2.set_collision_mask_value(2, false)
	static_body_2d_3.set_collision_mask_value(1, false)
	static_body_2d_3.set_collision_mask_value(2, false)


## Activates the button when the player body enters the trigger area.
func _on_area_2d_body_entered(body: Node2D) -> void:
	if body.has_method("flash_red") and buttondown == 0:
		buttondown = 1
		animated_sprite_2d.play("Press")
		await animated_sprite_2d.animation_finished
		animated_sprite_2d.play("Pressed")
		static_body_2d.show()
		static_body_2d_2.show()
		static_body_2d_3.show()


## Activates the button when a player area enters the trigger and disables collision masks.
func _on_area_2d_area_entered(area: Area2D) -> void:
	if area.has_method("flash_red") and buttondown == 0:
		buttondown = 1
		animated_sprite_2d.play("Press")
		await animated_sprite_2d.animation_finished
		animated_sprite_2d.play("Pressed")
		static_body_2d.show()
		static_body_2d_2.show()
		static_body_2d_3.show()
		static_body_2d.set_collision_mask_value(1, false)
		static_body_2d.set_collision_mask_value(2, false)
		static_body_2d_2.set_collision_mask_value(1, false)
		static_body_2d_2.set_collision_mask_value(2, false)
		static_body_2d_3.set_collision_mask_value(1, false)
		static_body_2d_3.set_collision_mask_value(2, false)
