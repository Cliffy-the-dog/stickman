extends Control

@onready var black: Sprite2D = $Black
@onready var sunset_battle: Sprite2D = $"Sunset Battle"

var blackZindex: int = -99
var SunsetZindex: int = -100


# Keeps background sprite draw order in sync with configured z-index values.
func _process(_delta: float) -> void:
	black.z_index = blackZindex
	sunset_battle.z_index = SunsetZindex
