extends Control

@onready var canvas_modulate: CanvasModulate = $"../../../.."
@onready var volume: HSlider = $Control/Volume
@onready var brightness: HSlider = $Control/Brightness
@onready var music_manager: Node = %MusicManager
@onready var button: Button = $Control/Button


var notshown = false

func _ready() -> void:
	hide()
	canvas_modulate.color = Color(1,1,1)
	brightness.value = 1
	volume.value = 1

var local_brightness
var local_volume

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if Input.is_action_just_pressed("Pause"):
		show()
		await get_tree().create_timer(0.15).timeout
		await Input.is_action_just_pressed("Pause")
		hide()




func _on_volume_value_changed(value: float) -> void:
	local_volume = volume.value
	music_manager.volume_multiplier = local_volume


func _on_brightness_value_changed(value: float) -> void:
	local_brightness = brightness.value
	canvas_modulate.color = Color(local_brightness,local_brightness , local_brightness)
