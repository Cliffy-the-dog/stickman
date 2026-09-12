extends ColorRect

func _process(_delta: float) -> void:
	# Time.get_ticks_msec() returns real-world milliseconds passed since game launch
	# Dividing by 1000.0 converts it to seconds matching Godot's built-in TIME scale
	var real_time: float = Time.get_ticks_msec() / 1000.0
	
	# Pass the value into the custom uniform
	(material as ShaderMaterial).set_shader_parameter("elapsed_time", real_time)
