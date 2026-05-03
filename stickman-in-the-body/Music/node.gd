extends Node

@onready var player = $AudioStreamPlayer

const TRACK_BLOODBORN = preload("res://Music/The Bloodborn.mp3")
const TRACK_FLOW = preload("res://Music/Flow.mp3")
const TRACK_HOARD1 = preload("res://Music/Main 1.wav")
const TRACK_HOARD2 = preload("res://Music/Main 2.wav")
const TRACK_HOARD_FALL = preload("res://Music/Fall.mp3")

var chasing_enemies = []

enum MusicState { FLOW, CHASE, BOSS_P1, BOSS_P2, BOSS_FALLING }
var current_state = MusicState.FLOW

func _ready():
	player.finished.connect(_on_track_finished)
	play_music(TRACK_FLOW)

func start_chase(enemy_id, is_boss = false):
	if is_boss:
		current_state = MusicState.BOSS_P1
		play_music(TRACK_HOARD1)
	elif not chasing_enemies.has(enemy_id):
		chasing_enemies.append(enemy_id)
		# Only switch to Bloodborn if we aren't currently in a boss fight
		if current_state == MusicState.FLOW:
			current_state = MusicState.CHASE
			play_music(TRACK_BLOODBORN)

func stop_chase(enemy_id, is_boss = false):
	if is_boss:
		current_state = MusicState.BOSS_FALLING
		play_music(TRACK_HOARD_FALL)
	elif chasing_enemies.has(enemy_id):
		chasing_enemies.erase(enemy_id)
		# Return to Flow only if no one else is chasing and no boss is active
		if chasing_enemies.is_empty() and current_state == MusicState.CHASE:
			current_state = MusicState.FLOW
			play_music(TRACK_FLOW)

func _on_track_finished():
	match current_state:
		MusicState.BOSS_P1:
			current_state = MusicState.BOSS_P2
			play_music(TRACK_HOARD2)
		MusicState.BOSS_P2:
			play_music(TRACK_HOARD2) # Loop Hoard 2
		MusicState.BOSS_FALLING:
			current_state = MusicState.FLOW
			play_music(TRACK_FLOW)
		MusicState.CHASE:
			play_music(TRACK_BLOODBORN) # Loop Bloodborn

func play_music(track: AudioStream):
	if player.stream == track and player.playing:
		return
	
	player.stop()
	player.stream = track
	player.volume_db = -20.0 
	player.play()
	
	var fade = create_tween()
	fade.tween_property(player, "volume_db", 0.0, 1.0)
