class_name PersistencyTracker
extends Node

@export var custom_id: String = ""
var entity_id: String = ""
var has_registered_death: bool = false

func _ready() -> void:
	var parent = get_parent()
	if not parent:
		return

	# 1. Generate unique scene-stable ID
	if not custom_id.is_empty():
		entity_id = custom_id
	elif parent.owner:
		entity_id = parent.owner.scene_file_path + "::" + str(parent.owner.get_path_to(parent))
	else:
		entity_id = str(parent.get_path())

	# 2. Wait 1 frame for SaveManager to initialize and load file
	await get_tree().process_frame

	# 3. If already defeated in save file, remove the boss immediately on level load
	var save_manager = get_tree().get_first_node_in_group("save_manager")
	if save_manager and "defeated_entity_ids" in save_manager:
		if save_manager.defeated_entity_ids.has(entity_id):
			parent.queue_free()

func _process(_delta: float) -> void:
	if has_registered_death:
		return

	var parent = get_parent()
	if not is_instance_valid(parent):
		return

	# Automatically detect if the boss is dying/dead from its health or state
	if is_parent_dead(parent):
		has_registered_death = true
		register_death()
		set_process(false)

func is_parent_dead(parent: Node) -> bool:
	# Check health variable (Former Guardian)
	if "health" in parent and parent.health <= 0:
		return true

	# Check healthbar progress value (Hoard / Guardian)
	if "healthbar" in parent and is_instance_valid(parent.healthbar) and parent.healthbar.value <= 0:
		return true

	# Check boss state enum / variable (DEAD or DYING states)
	if "current_state" in parent:
		var state_str = str(parent.current_state).to_upper()
		# Matches BossState.DEAD (3) or State.DYING (10)
		if state_str in ["3", "10", "DEAD", "DYING"]:
			return true

	return false

func register_death() -> void:
	var save_manager = get_tree().get_first_node_in_group("save_manager")
	if save_manager and save_manager.has_method("register_entity_death"):
		save_manager.register_entity_death(entity_id)
