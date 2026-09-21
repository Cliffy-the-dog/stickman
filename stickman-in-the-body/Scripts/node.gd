extends Node

@onready var player: AudioStreamPlayer = $AudioStreamPlayer

const TRACK_BLOODBORN = preload("res://assets/audio/music/The Bloodborn.mp3")
const TRACK_FLOW = preload("res://assets/audio/music/Ambient for Apoptosis.wav")
const TRACK_HOARD1 = preload("res://assets/audio/music/Main 1.wav")
const TRACK_HOARD2 = preload("res://assets/audio/music/Main 2.wav")
const TRACK_HOARD_FALL = preload("res://assets/audio/music/Screen Recording 2026-05-01 091735.mp3")

var chasing_enemies: Array = []

enum MusicState { FLOW, CHASE, BOSS_P1, BOSS_P2, BOSS_FALLING }
var current_state: MusicState = MusicState.FLOW

var volume_multiplier: float = 1.0:
	set(value):
		volume_multiplier = value
		if player:
			player.volume_linear = volume_multiplier


# Connects track finished signal and starts ambient music.
func _ready() -> void:
	player.finished.connect(_on_track_finished)
	player.volume_linear = volume_multiplier
	play_music(TRACK_FLOW)


# Begins chase or boss music when an enemy starts pursuing the player.
func start_chase(enemy_id, is_boss: bool = false) -> void:
	if is_boss:
		current_state = MusicState.BOSS_P1
		play_music(TRACK_HOARD1)
	elif not chasing_enemies.has(enemy_id):
		chasing_enemies.append(enemy_id)
		if current_state == MusicState.FLOW:
			current_state = MusicState.CHASE
			play_music(TRACK_BLOODBORN)


# Ends chase or boss music when an enemy stops pursuing the player.
func stop_chase(enemy_id, is_boss: bool = false) -> void:
	if is_boss:
		current_state = MusicState.BOSS_FALLING
		play_music(TRACK_HOARD_FALL)
	elif chasing_enemies.has(enemy_id):
		chasing_enemies.erase(enemy_id)
		if chasing_enemies.is_empty() and current_state == MusicState.CHASE:
			current_state = MusicState.FLOW
			play_music(TRACK_FLOW)


# Advances boss phases or loops the current track when playback finishes.
func _on_track_finished() -> void:
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


# Switches to a new track with a fade-in to the current volume setting.
func play_music(track: AudioStream) -> void:
	if player.stream == track and player.playing:
		return

	player.stop()
	player.stream = track
	player.volume_linear = 0.0
	player.play()

	var fade = create_tween()
	fade.tween_property(player, "volume_linear", volume_multiplier, 1.0)
