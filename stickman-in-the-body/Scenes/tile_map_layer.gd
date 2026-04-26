extends TileMapLayer
@onready var healthbar: ProgressBar = %Healthbar


# Called when the node enters the scene tree for the first time.
func Checkpointidentifier():
	print("Hello World")


func _on_area_2d_area_entered(area: Area2D) -> void:
	if area.has_method("flash_red"):
		healthbar.value = healthbar.value + 200000
