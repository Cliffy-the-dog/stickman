extends AnimatedSprite2D

@onready var label: Label = $Area2D/CollisionShape2D/Label
@onready var TxtBg: ColorRect = $"../Player/Camera2D2/ColorRect2"
@onready var Txt: RichTextLabel = $"../Player/Camera2D2/ColorRect2/RichTextLabel"
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
	
	accept.pressed.connect(func(): choice_made.emit(true))
	decline.pressed.connect(func(): choice_made.emit(false))

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
	
	# Explicitly hide all buttons initially
	for btn in [accept, decline, button_3, button_4, button_5]:
		if btn: btn.hide()
	
	Txt.text = "Hello young warrior! You don't by any chance have any interesting things on you? I'll buy them off you for a good price!"
	await get_tree().create_timer(0.1).timeout; await interact_pressed 
	
	Txt.text = "Well then, lets make a deal. You give me all your enemy parts, and I'll give you a good price!"
	accept.show(); decline.show()
	
	if await choice_made:
		var total_given = player.skins * 20
		Txt.text = "Here you go! You sold me " + str(player.skins) + " skins, so here is " + str(total_given) + " dollars!"
		player.money += total_given
		player.skins = 0
	else:
		Txt.text = "Oh alright then, tell me if you change your mind"
		must_leave_area = true 
	
	await get_tree().create_timer(0.1).timeout; await interact_pressed 
	
	accept.hide(); decline.hide(); Txt.hide(); TxtBg.hide()
	player.SPEED = 1200; in_dialog = false

func _on_area_2d_body_entered(body: Node2D) -> void: if body.has_method("flash_red"): colliding = true
func _on_area_2d_body_exited(body: Node2D) -> void: if body.has_method("flash_red"): colliding = false; must_leave_area = false
