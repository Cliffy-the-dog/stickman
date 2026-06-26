extends Control

@onready var black: Sprite2D = $Black
@onready var sunset_battle: Sprite2D = $"Sunset Battle"

var blackZindex = -99
var SunsetZindex = -100

func _process(delta: float) -> void:
	black.z_index = blackZindex
	sunset_battle.z_index = SunsetZindex
