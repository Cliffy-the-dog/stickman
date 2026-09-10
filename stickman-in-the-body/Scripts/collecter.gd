extends AnimatedSprite2D

@onready var DetectionZone: Area2D = $Area2D
@onready var label: Label = $Area2D/CollisionShape2D/Label
@onready var TxtBg: ColorRect = $"../Player/Camera2D2/ColorRect2"

@onready var Txt: RichTextLabel = $"../Player/Camera2D2/ColorRect2/RichTextLabel"

@onready var player: CharacterBody2D = %Player
@onready var accept: Button = $"../Player/Camera2D2/ColorRect2/Accept"
@onready var decline: Button = $"../Player/Camera2D2/ColorRect2/Decline"


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
	
	accept.pressed.connect(func(): choice_made.emit(true))
	decline.pressed.connect(func(): choice_made.emit(false))

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
	
	# --- PAGE 1 ---
	Txt.text = "Hello young warrior! You don't by any chance have any interesting things on you? I'll buy them off you for a good price!"
	
	await get_tree().create_timer(0.1).timeout 
	await interact_pressed 
	
	# --- PAGE 2 ---
	Txt.text = "Well then, lets make a deal. You give me all your enemy parts, and I'll give you a good price!"
	accept.show()
	decline.show()
	
	var accepted = await choice_made
	
	accept.hide()
	decline.hide()
	
	# --- PAGE 3 (Outcomes) ---
	if accepted:
		Txt.text = "Here you go! You sold me " + str(player.skins) + " skins, so here is " + str(player.skins * 20) + " dollars!"
		var total_given = player.skins * 20
		await get_tree().create_timer(0.1).timeout
		await interact_pressed # Closes dialogue safely now!
		player.money += total_given
		player.skins = 0
		await interact_pressed
		# OPTIONAL: If you want them to leave the area after accepting too, 
		# uncomment the line below:
		# must_leave_area = true
		
	else:
		Txt.text = "Oh alright then, tell me if you change your mind"
		await get_tree().create_timer(0.1).timeout
		await interact_pressed 
		must_leave_area = true 
	
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
