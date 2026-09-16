extends Control

@onready var startup: VideoStreamPlayer = $VideoStreamPlayer
var main_menu_path: String = "res://Scenes/levels/MainMenu.tscn"

func _ready() -> void:
	# Start background loading MainMenu immediately while video plays
	ResourceLoader.load_threaded_request(main_menu_path)
	startup.finished.connect(_on_video_finished)

func _on_video_finished() -> void:
	# Stop and free video player resources
	startup.stop()
	
	# Check if the scene finished background loading
	if ResourceLoader.load_threaded_get_status(main_menu_path) == ResourceLoader.THREAD_LOAD_LOADED:
		var packed_scene = ResourceLoader.load_threaded_get(main_menu_path) as PackedScene
		get_tree().change_scene_to_packed(packed_scene)
	else:
		# Fallback if the video was shorter than the load time
		get_tree().change_scene_to_file(main_menu_path)
