extends Line2D
class_name SkillLine

var is_unlocked: bool = false:
	set(value):
		is_unlocked = value
		_update_shader()


# Ensures the line processes while paused and applies initial shader state.
func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_update_shader()


# Pushes real-world time into the line shader (called by InventoryControls).
func update_shader_time(time_sec: float) -> void:
	if material is ShaderMaterial:
		(material as ShaderMaterial).set_shader_parameter("u_time", time_sec)


# Syncs the unlock state uniform on the line's shader material.
func _update_shader() -> void:
	if material is ShaderMaterial:
		(material as ShaderMaterial).set_shader_parameter("is_unlocked", is_unlocked)
