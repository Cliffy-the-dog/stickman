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

var defeated_entity_ids: Array = []

func _ready() -> void:
	add_to_group("save_manager")
	hide()
	load_game()

func save_game():
	if is_instance_valid(hoard) and hoard.current_state == hoard.BossState.DEAD:
		if not defeated_entity_ids.has("boss_hoard"):
			defeated_entity_ids.append("boss_hoard")

	# Save active abilities and unlocks to array
	var inventory: Array = []
	if is_instance_valid(player):
		if player.has_walljump:
			inventory.append("walljump")
		if "has_bloodbind" in player and player.has_bloodbind:
			inventory.append("bloodbind")

	if is_instance_valid(healer) and healer.health_upgrade_bought:
		inventory.append("healer_upgrade")

	var save_data = {
		"checkpoint": [player.last_checkpoint.x, player.last_checkpoint.y] if is_instance_valid(player) else [0.0, 0.0],
		"stats": {
			"money": player.money if is_instance_valid(player) else 0,
			"skins": player.skins if is_instance_valid(player) else 0,
			"damage": player.damage if is_instance_valid(player) else 10.0,
			"health_upgrades": management.health_upgrades if is_instance_valid(management) else 0
		},
		"inventory": inventory,
		"defeated_entities": defeated_entity_ids
	}

	var file = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file:
		file.store_line(JSON.stringify(save_data))
		file.close()

func load_game():
	if not FileAccess.file_exists(SAVE_PATH):
		return

	var file = FileAccess.open(SAVE_PATH, FileAccess.READ)
	var json_string = file.get_as_text()
	file.close()

	var json = JSON.new()
	if json.parse(json_string) == OK and json.data is Dictionary:
		var data = json.data

		# 1. Checkpoint Position
		if data.has("checkpoint") and data["checkpoint"] is Array and is_instance_valid(player):
			player.last_checkpoint = Vector2(data["checkpoint"][0], data["checkpoint"][1])
			player.global_position = player.last_checkpoint

		# 2. Player Stats
		if data.has("stats") and data["stats"] is Dictionary:
			var stats = data["stats"]
			if is_instance_valid(player):
				player.money = stats.get("money", 0)
				player.skins = stats.get("skins", 0)
				player.damage = stats.get("damage", 10.0)
			if is_instance_valid(management):
				management.health_upgrades = stats.get("health_upgrades", 0)
				var target_bar = healthbar if is_instance_valid(healthbar) else (player.get("healthbar") if is_instance_valid(player) else null)
				if target_bar:
					target_bar.max_value = 100 + 20 * management.health_upgrades

		# 3. Inventory Unlocks
		var inventory = data.get("inventory", [])
		if is_instance_valid(player):
			player.has_walljump = inventory.has("walljump")
			if "has_bloodbind" in player:
				player.has_bloodbind = inventory.has("bloodbind")

		if is_instance_valid(healer):
			healer.health_upgrade_bought = inventory.has("healer_upgrade")

		# 4. Persistence Deletions
		if data.has("defeated_entities") and data["defeated_entities"] is Array:
			defeated_entity_ids = []
			for item in data["defeated_entities"]:
				defeated_entity_ids.append(str(item))

		# PauseMenu _ready runs before later siblings (Hoard, Former Guardian) enter the tree.
		call_deferred("_apply_loaded_persistence")

func register_entity_death(entity_id: String) -> void:
	if entity_id != "" and not defeated_entity_ids.has(entity_id):
		defeated_entity_ids.append(entity_id)
		save_game()

func _apply_loaded_persistence() -> void:
	apply_entity_deaths()
	if not is_instance_valid(hoard):
		hoard = get_node_or_null("../../../Hoard")
	if is_instance_valid(hoard) and "exists_in_previous_save" in hoard:
		hoard.exists_in_previous_save = not defeated_entity_ids.has("boss_hoard")

func apply_entity_deaths() -> void:
	var tree := get_tree()
	if tree == null:
		return

	for tag in tree.get_nodes_in_group("non_respawning_tags"):
		if tag.has_method("is_defeated") and tag.is_defeated():
			var parent = tag.get_parent()
			if is_instance_valid(parent):
				parent.queue_free()

	for node in tree.get_nodes_in_group("persistent_entities"):
		if "entity_id" in node and defeated_entity_ids.has(str(node.entity_id)):
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
