extends AnimatedSprite2D

@onready var label: Label = $Area2D/CollisionShape2D/Label
@onready var TxtBg: ColorRect = $"../DirectionalLight2D/Management/Player/Camera2D2/ColorRect2"
@onready var Txt: RichTextLabel = $"../DirectionalLight2D/Management/Player/Camera2D2/ColorRect2/RichTextLabel"

@onready var accept: Button = TxtBg.get_node("Accept")
@onready var decline: Button = TxtBg.get_node("Decline")
# Hide extra buttons to prevent UI overlap
@onready var button_3: Button = TxtBg.get_node_or_null("Button3")
@onready var button_4: Button = TxtBg.get_node_or_null("Button4")
@onready var button_5: Button = TxtBg.get_node_or_null("Button5")

@onready var player: CharacterBody2D = %Player

var in_dialog = false
var colliding = false
var must_leave_area = false 

signal interact_pressed
signal choice_made(accepted: bool)

func _ready() -> void:
	for ui in [Txt, TxtBg, accept, decline, button_3, button_4, button_5]: 
		if ui: ui.hide()
	
	Txt.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	accept.pressed.connect(func(): choice_made.emit(true))
	decline.pressed.connect(func(): choice_made.emit(false))

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("Interact"):
		if in_dialog: interact_pressed.emit()
		elif colliding and not must_leave_area: start_dialogue()

func _process(_delta: float) -> void:
	if in_dialog and is_instance_valid(TxtBg) and get_viewport().get_camera_2d():
		TxtBg.global_position = get_viewport().get_camera_2d().get_screen_center_position() - (TxtBg.size / 2.0)

func _physics_process(_delta: float) -> void:
	if not is_playing(): play("Anim")
	label.visible = (not in_dialog and colliding and not must_leave_area)

func start_dialogue() -> void:
	in_dialog = true; player.SPEED = 0
	Txt.show(); TxtBg.show()
	
	# Explicitly hide all buttons at the start
	for btn in [accept, decline, button_3, button_4, button_5]:
		if btn: btn.hide()
	
	Txt.text = "I saw what you did down there. You might stand a chance."
	await get_tree().create_timer(0.1).timeout; await interact_pressed 
	
	Txt.text = "I need some material for a project I'm working on. Give me 10 of those skin things, and I'll teach you a skill."
	accept.show(); decline.show()
	
	if await choice_made:
		if player.skins >= 10:
			player.skins -= 10; player.hasbloodbind = true
			Txt.text = "Thanks. You have learned Bloodbind!"
		else:
			Txt.text = "You don't have enough skins..."
	else:
		Txt.text = "Alright. I'll just be here if you need me."
		must_leave_area = true 
	
	await get_tree().create_timer(0.1).timeout; await interact_pressed
	
	accept.hide(); decline.hide(); Txt.hide(); TxtBg.hide()
	player.SPEED = 1440; in_dialog = false

func _on_area_2d_body_entered(body: Node2D) -> void: if body.has_method("flash_red"): colliding = true
func _on_area_2d_body_exited(body: Node2D) -> void: if body.has_method("flash_red"): colliding = false; must_leave_area = false
