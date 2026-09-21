extends Button

@onready var delete_save_popup: Panel = $".."


## Closes the delete-save confirmation popup without deleting.
func _on_pressed() -> void:
	delete_save_popup.hide()
