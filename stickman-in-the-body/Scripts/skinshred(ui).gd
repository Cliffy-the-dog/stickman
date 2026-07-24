extends Node2D
@onready var label: Label = $Label
@onready var player: CharacterBody2D = $"../../../../../.."

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	label.text = str(player.skins)
