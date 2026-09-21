extends Control

@onready var Sun: DirectionalLight2D = $"../../../.."
@onready var brightness: HSlider = $Control/VBoxContainer/Brightness
@onready var volume: HSlider = $Control/VBoxContainer/Volume
@onready var music_manager: Node = %MusicManager

var local_brightness: float
var local_volume: float


# Hides the menu and sets default brightness and volume values.
func _ready() -> void:
	hide()
	brightness.value = 0
	Sun.color = Color(0, 0, 0)
	volume.value = 1


# Opens the menu on pause and closes it after a second pause press.
func _process(_delta: float) -> void:
	if Input.is_action_just_pressed("Pause"):
		show()
		await get_tree().create_timer(0.15).timeout
		await Input.is_action_just_pressed("Pause")
		hide()


# Applies the volume slider value to the music manager.
func _on_volume_value_changed(value: float) -> void:
	local_volume = volume.value
	music_manager.volume_multiplier = local_volume


# Applies the brightness slider value to the scene light color.
func _on_brightness_value_changed(value: float) -> void:
	local_brightness = brightness.value
	Sun.color = Color(brightness.value, brightness.value, brightness.value)
