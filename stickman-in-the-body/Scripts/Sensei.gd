extends AnimatedSprite2D

@onready var area_2d: Area2D = $Area2D
@onready var label: Label = $Area2D/CollisionShape2D/Label

# Your original paths remain untouched
@onready var TxtBg: ColorRect = $"../DirectionalLight2D/Management/Player/Camera2D2/ColorRect2"
@onready var Txt: RichTextLabel = $"../DirectionalLight2D/Management/Player/Camera2D2/ColorRect2/RichTextLabel"

@onready var player: CharacterBody2D = %Player
@onready var accept: Button = $"../DirectionalLight2D/Management/Player/Camera2D2/ColorRect2/Accept"
@onready var decline: Button = $"../DirectionalLight2D/Management/Player/Camera2D2/ColorRect2/Decline"


var animationlock = 0
var indialog = 0
var colliding = 0
var must_leave_area = false 

signal interact_pressed
signal choice_made(accepted: bool)

func _ready() -> void:
	Txt.hide()
	TxtBg.hide()
	accept.hide()
	decline.hide()
	
	Txt.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	
	if not accept.pressed.is_connected(_on_accept_pressed):
		accept.pressed.connect(_on_accept_pressed)
	if not decline.pressed.is_connected(_on_decline_pressed):
		decline.pressed.connect(_on_decline_pressed)

func _on_accept_pressed() -> void:
	choice_made.emit(true)

func _on_decline_pressed() -> void:
	choice_made.emit(false)

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("Interact"):
		if indialog == 1:
			interact_pressed.emit()
		elif colliding == 1 and not must_leave_area:
			start_dialogue()

func _process(_delta: float) -> void:
	# Keep dialogue centered on screen without reparenting nodes
	if indialog == 1 and is_instance_valid(TxtBg):
		var camera = get_viewport().get_camera_2d()
		if camera:
			TxtBg.global_position = camera.get_screen_center_position() - (TxtBg.size / 2.0)

func _physics_process(_delta: float) -> void:
	if animationlock == 0:
		animationlock = 1
		play("Anim")
		await animation_finished
		animationlock = 0
		
	if indialog == 0 and colliding == 1 and not must_leave_area:
		label.show()
	else: 
		label.hide()

func start_dialogue() -> void:
	indialog = 1
	player.SPEED = 0
	
	# Initial position sync before showing
	var camera = get_viewport().get_camera_2d()
	if camera:
		TxtBg.global_position = camera.get_screen_center_position() - (TxtBg.size / 2.0)
		
	Txt.show()
	TxtBg.show()
	
	# --- PAGE 1 ---
	Txt.text = "I saw what you did down there. You might stand a chance."
	
	await get_tree().create_timer(0.1).timeout 
	await interact_pressed 
	
	# --- PAGE 2 ---
	Txt.text = "I need some material for a project I'm working on. Give me 10 of those skin things, and I'll teach you a skill."
	accept.show()
	decline.show()
	
	var accepted = await choice_made
	
	accept.hide()
	decline.hide()
	
	# --- PAGE 3 (Outcomes) ---
	if accepted:
		if player.skins >= 10:
			player.skins -= 10
			player.hasbloodbind = true
			Txt.text = "Thanks. You have learned Bloodbind!"
			await get_tree().create_timer(0.1).timeout
			await interact_pressed
		else:
			Txt.text = "You don't have enough skins..."
			await get_tree().create_timer(0.1).timeout
			await interact_pressed
	else:
		Txt.text = "Alright. I'll just be here if you need me."
		await get_tree().create_timer(0.1).timeout
		await interact_pressed 
		must_leave_area = true 
	
	# Clean up and reset states
	Txt.hide()
	TxtBg.hide()
	player.SPEED = 1440 
	indialog = 0

func _on_area_2d_body_entered(body: Node2D) -> void:
	if body.has_method("flash_red"): colliding = 1

func _on_area_2d_body_exited(body: Node2D) -> void:
	if body.has_method("flash_red"): 
		colliding = 0
		must_leave_area = false 

func _on_area_2d_area_entered(area: Area2D) -> void:
	if area.has_method("flash_red"): colliding = 1

func _on_area_2d_area_exited(area: Area2D) -> void:
	if area.has_method("flash_red"): 
		colliding = 0
		must_leave_area = false
