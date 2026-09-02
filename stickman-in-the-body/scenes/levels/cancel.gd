extends Button

@onready var delete_save_popup: Panel = $".."

func _on_pressed() -> void:
	delete_save_popup.hide()
