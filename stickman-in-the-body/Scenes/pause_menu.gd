extends Control

@onready var hoard: CharacterBody2D = $"../../../Hoard"
@onready var management: Node = %Management
@onready var color_rect: ColorRect = $"../ColorRect"
@onready var healer: AnimatedSprite2D = $"../../../Collecter2"
@onready var starter_scene: Node2D = $"../../../../.."
@onready var player: CharacterBody2D = %Player

const SAVE_PATH = "user://savegame.json"

func _ready() -> void:
	hide()

func save_game():
	var save_data = {
		"checkpoint_x": player.last_checkpoint.x,
		"checkpoint_y": player.last_checkpoint.y,
		"skinshreds": player.skins,
		"health_upgrades": management.health_upgrades,
		"health_upgrade_bought": healer.health_upgrade_bought,
		"Sword_Damage": player.damage,
		"money": player.money,
		"Hoard_exists": is_instance_valid(hoard)
	}
	
	var json_string = JSON.stringify(save_data)
	var file = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	
	if file:
		file.store_line(json_string)
		file.close()
		print("DEBUG: Save successful to ", SAVE_PATH)
	else:
		print("DEBUG: Save failed! Error: ", FileAccess.get_open_error())

func load_game():
	if not FileAccess.file_exists(SAVE_PATH):
		print("DEBUG: No save file found.")
		return

	var file = FileAccess.open(SAVE_PATH, FileAccess.READ)
	var json_string = file.get_as_text()
	file.close()

	var json = JSON.new()
	var error = json.parse(json_string)

	if error == OK:
		var data = json.data
		# CRITICAL FIX: Check if keys exist before accessing to prevent crash
		if data is Dictionary:
			if data.has("checkpoint_x") and data.has("checkpoint_y"):
				player.last_checkpoint = Vector2(data["checkpoint_x"], data["checkpoint_y"])
				player.global_position = player.last_checkpoint
				print("DEBUG: Checkpoint loaded: ", player.last_checkpoint)
			
			if data.has("health_upgrades"):
				management.health_upgrades = data["health_upgrades"]
				print("DEBUG: Upgrades loaded: ", management.health_upgrades)

			if data.has("health_upgrade_bought"):
				healer.health_upgrade_bought = data["health_upgrade_bought"]


			if data.has("money"):
				player.money = data["money"]
				print("DEBUG: Upgrades loaded: ", player.money)

			if data.has("skinshreds"):
				player.skins = data["skinshreds"]
				print("DEBUG: Upgrades loaded: ", player.skins)

			if data.has("Hoard_exists"):
				hoard.exists_in_previous_save = data["Hoard_exists"]

			if data.has("Sword_Damage"):
				player.damage = data["Sword_Damage"]
				print("DEBUG: Upgrades loaded: ", player.damage)
		else:
			print("DEBUG: Unexpected data format in save file.")
	else:
		print("DEBUG: JSON Parse Error: ", json.get_error_message())

func _process(_delta: float) -> void:
	if color_rect.local_hide == 1: hide()
	elif color_rect.local_hide == 0: show()

func _on_resume_pressed() -> void:
	starter_scene.pauseMenu()

func _on_quit_to_menu_pressed() -> void:
	save_game()
	get_tree().paused = false # <-- ADD THIS HERE
	Engine.time_scale = 1
	get_tree().change_scene_to_file("res://Scenes/control.tscn")
