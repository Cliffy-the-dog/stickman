extends ColorRect
@onready var starter_scene: Node2D = $"../../../../../"

var local_hide = 1

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	hide()


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if starter_scene.paused == true:
		show()
		local_hide = 0
	if starter_scene.paused == false:
		hide()
		local_hide = 1
