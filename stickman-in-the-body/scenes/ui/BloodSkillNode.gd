extends SkillNode
class_name BloodSkillNode

@export var unlocks_lifesteal: bool = false
@export var lifesteal_bonus: float = 0.05

func apply_skill_effect() -> void:
	var player = get_player()
	if not player:
		return

	if unlocks_lifesteal:
		player.has_lifesteal = true
	else:
		player.lifesteal_amount += lifesteal_bonus
