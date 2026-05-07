extends Control

@onready var black: Sprite2D = $"../Black"
@onready var sunset_battle: Sprite2D = $"../Sunset Battle"

func load_game():
	if not FileAccess.file_exists("user://savegame.json"):
		return # No save file found
		
	# 1. Open and read the file
	var file = FileAccess.open("user://savegame.json", FileAccess.READ)
	var json_string = file.get_line()
	file.close()
	
	# 2. Parse the JSON string
	var json = JSON.new()
	var error = json.parse(json_string)
	
	if error == OK:
		var data_received = json.data
		print(data_received["Health Upgrades"]) # Access your data here
	else:
		print("JSON Parse Error: ", json.get_error_message())


func _on_option_button_item_selected(index: int) -> void:
	if index == 1:
		sunset_battle.z_index = -99
		black.z_index = -110
	if index == 2:
		sunset_battle.z_index = -110
		black.z_index = -99


func _on_button_pressed() -> void:
	z_index = -110
