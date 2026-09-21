extends Control

@onready var startup: VideoStreamPlayer = $VideoStreamPlayer

const MAIN_MENU_PATH := "res://scenes/levels/MainMenu.tscn"

var _transition_started := false
var _video_has_started := false


# Starts background loading of the main menu while the startup video plays.
func _ready() -> void:
	ResourceLoader.load_threaded_request(MAIN_MENU_PATH)
	if not startup.finished.is_connected(_on_video_finished):
		startup.finished.connect(_on_video_finished)


# Fallback when VideoStreamPlayer never emits finished (common with some .ogv files).
func _process(_delta: float) -> void:
	if _transition_started:
		return
	if startup.is_playing():
		_video_has_started = true
	elif _video_has_started:
		_go_to_main_menu()


# Stops the video and transitions to the preloaded main menu scene.
func _on_video_finished() -> void:
	_go_to_main_menu()


# Waits for threaded preload if needed, then switches to the main menu.
func _go_to_main_menu() -> void:
	if _transition_started:
		return
	_transition_started = true

	startup.stop()

	var status := ResourceLoader.load_threaded_get_status(MAIN_MENU_PATH)
	while status == ResourceLoader.THREAD_LOAD_IN_PROGRESS:
		await get_tree().process_frame
		status = ResourceLoader.load_threaded_get_status(MAIN_MENU_PATH)

	if status == ResourceLoader.THREAD_LOAD_LOADED:
		var packed_scene := ResourceLoader.load_threaded_get(MAIN_MENU_PATH) as PackedScene
		get_tree().change_scene_to_packed(packed_scene)
		return

	var err := get_tree().change_scene_to_file(MAIN_MENU_PATH)
	if err != OK:
		push_error("StartupScreen: failed to load main menu at %s (error %s)" % [MAIN_MENU_PATH, err])
