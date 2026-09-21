extends TileMapLayer

@onready var healthbar: ProgressBar = %Healthbar


## Debug placeholder for checkpoint identification.
func Checkpointidentifier():
	print("Hello World")


## Restores a large amount of health when the player enters the checkpoint area.
func _on_area_2d_area_entered(area: Area2D) -> void:
	if area.has_method("flash_red"):
		healthbar.value = healthbar.value + 200000
