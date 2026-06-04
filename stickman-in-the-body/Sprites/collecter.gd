extends AnimatedSprite2D

@onready var management: Node = %Management
@onready var DetectionZone: Area2D = $Area2D
@onready var label: Label = $Area2D/CollisionShape2D/Label
@onready var TxtBg: ColorRect = $"../Player/ColorRect"
@onready var Txt: RichTextLabel = $"../Player/ColorRect/RichTextLabel"
@onready var player: CharacterBody2D = %Player
@onready var accept: Button = $"../Player/ColorRect/Accept"
@onready var decline: Button = $"../Player/ColorRect/Decline"
@onready var button_3: Button = $"../Player/ColorRect/Button3"
@onready var button_4: Button = $"../Player/ColorRect/Button4"
@onready var button_5: Button = $"../Player/ColorRect/Button5"

# CHANGED: This is now an export variable so you can assign it in the Inspector
var healthbar: ProgressBar

var animationlock = 0
var indialog = 0
var colliding = 0
var must_leave_area = false 
var health_upgrade_bought = false

signal interact_pressed
# Changed from bool to String to handle 3 different button choices
signal choice_made(choice: String)

func _ready() -> void:
	healthbar = get_tree().get_first_node_in_group("main_healthbar")
	Txt.hide()
	TxtBg.hide()
	accept.hide()
	decline.hide()
	button_3.hide()
	button_4.hide()
	button_5.hide()
	
	# Pass a string corresponding to the action
	accept.pressed.connect(func(): choice_made.emit("heal"))
	decline.pressed.connect(func(): choice_made.emit("decline"))
	button_5.pressed.connect(func(): choice_made.emit("upgrade"))

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
	Txt.text = "Oi, you there. Scrawny. You look beat up. Don't expect yourself to last much longer in your condition."
	
	await get_tree().create_timer(0.1).timeout 
	await interact_pressed 
	
	Txt.text = "I've got some stuff you might last longer off. Take a look. If you're interested, tell me. I'll give it to you for the right price."
	
	await get_tree().create_timer(0.1).timeout 
	await interact_pressed 
	
	# --- PAGE 2 ---
	Txt.text = "Hurry it up."
	accept.show()
	decline.show()
	
	if health_upgrade_bought:
		button_5.hide()
	else:
		button_5.show()
		
	decline.text = "Nevermind"
	accept.text = "Heal"
	button_5.text = "Health Upgrade"
	
	var choice = await choice_made
	
	# Hide buttons as soon as a choice is made
	accept.hide()
	decline.hide()
	button_5.hide()
	
	# --- PAGE 3 (Outcomes) ---
	if choice == "heal":
		var health_missing = healthbar.max_value - healthbar.value
		var heal_cost = health_missing * 1 # 1 dollar per missing HP
		
		if health_missing <= 0:
			Txt.text = "You're already at full health. Quit wasting my time."
			await get_tree().create_timer(0.1).timeout
			await interact_pressed
		elif player.money >= heal_cost:
			player.money -= heal_cost
			healthbar.health = healthbar.max_value
			healthbar.value = healthbar.max_value
			Txt.text = "Alright, patched you up. That'll be " + str(heal_cost) + " dollars."
			await get_tree().create_timer(0.1).timeout
			await interact_pressed
		else:
			Txt.text = "You don't have enough money! You need " + str(heal_cost) + " dollars to fully heal."
			await get_tree().create_timer(0.1).timeout
			await interact_pressed
			
	elif choice == "upgrade":
		if player.money >= 500:
			player.money -= 500
			health_upgrade_bought = true
			management.health_upgrades += 1
			Txt.text = "Pleasure doing business. Try not to get yourself killed with that."
			await get_tree().create_timer(0.1).timeout
			await interact_pressed
		else:
			Txt.text = "You need 500 dollars for this upgrade. Come back when you're not broke."
			await get_tree().create_timer(0.1).timeout
			await interact_pressed

	# --- WRAP UP PART ---
	Txt.text = "Well then, if you think you can survive the roads ahead, go on! By all means, don't come back to me crying when you've bled yourself half to death"
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
