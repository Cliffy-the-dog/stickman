extends Control
@onready var hoard: CharacterBody2D = $"../../../Hoard"
@onready var management: Node = %Management
@onready var color_rect: ColorRect = $"../ColorRect"
@onready var healer: AnimatedSprite2D = $"../../../Collecter2"
@onready var starter_scene: Node2D = $"../../../../.."
@onready var player: CharacterBody2D = %Player
@onready var healthbar: ProgressBar = $"../../Healthbar"
const SAVE_PATH = "user://savegame.json"
@onready var control: Control = $"../Control"
# --- Save Data Variables ---
var last_checkpoint: Vector2 = Vector2.ZERO
var skins: int = 0
var damage: float = 10.0 # Or whatever your default starting damage is
var money: int = 0
var has_walljump: bool = false
func _ready() -> void:
	hide()
	load_game()

func save_game():
	var save_data = {
		"checkpoint_x": player.last_checkpoint.x,
		"checkpoint_y": player.last_checkpoint.y,
		"skinshreds": player.skins,
		"health_upgrades": management.health_upgrades,
		"health_upgrade_bought": healer.health_upgrade_bought,
		"Sword_Damage": player.damage,
		"money": player.money,
		"has_walljump": player.has_walljump,
		# THE FIX: Check if the node is valid AND make sure its state is not DEAD
		"Hoard_exists": is_instance_valid(hoard) and hoard.current_state != hoard.BossState.DEAD
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
	await get_tree().create_timer(0.1).timeout
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
				print("DEBUG: Health Upgrades loaded: ", management.health_upgrades)
				healthbar.max_value = 100 + 20 * data["health_upgrades"]
				

			if data.has("health_upgrade_bought"):
				healer.health_upgrade_bought = data["health_upgrade_bought"]

			if data.has("has_walljump"):
				player.has_walljump = data["has_walljump"]

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
	control.mouse_filter = Control.MOUSE_FILTER_PASS
	mouse_filter = Control.MOUSE_FILTER_PASS

func _on_quit_to_menu_pressed() -> void:
	save_game()
	get_tree().paused = false # <-- ADD THIS HERE
	Engine.time_scale = 1
	get_tree().change_scene_to_file("res://Scenes/levels/MainMenu.tscn")
