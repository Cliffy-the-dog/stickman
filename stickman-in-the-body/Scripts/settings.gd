extends Control

@onready var black: Sprite2D = $"../Black"
@onready var sunset_battle: Sprite2D = $"../Sunset Battle"


# Attempts to load and print health upgrade data from an existing save file.
func load_game() -> void:
	if not FileAccess.file_exists("user://savegame.json"):
		return

	var file = FileAccess.open("user://savegame.json", FileAccess.READ)
	var json_string = file.get_line()
	file.close()

	var json = JSON.new()
	var error = json.parse(json_string)

	if error == OK:
		var data_received = json.data
		print(data_received["Health Upgrades"])
	else:
		print("JSON Parse Error: ", json.get_error_message())


# Swaps background sprite z-index based on the selected option index.
func _on_option_button_item_selected(index: int) -> void:
	if index == 1:
		sunset_battle.z_index = -99
		black.z_index = -110
	if index == 2:
		sunset_battle.z_index = -110
		black.z_index = -99


# Sends this settings panel behind other UI layers.
func _on_button_pressed() -> void:
	z_index = -110
