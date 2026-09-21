extends Area2D

@export var LockedWall: Node2D
@export var wall_id: String = "wall_1"

var is_following: bool = false
var player_ref: Node2D = null
var key_sprite: Node = null

func _ready() -> void:
	# Cache the sprite reference once on load
	key_sprite = find_child("*Sprite*", true, false)
	if not key_sprite:
		key_sprite = get_node_or_null("Sprite2D") # Fallback to standard node name
	
	if not body_entered.is_connected(_on_body_entered):
		body_entered.connect(_on_body_entered)
	if not area_entered.is_connected(_on_area_entered):
		area_entered.connect(_on_area_entered)
		
	call_deferred("_check_persistence_on_load")

func _check_persistence_on_load() -> void:
	if wall_id.strip_edges() == "":
		return
	var save_mgr = _find_save_manager()
	if not save_mgr:
		return
	if "defeated_entity_ids" in save_mgr:
		if wall_id in save_mgr.defeated_entity_ids:
			if is_instance_valid(LockedWall):
				LockedWall.queue_free()
			queue_free()

func _process(delta: float) -> void:
	if is_following and is_instance_valid(player_ref):
		var facing = _get_player_facing_dir() # Returns -1.0 (left) or 1.0 (right)
		
		# Offset positions relative to player facing side
		var offset = Vector2(facing * 40.0, -16.0)
		var target_pos = player_ref.global_position + offset

		global_position = global_position.lerp(target_pos, 15.0 * delta)
		
		# If pointing at a wall, use look_at; otherwise use horizontal sprite flipping
		if is_instance_valid(LockedWall):
			look_at(LockedWall.global_position)
		elif is_instance_valid(key_sprite) and "flip_h" in key_sprite:
			rotation = 0.0 # Reset node rotation when not aiming at door
			key_sprite.flip_h = (facing < 0.0)

func _get_player_facing_dir() -> float:
	if not is_instance_valid(player_ref):
		return 1.0

	# 1. Check custom variables on player script
	for var_name in ["facing_direction", "facing_dir", "facing", "dir"]:
		if var_name in player_ref:
			var val = player_ref.get(var_name)
			if val is Vector2 and val.x != 0:
				return 1.0 if val.x > 0 else -1.0
			elif (val is float or val is int) and val != 0:
				return 1.0 if val > 0 else -1.0

	# 2. Check Node scale
	if player_ref.scale.x < 0 or player_ref.global_transform.x.x < 0:
		return -1.0

	# 3. Check Sprite flip status
	var sprite = player_ref.find_child("*Sprite*", true, false)
	if sprite and "flip_h" in sprite:
		return -1.0 if sprite.flip_h else 1.0

	# 4. Fallback to velocity
	if "velocity" in player_ref and abs(player_ref.velocity.x) > 0.1:
		return 1.0 if player_ref.velocity.x > 0 else -1.0

	return 1.0

func _on_body_entered(body: Node2D) -> void:
	if _is_target_door(body):
		unlock_door(body)
		return
		
	if not is_following:
		var p = _find_player(body)
		if p:
			is_following = true
			player_ref = p

func _on_area_entered(area: Area2D) -> void:
	if _is_target_door(area):
		unlock_door(area)
		return
		
	if not is_following:
		var p = _find_player(area)
		if p:
			is_following = true
			player_ref = p

func _is_target_door(node: Node2D) -> bool:
	if not is_instance_valid(node):
		return false
	if is_instance_valid(LockedWall):
		if node == LockedWall or LockedWall.is_ancestor_of(node):
			return true
	if wall_id.strip_edges() != "":
		if node.name == wall_id or ("entity_id" in node and node.entity_id == wall_id):
			return true
	return false

func _find_player(node: Node) -> Node2D:
	var current = node
	while current != null:
		if current.is_in_group("player") or current.has_method("flash_red"):
			return current as Node2D
		current = current.get_parent()
	return null

func unlock_door(door_node: Node2D = null) -> void:
	set_deferred("monitoring", false)
	set_deferred("monitorable", false)
	
	var save_mgr = _find_save_manager()
	if save_mgr and wall_id.strip_edges() != "":
		if save_mgr.has_method("register_entity_death"):
			save_mgr.register_entity_death(wall_id)
			
	var target_door = LockedWall if is_instance_valid(LockedWall) else door_node
	if is_instance_valid(target_door):
		var wall_collider = target_door.find_child("CollisionShape2D", true, false)
		if wall_collider:
			wall_collider.set_deferred("disabled", true)
		target_door.queue_free()
		
	queue_free()

func _find_save_manager() -> Node:
	var sm = get_tree().get_first_node_in_group("save_manager")
	if sm:
		return sm
	var path_pm = get_node_or_null("../../Management/Player/Camera2D2/pause_menu")
	if path_pm:
		return path_pm
	return get_tree().current_scene.find_child("pause_menu", true, false)
