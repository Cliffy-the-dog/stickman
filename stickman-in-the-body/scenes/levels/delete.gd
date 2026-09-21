extends Button

var save_file_path: String = "user://savegame.json"


## Deletes the save file from disk if it exists.
func _on_pressed() -> void:
	if FileAccess.file_exists(save_file_path):
		var error = DirAccess.remove_absolute(save_file_path)
		if error == OK:
			print("Save file successfully deleted: ", save_file_path)
		else:
			push_error("Failed to delete save file. Error code: " + str(error))
	else:
		print("No save file found at path: ", save_file_path)
