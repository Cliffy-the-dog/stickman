class_name SkillNode
extends ColorRect

# --- Child Panel Reference ---
@onready var panel: Control = $Panel

# --- Exports ---
@export var parent_node: SkillNode = null # Leave empty for Root Nodes
@export var cost: float = 50.0

# --- Visual Settings ---
@export var color_locked: Color = Color(0.2, 0.2, 0.2, 0.8)
@export var color_available: Color = Color(0.8, 0.6, 0.2, 1.0)
@export var color_unlocked: Color = Color(0.2, 0.8, 0.3, 1.0)

# --- Connection Line Settings ---
@export var draw_connection_line: bool = true
@export var line_width: float = 4.0

var is_unlocked: bool = false
var player: CharacterBody2D = null
var connection_line: Line2D = null

func _ready() -> void:
	player = %Player if has_node("%Player") else get_tree().get_first_node_in_group("player")
	gui_input.connect(_on_gui_input)
	
	call_deferred("_setup_line")
	call_deferred("update_visuals")

func _process(_delta: float) -> void:
	# Updates shader uniforms
	if material is ShaderMaterial:
		var real_time: float = Time.get_ticks_msec() / 1000.0
		(material as ShaderMaterial).set_shader_parameter("elapsed_time", real_time)

func can_unlock() -> bool:
	if is_unlocked:
		return false
	if parent_node != null and not parent_node.is_unlocked:
		return false
	return true

func try_buy() -> void:
	if not can_unlock() or player == null:
		return
		
	if player.money >= cost:
		player.money -= cost
		unlock_skill()

func unlock_skill() -> void:
	is_unlocked = true
	update_visuals()
	apply_skill_effect()
	
	# Refresh child nodes
	for child in get_tree().get_nodes_in_group("skill_nodes"):
		if child is SkillNode and child.parent_node == self:
			child.update_visuals()

func apply_skill_effect() -> void:
	pass

func update_visuals() -> void:
	var target_color: Color = color_locked
	
	if is_unlocked:
		target_color = color_unlocked
	elif can_unlock():
		target_color = color_available

	if panel:
		panel.modulate = target_color
		
	_update_line(target_color)

func _setup_line() -> void:
	if parent_node == null or not draw_connection_line:
		return
		
	connection_line = Line2D.new()
	connection_line.width = line_width
	connection_line.top_level = true # Uses global screen space
	connection_line.z_index = -1 # Renders behind skill panels
	add_child(connection_line)
	
	_update_line(color_locked)

func _update_line(current_color: Color) -> void:
	if connection_line == null or parent_node == null:
		return
		
	var start_pos: Vector2 = parent_node.global_position + (parent_node.size / 2.0)
	var end_pos: Vector2 = global_position + (size / 2.0)
	
	connection_line.clear_points()
	connection_line.add_point(start_pos)
	connection_line.add_point(end_pos)
	connection_line.default_color = current_color

func _on_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		try_buy()
