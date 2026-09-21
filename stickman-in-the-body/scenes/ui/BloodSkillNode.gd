extends SkillNode
class_name BloodSkillNode

@export var unlocks_lifesteal: bool = false
@export var lifesteal_bonus: float = 0.05

## Applies lifesteal unlock or bonus to the player when this node is unlocked.
func apply_skill_effect() -> void:
	var player := get_player()
	if not player:
		return

	if unlocks_lifesteal:
		player.has_lifesteal = true
	else:
		player.lifesteal_amount += lifesteal_bonus
