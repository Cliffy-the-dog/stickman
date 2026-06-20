extends ColorRect
@onready var starter_scene: Node2D = $"../../../../../"

@onready var screens: Array[ColorRect] = [$MapScreen, $InventoryScreen, $BuildScreen]

var traffic_control = 0
var local_hide = 1
var HIDDEN = true

# New variable to keep track of which screen is currently active
var current_tab_index: int = 0 

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	hide()
	HIDDEN = true

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if starter_scene.paused == true:
		show()
		local_hide = 0
	if starter_scene.paused == false:
		if HIDDEN:
			hide()
		local_hide = 1
		
