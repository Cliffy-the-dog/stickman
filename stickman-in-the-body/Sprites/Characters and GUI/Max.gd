extends Label
@onready var healthbar: ProgressBar = %Healthbar


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	text = str(healthbar.value) + " of " + str(healthbar.max_value)
