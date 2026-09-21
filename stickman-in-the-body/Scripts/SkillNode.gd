extends ColorRect
class_name SkillNode

signal unlocked

@export_category("Custom Player Skill Call")
@export var function_name: String = ""
@export var function_argument: float = 0.0
@export var pass_argument: bool = false

@export_category("Node Connections")
@export var is_unlocked: bool = false:
	set(value):
		is_unlocked = value
		_update_visuals()

@export var locked_color: Color = Color(0.2, 0.2, 0.2, 1.0)
@export var unlocked_color: Color = Color(0.1, 0.8, 0.3, 1.0)

@export var parent_nodes: Array[SkillNode] = []
@export var child_nodes: Array[SkillNode] = []
@export var line_shader: ShaderMaterial
@export var line_width: float = 16.0

var generated_lines: Array[SkillLine] = []

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	mouse_filter = Control.MOUSE_FILTER_STOP
	gui_input.connect(_on_gui_input)
	
	_update_visuals()
	_setup_lines.call_deferred()

func _on_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		if not is_unlocked and can_unlock():
			unlock()

func _update_visuals() -> void:
	color = unlocked_color if is_unlocked else locked_color

func _setup_lines() -> void:
	await get_tree().process_frame
	
	for child in child_nodes:
		if not child:
			continue
		
		var line = SkillLine.new()
		line.width = line_width
		line.top_level = true
		line.z_index = z_index - 1
		
		if line_shader:
			line.material = line_shader.duplicate()
		
		var start_pos = global_position + (size * 0.5)
		var end_pos = child.global_position + (child.size * 0.5)
		
		line.add_point(start_pos)
		line.add_point(end_pos)
		line.is_unlocked = is_unlocked
		
		get_tree().current_scene.add_child(line)
		generated_lines.append(line)

func can_unlock() -> bool:
	if parent_nodes.is_empty():
		return true
	for parent in parent_nodes:
		if parent.is_unlocked:
			return true
	return false

func unlock() -> void:
	is_unlocked = true
	
	for line in generated_lines:
		line.is_unlocked = true
		
	apply_skill_effect()
	unlocked.emit()

func apply_skill_effect() -> void:
	var player = get_tree().get_first_node_in_group("player")
	if not player:
		push_error("SkillNode: Player node not found in 'player' group!")
		return

	if function_name.is_empty():
		push_warning("SkillNode: No function_name assigned on " + name)
		return

	if player.has_method(function_name):
		if pass_argument:
			player.call(function_name, function_argument)
		else:
			player.call(function_name)
	else:
		push_error("SkillNode: Player script is missing the function '" + function_name + "'")
