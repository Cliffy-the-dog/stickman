extends SkillNode
class_name HealthSkillNode

@export var max_hp_bonus: float = 25.0
@export var health_regen_bonus: float = 2.0

## Increases the player's max HP, current HP, and health regen when unlocked.
func apply_skill_effect() -> void:
	var player := get_player()
	if not player:
		return

	player.max_health += max_hp_bonus
	player.current_health += max_hp_bonus
	if "health_regen_rate" in player:
		player.health_regen_rate += health_regen_bonus
