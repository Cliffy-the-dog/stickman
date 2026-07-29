extends AnimatedSprite2D

@onready var area_2d: Area2D = $Area2D
@onready var label: Label = $Area2D/CollisionShape2D/Label

@onready var TxtBg: ColorRect = $"../DirectionalLight2D/Management/Player/ColorRect"
@onready var Txt: RichTextLabel = $"../DirectionalLight2D/Management/Player/ColorRect/RichTextLabel"
@onready var player: CharacterBody2D = %Player

var animationlock = 0
var indialog = 0
var colliding = 0
var must_leave_area = false 

signal interact_pressed

func _ready() -> void:
	Txt.hide()
	TxtBg.hide()

func _input(event: InputEvent) -> void:
	# Handle ALL spacebar inputs here to prevent frame-bleeding loops
	if event.is_action_pressed("Interact"):
		if indialog == 1:
			# If already talking, this press ONLY advances the text
			interact_pressed.emit()
		elif colliding == 1 and not must_leave_area:
			# If not talking but nearby, this press ONLY starts the dialogue
			start_dialogue()

func _physics_process(delta: float) -> void:
	if animationlock == 0:
		animationlock = 1
		play("Anim")
		await animation_finished
		animationlock = 0
		
	# Physics process now ONLY handles showing/hiding the prompt indicator
	if indialog == 0 and colliding == 1 and not must_leave_area:
		label.show()
	else: 
		label.hide()

func start_dialogue() -> void:
	indialog = 1
	player.SPEED = 0
	Txt.show()
	TxtBg.show()
	
	if player.has_walljump:
		# --- POST-UPGRADE DIALOGUE ---
		Txt.text = "Go on, try it out, hop on a wall and keep jumping!"
		await get_tree().create_timer(0.1).timeout 
		await interact_pressed 
	else:
		# --- FIRST TIME DIALOGUE ---
		Txt.text = "Yo, you. I'm kinda dying here, and there's no way to go back down."
		await get_tree().create_timer(0.1).timeout 
		await interact_pressed 
		
		Txt.text = "My technique would be wasted on me. Take it. You look like you have a grudge against the plague that's killin' the lot of us. Go on, use it to ascend."
		await get_tree().create_timer(0.1).timeout 
		await interact_pressed 
		
		Txt.text = "You should be able to wall jump now. Scat."
		await get_tree().create_timer(0.1).timeout 
		await interact_pressed 
		
		player.has_walljump = true
	
	must_leave_area = true # Forces the player to walk away before re-triggering the NPC
	
	# Clean up and reset states
	Txt.hide()
	TxtBg.hide()
	player.SPEED = 1200 
	indialog = 0

# --- Collision Detection ---
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
