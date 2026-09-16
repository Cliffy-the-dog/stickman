extends SkillNode

@export var is_root_walljump: bool = false

func apply_skill_effect() -> void:
	if is_root_walljump:
		player.has_walljump = true
	else:
		player.SPEED += 200.0
