extends AnimatedSprite2D

@onready var label: Label = $Area2D/CollisionShape2D/Label
@onready var TxtBg: ColorRect = $"../DirectionalLight2D/Management/Player/Camera2D2/ColorRect2"
@onready var Txt: RichTextLabel = $"../DirectionalLight2D/Management/Player/Camera2D2/ColorRect2/RichTextLabel"
@onready var player: CharacterBody2D = %Player

var in_dialog = false
var colliding = false
var must_leave_area = false 

signal interact_pressed

func _ready() -> void:
	Txt.hide(); TxtBg.hide()

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("Interact"):
		if in_dialog: interact_pressed.emit()
		elif colliding and not must_leave_area: start_dialogue()

func _physics_process(_delta: float) -> void:
	if not is_playing(): play("Anim")
	label.visible = (not in_dialog and colliding and not must_leave_area)

func start_dialogue() -> void:
	in_dialog = true; player.SPEED = 0
	Txt.show(); TxtBg.show()
	
	# Walljump giver has no choices, so we sweep the UI and hide ANY buttons
	for child in TxtBg.get_children():
		if child is Button:
			child.hide()
	
	if player.has_walljump:
		Txt.text = "Go on, try it out, hop on a wall and keep jumping!"
		await get_tree().create_timer(0.1).timeout; await interact_pressed 
	else:
		var lines = [
			"Yo, you. I'm kinda dying here, and there's no way to go back down.",
			"My technique would be wasted on me. Take it. You look like you have a grudge against the plague that's killin' the lot of us. Go on, use it to ascend.",
			"You should be able to wall jump now. Scat."
		]
		for line in lines:
			Txt.text = line
			await get_tree().create_timer(0.1).timeout; await interact_pressed 
		player.has_walljump = true
	
	must_leave_area = true 
	Txt.hide(); TxtBg.hide()
	player.SPEED = 1200; in_dialog = false

func _on_area_2d_body_entered(body: Node2D) -> void: if body.has_method("flash_red"): colliding = true
func _on_area_2d_body_exited(body: Node2D) -> void: if body.has_method("flash_red"): colliding = false; must_leave_area = false
