extends Node

@onready var player: AudioStreamPlayer = $AudioStreamPlayer

const TRACK_BLOODBORN = preload("res://assets/audio/music/The Bloodborn.mp3")
const TRACK_FLOW = preload("res://assets/audio/music//Flow.mp3")
const TRACK_HOARD1 = preload("res://assets/audio/music//Main 1.wav")
const TRACK_HOARD2 = preload("res://assets/audio/music//Main 2.wav")
const TRACK_HOARD_FALL = preload("res://assets/audio/music/Screen Recording 2026-05-01 091735.mp3")

var chasing_enemies = []

enum MusicState { FLOW, CHASE, BOSS_P1, BOSS_P2, BOSS_FALLING }
var current_state = MusicState.FLOW

# This variable is updated by your slider script
var volume_multiplier: float = 1.0:
	set(value):
		volume_multiplier = value
		# Instantly apply the new volume to the player
		if player:
			player.volume_linear = volume_multiplier

func _ready():
	player.finished.connect(_on_track_finished)
	# Set initial volume
	player.volume_linear = volume_multiplier
	play_music(TRACK_FLOW)

# --- CHASE LOGIC ---
func start_chase(enemy_id, is_boss = false):
	if is_boss:
		current_state = MusicState.BOSS_P1
		play_music(TRACK_HOARD1)
	elif not chasing_enemies.has(enemy_id):
		chasing_enemies.append(enemy_id)
		if current_state == MusicState.FLOW:
			current_state = MusicState.CHASE
			play_music(TRACK_BLOODBORN)

func stop_chase(enemy_id, is_boss = false):
	if is_boss:
		current_state = MusicState.BOSS_FALLING
		play_music(TRACK_HOARD_FALL)
	elif chasing_enemies.has(enemy_id):
		chasing_enemies.erase(enemy_id)
		if chasing_enemies.is_empty() and current_state == MusicState.CHASE:
			current_state = MusicState.FLOW
			play_music(TRACK_FLOW)

func _on_track_finished():
	match current_state:
		MusicState.BOSS_P1:
			current_state = MusicState.BOSS_P2
			play_music(TRACK_HOARD2)
		MusicState.BOSS_P2:
			play_music(TRACK_HOARD2) 
		MusicState.BOSS_FALLING:
			current_state = MusicState.FLOW
			play_music(TRACK_FLOW)
		MusicState.CHASE:
			play_music(TRACK_BLOODBORN)

# --- CORE PLAY FUNCTION ---
func play_music(track: AudioStream):
	if player.stream == track and player.playing:
		return
	
	player.stop()
	player.stream = track
	
	# Start at 0 volume for the fade-in effect
	player.volume_linear = 0.0 
	player.play()
	
	# Fade volume up to the current setting
	var fade = create_tween()
	fade.tween_property(player, "volume_linear", volume_multiplier, 1.0)
