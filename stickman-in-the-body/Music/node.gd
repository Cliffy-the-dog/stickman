extends Node

@onready var player = $AudioStreamPlayer
var chasing_enemies = []
var current_track_type = ""

func _process(_delta):
	var target_type = "battle" if chasing_enemies.size() > 0 else "ambient"
	
	if current_track_type != target_type:
		current_track_type = target_type
		change_music_with_fade(target_type)

func change_music_with_fade(type):
	var new_track = preload("res://Music/Flow.mp3")
	if type == "battle":
		new_track = preload("res://Music/The Bloodborn.mp3")

	# 1. Create a Tween to fade out
	var fade_out = create_tween()
	fade_out.tween_property(player, "volume_db", -80, 1.0) # Fade to silent over 1s
	
	# 2. After fading out, change the song and fade back in
	fade_out.tween_callback(func():
		player.stream = new_track
		player.play()
	)
	
	# 3. Create a Tween to fade back in
	var fade_in = create_tween()
	fade_in.tween_property(player, "volume_db", 0.0, 1.0) 

func start_chase(enemy_id):
	if not chasing_enemies.has(enemy_id):
		chasing_enemies.append(enemy_id)

func stop_chase(enemy_id):
	chasing_enemies.erase(enemy_id)
	
