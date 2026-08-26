extends Area2D

@export var speed: float = 800.0
@export var max_distance: float = 400.0
@export var damage: int = 50

# --- AUDIO VOLUME EXPORTS ---
@export_range(-80.0, 24.0, 0.1) var chain_toss_volume_db: float = 0.0
@export_range(-80.0, 24.0, 0.1) var punch_volume_db: float = 0.0

var direction := Vector2.ZERO
var player_ref: Node2D = null
var distance_traveled: float = 0.0
var is_returning: bool = false
var is_flipped: bool = false
var is_punching: bool = false 

var caught_targets: Array = []
@onready var chain_line: Line2D = $Line2D

# Audio Players
var chain_audio_player: AudioStreamPlayer2D
var punch_audio_player: AudioStreamPlayer2D

func _ready() -> void:
	texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED
	
	if has_node("AnimatedSprite2D"):
		$AnimatedSprite2D.flip_h = is_flipped
	elif has_node("Sprite2D"):
		$Sprite2D.flip_h = is_flipped
		
	setup_audio_players()

func setup_audio_players() -> void:
	chain_audio_player = AudioStreamPlayer2D.new()
	chain_audio_player.stream = load("res://Music/ChainToss.mp3")
	chain_audio_player.volume_db = chain_toss_volume_db
	chain_audio_player.autoplay = true
	add_child(chain_audio_player)
	
	punch_audio_player = AudioStreamPlayer2D.new()
	punch_audio_player.stream = load("res://Music/Punch.mp3")
	punch_audio_player.volume_db = punch_volume_db
	add_child(punch_audio_player)

func _physics_process(delta: float) -> void:
	if not is_returning:
		var step = direction * speed * delta
		global_position += step
		distance_traveled += step.length()
		
		if distance_traveled >= max_distance:
			is_returning = true
			if is_instance_valid(player_ref):
				player_ref.anim_player.play("Reeling") # FIXED
	else:
		if is_instance_valid(player_ref):
			if not is_punching:
				direction = (player_ref.global_position - global_position).normalized()
				global_position += direction * speed * delta
				
				# Check distance to player
				if global_position.distance_to(player_ref.global_position) < 300.0:
					is_punching = true
					
					# --- MODIFIED: Only punch if we actually caught targets ---
					if caught_targets.size() > 0:
						trigger_punch()
					else:
						trigger_miss_cleanup()
		else:
			cleanup()
			queue_free()

	for target in caught_targets:
		if is_instance_valid(target):
			target.global_position = target.global_position.lerp(global_position, 0.5)

	update_chain_trail()

func trigger_punch() -> void:
	# 1. Stop the chain sound immediately as the projectile returns
	if is_instance_valid(chain_audio_player):
		chain_audio_player.stop()

	# 2. Start the visual winding-up punch animation
	if is_instance_valid(player_ref):
		player_ref.anim_player.play("Bloodpunch") # FIXED
		
	# 3. Apply the cinematic delay pause (or switch to animation_finished)
	await get_tree().create_timer(0.4).timeout 
	
	# ========================================================
	# 4. THE IMPACT: Play the punch sound effect NOW
	# ========================================================
	if is_instance_valid(punch_audio_player):
		punch_audio_player.play()

	# 5. Apply the knockback forces right as the sound hits
	if is_instance_valid(player_ref):
		for target in caught_targets:
			if is_instance_valid(target) and target.has_method("apply_knockback"):
				var push_dir = sign(target.global_position.x - player_ref.global_position.x)
				if push_dir == 0:
					push_dir = -1.0 if player_ref.visuals.scale.x < 0 else 1.0 # FIXED
					
				target.apply_knockback(Vector2(push_dir * 2400.0, -800.0))
		
		player_ref.finish_bloodbind()
	
	# 6. Keep the node alive long enough for the punch sound to finish playing
	if is_instance_valid(punch_audio_player) and punch_audio_player.playing:
		hide() 
		if chain_line: chain_line.queue_free()
		set_physics_process(false)
		await punch_audio_player.finished
		
	queue_free()

# --- NEW: Safely handles unlocking the player without playing any effects ---
func trigger_miss_cleanup() -> void:
	if is_instance_valid(chain_audio_player):
		chain_audio_player.stop()
		
	if is_instance_valid(player_ref):
		player_ref.trigger_endlag_punishment()
		
	cleanup()
	queue_free()

func update_chain_trail() -> void:
	if chain_line and is_instance_valid(player_ref):
		if chain_line.points.size() != 2:
			chain_line.clear_points()
			chain_line.add_point(Vector2.ZERO)
			chain_line.add_point(Vector2.ZERO)
		
		chain_line.set_point_position(0, chain_line.to_local(player_ref.global_position))
		chain_line.set_point_position(1, chain_line.to_local(global_position))

func cleanup() -> void:
	if chain_line: chain_line.queue_free()

func _on_body_entered(body: Node2D) -> void:
	if body == player_ref:
		return
		
	if body.has_method("take_damage") and not body in caught_targets:
		body.take_damage(damage)
		caught_targets.append(body)
