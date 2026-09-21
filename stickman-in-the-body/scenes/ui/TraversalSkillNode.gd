extends SkillNode
class_name TraversalSkillNode

@export var unlocks_wall_jump: bool = false
@export var speed_bonus: float = 50.0

## Unlocks wall jump or adds a movement speed bonus when this node is unlocked.
func apply_skill_effect() -> void:
	var player := get_player()
	if not player:
		return

	if unlocks_wall_jump:
		player.can_wall_jump = true
	else:
		player.speed += speed_bonus
