extends ColorRect

@onready var starter_scene: Node2D = $"../../../../../"
@onready var screens: Array[ColorRect] = [$MapScreen, $InventoryScreen, $BuildScreen]

var local_hide: int = 1
var HIDDEN: bool = true
var current_tab_index: int = 0


# Starts hidden and marks the overlay as not visible.
func _ready() -> void:
	hide()
	HIDDEN = true


# Shows the overlay while paused and hides it again when gameplay resumes.
func _process(_delta: float) -> void:
	if starter_scene.paused:
		show()
		local_hide = 0
	else:
		if HIDDEN:
			hide()
		local_hide = 1
