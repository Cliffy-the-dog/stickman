extends Control

@onready var hoard: CharacterBody2D = $"../../../Hoard"
@onready var management: Node = %Management
@onready var color_rect: ColorRect = $"../ColorRect"
@onready var healer: AnimatedSprite2D = $"../../../Collecter2"
@onready var starter_scene: Node2D = $"../../../../.."
@onready var player: CharacterBody2D = %Player
@onready var healthbar: ProgressBar = %Healthbar
const SAVE_PATH = "user://savegame.json"
@onready var control: Control = $"../Control"

# --- Save Data Variables ---
var last_checkpoint: Vector2 = Vector2.ZERO
var skins: int = 0
var damage: float = 10.0
var money: int = 0
var has_walljump: bool = false
var defeated_entity_ids: Array = [] # ADDED: Array for tracking group deaths

func _ready() -> void:
	add_to_group("save_manager") # ADDED: Allows entities to quickly locate this script
	hide()
	load_game()

func save_game():
	var hoard_alive = is_instance_valid(hoard) and hoard.current_state != hoard.BossState.DEAD
	
	var save_data = {
		"checkpoint_x": player.last_checkpoint.x if is_instance_valid(player) else 0.0,
		"checkpoint_y": player.last_checkpoint.y if is_instance_valid(player) else 0.0,
		"skinshreds": player.skins if is_instance_valid(player) else 0,
		"health_upgrades": management.health_upgrades if is_instance_valid(management) else 0,
		"health_upgrade_bought": healer.health_upgrade_bought if is_instance_valid(healer) else false,
		"Sword_Damage": player.damage if is_instance_valid(player) else 10.0,
		"money": player.money if is_instance_valid(player) else 0,
		"has_walljump": player.has_walljump if is_instance_valid(player) else false,
		"Hoard_exists": hoard_alive,
		"defeated_entities": defeated_entity_ids # ADDED: Save array of defeated IDs
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
		if data is Dictionary:
			if data.has("checkpoint_x") and data.has("checkpoint_y") and is_instance_valid(player):
				player.last_checkpoint = Vector2(data["checkpoint_x"], data["checkpoint_y"])
				player.global_position = player.last_checkpoint
				print("DEBUG: Checkpoint loaded: ", player.last_checkpoint)
			
			if data.has("health_upgrades") and is_instance_valid(management):
				management.health_upgrades = data["health_upgrades"]
				var target_bar = healthbar if is_instance_valid(healthbar) else (player.get("healthbar") if is_instance_valid(player) else null)
				if target_bar:
					target_bar.max_value = 100 + 20 * data["health_upgrades"]

			if data.has("health_upgrade_bought") and is_instance_valid(healer):
				healer.health_upgrade_bought = data["health_upgrade_bought"]

			if data.has("has_walljump") and is_instance_valid(player):
				player.has_walljump = data["has_walljump"]

			if data.has("money") and is_instance_valid(player):
				player.money = data["money"]

			if data.has("skinshreds") and is_instance_valid(player):
				player.skins = data["skinshreds"]

			if data.has("Sword_Damage") and is_instance_valid(player):
				player.damage = data["Sword_Damage"]

			# UN-NESTED: Check boss status independently
			if data.has("Hoard_exists") and is_instance_valid(hoard):
				hoard.exists_in_previous_save = data["Hoard_exists"]
				print("DEBUG: Hoard existence loaded as: ", data["Hoard_exists"])

			# ADDED: Load defeated entity array and destroy them in scene
			if data.has("defeated_entities"):
				defeated_entity_ids = data["defeated_entities"]
				apply_entity_deaths()
	else:
		print("DEBUG: JSON Parse Error: ", json.get_error_message())

# --- ADDED: Helper functions for group death handling ---
func register_entity_death(entity_id: String) -> void:
	if entity_id != "" and not defeated_entity_ids.has(entity_id):
		defeated_entity_ids.append(entity_id)
		save_game()

func apply_entity_deaths() -> void:
	var persistent_nodes = get_tree().get_nodes_in_group("persistent_entities")
	for node in persistent_nodes:
		if "entity_id" in node and defeated_entity_ids.has(node.entity_id):
			node.queue_free()

func _process(_delta: float) -> void:
	if color_rect.local_hide == 1: hide()
	elif color_rect.local_hide == 0: show()

func _on_resume_pressed() -> void:
	starter_scene.pauseMenu()
	control.mouse_filter = Control.MOUSE_FILTER_PASS
	mouse_filter = Control.MOUSE_FILTER_PASS

func _on_quit_to_menu_pressed() -> void:
	save_game()
	get_tree().paused = false
	Engine.time_scale = 1
	get_tree().change_scene_to_file("res://Scenes/levels/MainMenu.tscn")
