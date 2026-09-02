extends Area2D

@export var LockedWall: Node2D
@export var follow_offset: Vector2 = Vector2(80, -20)

var is_following: bool = false
var player_ref: Node2D = null

func _ready() -> void:
	# Force-connect signals in code so you don't have to rely on editor connections
	if not body_entered.is_connected(_on_body_entered):
		body_entered.connect(_on_body_entered)
	if not area_entered.is_connected(_on_area_entered):
		area_entered.connect(_on_area_entered)

func _process(delta: float) -> void:
	if is_following and is_instance_valid(player_ref) and is_instance_valid(LockedWall):
		var facing = 1.0
		if "facing_direction" in player_ref:
			facing = player_ref.facing_direction
		
		var target_pos = player_ref.global_position + Vector2(follow_offset.x * facing, follow_offset.y)
		global_position = global_position.lerp(target_pos, 15.0 * delta)
		look_at(LockedWall.global_position)

func _on_body_entered(body: Node2D) -> void:
	# 1. Door Unlock
	if body == LockedWall or (LockedWall and body.get_parent() == LockedWall):
		LockedWall.queue_free()
		queue_free()
		return
		
	# 2. Player Pick Up (Direct CharacterBody2D detection)
	if not is_following and (body is CharacterBody2D or body.is_in_group("player")):
		is_following = true
		player_ref = body

func _on_area_entered(area: Area2D) -> void:
	# 1. Door Unlock
	if area == LockedWall or (LockedWall and area.get_parent() == LockedWall):
		LockedWall.queue_free()
		queue_free()
		return
		
	# 2. Player Pick Up (Hitbox/Hurtbox detection)
	if not is_following:
		var parent = area.get_parent()
		if parent and (parent is CharacterBody2D or parent.is_in_group("player")):
			is_following = true
			player_ref = parent
