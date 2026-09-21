extends Line2D
class_name SkillLine

var is_unlocked: bool = false:
	set(value):
		is_unlocked = value
		_update_shader()

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_update_shader()

func _process(_delta: float) -> void:
	if material is ShaderMaterial:
		# Use unpaused system time
		var real_time = Time.get_ticks_msec() / 1000.0
		(material as ShaderMaterial).set_shader_parameter("u_time", real_time)

func _update_shader() -> void:
	if material is ShaderMaterial:
		(material as ShaderMaterial).set_shader_parameter("is_unlocked", is_unlocked)
