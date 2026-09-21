extends Button

@onready var delete_save_popup: Panel = $"../DeleteSavePopup"


## Opens the delete-save confirmation popup.
func _on_pressed() -> void:
	delete_save_popup.show()
