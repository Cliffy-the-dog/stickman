class_name PersistencyTracker
extends Node

## Unique string identifier for this entity (e.g., "guardian_boss_area_1")
@export var entity_id: String = ""

func _ready() -> void:
	call_deferred("_check_persistence")

func _check_persistence() -> void:
	if entity_id.strip_edges() == "":
		return

	if is_defeated():
		# Free the parent node (e.g., Guardian, Door, Spawner) before it renders
		var parent = get_parent()
		if parent:
			parent.queue_free()

func is_defeated() -> bool:
	if entity_id.strip_edges() == "":
		return false
		
	var save_mgr = _find_save_manager()
	if save_mgr and "defeated_entity_ids" in save_mgr:
		return entity_id in save_mgr.defeated_entity_ids
	return false

func on_defeated() -> void:
	if entity_id.strip_edges() == "":
		return

	var save_mgr = _find_save_manager()
	if save_mgr and save_mgr.has_method("register_entity_death"):
		save_mgr.register_entity_death(entity_id)

func _find_save_manager() -> Node:
	var sm = get_tree().get_first_node_in_group("save_manager")
	if sm:
		return sm
	return get_tree().current_scene.find_child("pause_menu", true, false)
