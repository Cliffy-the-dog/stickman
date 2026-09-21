extends Label

@onready var healthbar: ProgressBar = %Healthbar


# Displays current and maximum health from the linked progress bar.
func _process(_delta: float) -> void:
	text = str(healthbar.value) + " of " + str(healthbar.max_value)
