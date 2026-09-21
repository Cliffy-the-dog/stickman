extends Node2D

@onready var label: Label = $Label
@onready var player: CharacterBody2D = %Player


## Updates the on-screen label to show the player's current skin count.
func _process(_delta: float) -> void:
	if is_instance_valid(player):
		label.text = str(player.skins)
