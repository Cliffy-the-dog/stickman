extends ColorRect
class_name SkillNode

signal unlocked

## Unique skill ID — same strings used in the save file ("bloodbind", "walljump", "sprint", "healer_upgrade").
## Set this in the Inspector, like gauntlet_id on WaveSpawner.
@export_group("Skill Identity")
@export var skill_id: String = ""

@export_group("Unlock Action")
## Player method called when you click this node to buy/unlock it (e.g. "sprint", "blood_increase_1").
@export var player_method: String = ""
@export var skin_cost: int = 10
@export var pass_argument: bool = false
@export var method_argument: float = 0.0

@export_group("Tree Layout")
## Drag other skill nodes here. (Typed as Node because SkillNode cannot reference itself at parse time.)
@export var parent_nodes: Array[Node] = []
@export var child_nodes: Array[Node] = []
@export var line_width: float = 12.0

@export_group("Fallback Colors (no shader)")
@export var locked_color: Color = Color(0.2, 0.2, 0.2, 1.0)
@export var unlocked_color: Color = Color(0.1, 0.8, 0.3, 1.0)
@export var owned_color: Color = Color(1.0, 0.45, 0.0, 1.0)

var is_unlocked: bool = false:
	set(value):
		is_unlocked = value
		_update_visuals()

var is_owned: bool = false:
	set(value):
		is_owned = value
		_update_visuals()


# Prepares input handling, syncs player ownership, and builds connector lines.
func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	mouse_filter = Control.MOUSE_FILTER_STOP
	gui_input.connect(_on_gui_input)

	if material is ShaderMaterial:
		material = (material as ShaderMaterial).duplicate()

	sync_from_player()
	_update_visuals()
	call_deferred("rebuild_lines")


# Re-syncs visuals when the node becomes visible (e.g. opening the skills tab).
func _notification(what: int) -> void:
	if what == NOTIFICATION_VISIBILITY_CHANGED and is_visible_in_tree():
		sync_from_player()
		_update_visuals()


# Returns the center of this node in the skill canvas local space for line drawing.
func get_line_anchor() -> Vector2:
	return position + (size * 0.5)


# Pushes real-world time and state into this node's shader (called by InventoryControls).
func update_shader_time(time_sec: float) -> void:
	if material is ShaderMaterial:
		var shader_mat := material as ShaderMaterial
		shader_mat.set_shader_parameter("elapsed_time", time_sec)
		shader_mat.set_shader_parameter("u_time", time_sec)


# Reads the player's current skills and marks this node as owned when applicable.
func sync_from_player() -> void:
	var player_node := get_player()
	if not player_node or skill_id.is_empty():
		return
	is_owned = _player_has_skill_id(player_node, skill_id)
	if is_owned:
		is_unlocked = true
	_update_visuals()


# Handles left-click to purchase/unlock this node when prerequisites are met.
func _on_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		if is_owned:
			return
		if not is_unlocked and can_unlock():
			unlock()


# Updates node tint and shader uniforms for locked / tree-unlocked / owned states.
func _update_visuals() -> void:
	if material is ShaderMaterial:
		color = Color.WHITE
		var shader_mat := material as ShaderMaterial
		shader_mat.set_shader_parameter("is_owned", is_owned)
		shader_mat.set_shader_parameter("is_unlocked", is_unlocked or is_owned)
	else:
		if is_owned:
			color = owned_color
		elif is_unlocked:
			color = unlocked_color
		else:
			color = locked_color

	rebuild_lines()


# Rebuilds connector lines on the shared SkillLines control layer.
func rebuild_lines() -> void:
	var line_layer := _get_line_layer()
	if line_layer and line_layer.has_method("rebuild_all"):
		line_layer.rebuild_all()


# Returns true when this node has no valid parents (root of its branch).
func is_root_node() -> bool:
	return _get_valid_parent_nodes().is_empty()


# Returns true if this node may be unlocked (roots always can, others need a unlocked parent).
func can_unlock() -> bool:
	if is_root_node():
		return true
	for parent_node in _get_valid_parent_nodes():
		if parent_node is SkillNode:
			var parent := parent_node as SkillNode
			if parent.is_unlocked or parent.is_owned:
				return true
	return false


# Marks this node unlocked, applies the skill, and refreshes visuals/lines.
func unlock() -> void:
	if player_method.is_empty() and not skill_id.is_empty():
		push_warning("SkillNode '%s': assign player_method in the Inspector." % name)
		return

	var player_node := get_player()
	if player_node and skin_cost > 0 and player_node.has_method("spend_skins"):
		if not player_node.spend_skins(skin_cost):
			return

	is_unlocked = true
	is_owned = true

	apply_skill_effect()
	unlocked.emit()
	_update_visuals()
	rebuild_lines()

	var save_manager := get_tree().get_first_node_in_group("save_manager")
	if save_manager and save_manager.has_method("save_game"):
		save_manager.save_game()


# Calls the configured player method when this node is unlocked from the tree.
func apply_skill_effect() -> void:
	var player_node := get_player()
	if not player_node:
		push_error("SkillNode: Player node not found!")
		return

	if player_method.is_empty():
		return

	if player_node.has_method(player_method):
		if pass_argument:
			player_node.call(player_method, method_argument)
		else:
			player_node.call(player_method)
	else:
		push_error("SkillNode: Player script is missing the method '%s'" % player_method)


# Returns the player node from the "player" group, walking up the tree as fallback.
func get_player() -> Node:
	var grouped := get_tree().get_first_node_in_group("player")
	if grouped:
		return grouped

	var current: Node = self
	while current:
		if current is CharacterBody2D and current.has_method("spend_skins"):
			return current
		current = current.get_parent()
	return null


# Returns the SkillLines draw layer under the skill tree canvas.
func _get_line_layer() -> Control:
	var canvas := get_parent()
	if canvas == null:
		return null
	var layer := canvas.get_node_or_null("SkillLines")
	if layer is Control:
		return layer
	return null


# Shows or hides connector lines (called when the skills tab opens/closes).
func set_lines_visible(should_show: bool) -> void:
	var line_layer := _get_line_layer()
	if line_layer:
		line_layer.visible = should_show


# Filters parent_nodes down to valid SkillNode references.
func _get_valid_parent_nodes() -> Array[Node]:
	var valid: Array[Node] = []
	for parent_node in parent_nodes:
		if parent_node is SkillNode:
			valid.append(parent_node)
	return valid


# Checks whether the player already has a skill matching skill_id.
func _player_has_skill_id(player_node: Node, id: String) -> bool:
	match id:
		"bloodbind":
			return player_node.get("has_bloodbind") == true
		"walljump":
			return player_node.get("has_walljump") == true
		"sprint":
			return player_node.get("has_sprint_unlocked") == true
		"healer_upgrade":
			return player_node.get("has_healer_health_upgrade") == true
		_:
			return false
