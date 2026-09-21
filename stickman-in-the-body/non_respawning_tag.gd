class_name PersistencyTracker
extends Node

## Optional stable ID. If empty, uses the parent's entity_id, then its path in the level.
@export var entity_id: String = ""

var _resolved_id: String = ""
var _tracked_parent: Node = null
var _logged: bool = false


# Registers with persistence groups and checks whether the parent should be removed.
func _ready() -> void:
	add_to_group("non_respawning_tags")
	_tracked_parent = get_parent()
	_resolved_id = _make_id()
	if is_instance_valid(_tracked_parent) and not _tracked_parent.tree_exiting.is_connected(_on_parent_tree_exiting):
		_tracked_parent.tree_exiting.connect(_on_parent_tree_exiting)
	call_deferred("_check_persistence")


# Builds a stable ID from export override, parent ID, or scene-relative path.
func _make_id() -> String:
	var override := entity_id.strip_edges()
	if override != "":
		return override
	if is_instance_valid(_tracked_parent) and "entity_id" in _tracked_parent:
		var parent_id := str(_tracked_parent.entity_id).strip_edges()
		if parent_id != "":
			return parent_id
	if not is_instance_valid(_tracked_parent):
		return ""
	var tree := _scene_tree()
	if tree and is_instance_valid(tree.current_scene) and tree.current_scene.is_ancestor_of(_tracked_parent):
		return str(tree.current_scene.get_path_to(_tracked_parent))
	return str(_tracked_parent.get_path())


# Returns the cached persistence ID, resolving it on first access.
func _id() -> String:
	if _resolved_id != "":
		return _resolved_id
	_resolved_id = _make_id()
	return _resolved_id


# Collects every ID that may match this entity in save data.
func _candidate_ids() -> Array[String]:
	var ids: Array[String] = []
	var primary := _id()
	if primary != "":
		ids.append(primary)
	if entity_id.strip_edges() != "" and not ids.has(entity_id.strip_edges()):
		ids.append(entity_id.strip_edges())
	if is_instance_valid(_tracked_parent) and "entity_id" in _tracked_parent:
		var parent_id := str(_tracked_parent.entity_id).strip_edges()
		if parent_id != "" and not ids.has(parent_id):
			ids.append(parent_id)
	return ids


# Removes the tracked parent immediately if it was already defeated in a save.
func _check_persistence() -> void:
	if is_defeated() and is_instance_valid(_tracked_parent):
		_tracked_parent.queue_free()


# Returns whether any candidate ID is marked defeated in the save manager.
func is_defeated() -> bool:
	var save_mgr := _find_save_manager()
	if save_mgr == null or not ("defeated_entity_ids" in save_mgr):
		return false
	var saved: Array = save_mgr.defeated_entity_ids
	for id in _candidate_ids():
		if saved.has(id):
			return true
	return false


# Public hook called when an entity is defeated during gameplay.
func on_defeated() -> void:
	_log_gone()


# Attempts to record defeat when the tracked parent begins exiting the tree.
func _on_parent_tree_exiting() -> void:
	_try_log_parent_freed()


# Attempts to record defeat when this tracker leaves the scene tree.
func _exit_tree() -> void:
	_try_log_parent_freed()


# Records defeat once when the parent is actually being freed outside scene unload.
func _try_log_parent_freed() -> void:
	if _logged:
		return
	if not is_instance_valid(_tracked_parent) or not _tracked_parent.is_queued_for_deletion():
		return
	if _is_scene_unloading():
		return
	_log_gone()


# Returns true while the current scene is unloading or unavailable.
func _is_scene_unloading() -> bool:
	var tree := _scene_tree()
	if tree == null:
		return true
	var scene := tree.current_scene
	if scene == null or not is_instance_valid(scene) or scene.is_queued_for_deletion():
		return true
	return false


# Persists all candidate IDs as defeated through the save manager.
func _log_gone() -> void:
	if _logged:
		return
	var save_mgr := _find_save_manager()
	if save_mgr == null or not save_mgr.has_method("register_entity_death"):
		return
	_logged = true
	for id in _candidate_ids():
		save_mgr.register_entity_death(id)


# Returns the active scene tree, falling back to the main loop when needed.
func _scene_tree() -> SceneTree:
	var tree := get_tree()
	if tree:
		return tree
	return Engine.get_main_loop() as SceneTree


# Finds the save manager node from group membership or the pause menu.
func _find_save_manager() -> Node:
	var tree := _scene_tree()
	if tree == null:
		return null
	var sm := tree.get_first_node_in_group("save_manager")
	if sm:
		return sm
	if tree.current_scene:
		return tree.current_scene.find_child("pause_menu", true, false)
	return null
