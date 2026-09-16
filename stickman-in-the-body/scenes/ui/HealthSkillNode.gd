extends SkillNode

@export var is_root_health: bool = false

func apply_skill_effect() -> void:
	player.health_upgrades += 1
	player.max_health = 100 + (20 * player.health_upgrades)
	
	if is_instance_valid(player.healthbar):
		player.healthbar.max_value = player.max_health
		player.healthbar.value = player.max_health
