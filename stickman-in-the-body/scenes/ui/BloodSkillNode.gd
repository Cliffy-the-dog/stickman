extends SkillNode

@export var is_root_bloodbind: bool = false

func apply_skill_effect() -> void:
	if is_root_bloodbind:
		player.has_bloodbind = true
	else:
		player.damage_value += 5
