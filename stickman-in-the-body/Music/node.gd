extends Node

@onready var player = $AudioStreamPlayer

const TRACK_BLOODBORN = preload("res://Music/The Bloodborn.mp3")
const TRACK_FLOW = preload("res://Music/Flow.mp3")

# This tracks which specific enemies are currently chasing
var chasing_enemies = []

func _ready():
	# Start with Flow on loop
	play_music(TRACK_FLOW)

func start_chase(enemy_id):
	if not chasing_enemies.has(enemy_id):
		chasing_enemies.append(enemy_id)
		play_music(TRACK_BLOODBORN)
		print("Enemy ", enemy_id, " started chase. Playing Bloodborn.")

func stop_chase(enemy_id):
	if chasing_enemies.has(enemy_id):
		chasing_enemies.erase(enemy_id)
		# Only switch back to Flow if NO ONE else is chasing
		if chasing_enemies.is_empty():
			play_music(TRACK_FLOW)
			print("All clear. Playing Flow.")

func play_music(track: AudioStream):
	if player.stream == track and player.playing:
		return # Already playing this track
	
	player.stop()
	player.stream = track
	player.volume_db = -20.0 
	player.play()
	
	var fade = create_tween()
	fade.tween_property(player, "volume_db", 0.0, 1.0)
