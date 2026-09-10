extends AnimatedSprite2D

@onready var management: Node = %Management
@onready var DetectionZone: Area2D = $Area2D
@onready var label: Label = $Area2D/CollisionShape2D/Label
@onready var TxtBg: ColorRect = $"../Player/Camera2D2/ColorRect2"
@onready var Txt: RichTextLabel = $"../Player/Camera2D2/ColorRect2/RichTextLabel"
@onready var press_space_to_continue: Label = $"../Player/Camera2D2/ColorRect2/Press Space to Continue"
@onready var accept: Button = $"../Player/Camera2D2/ColorRect2/Accept"
@onready var button_3: Button = $"../Player/Camera2D2/ColorRect2/Button3"
@onready var button_4: Button = $"../Player/Camera2D2/ColorRect2/Button4"
@onready var button_5: Button = $"../Player/Camera2D2/ColorRect2/Button5"
@onready var decline: Button = $"../Player/Camera2D2/ColorRect2/Decline"

@onready var player: CharacterBody2D = %Player

# FIXED: Changed from %Healthbar to the direct node path relative to this character
@onready var healthbar: ProgressBar = $"../Player/Healthbar"


var animationlock = 0
var indialog = 0
var colliding = 0
var must_leave_area = false 
var health_upgrade_bought = false

signal interact_pressed
signal choice_made(choice: String)

func _ready() -> void:

	
	accept.pressed.connect(func(): choice_made.emit("heal"))
	decline.pressed.connect(func(): choice_made.emit("decline"))
	button_5.pressed.connect(func(): choice_made.emit("upgrade"))

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("Interact"):
		if indialog == 1:
			interact_pressed.emit()
		elif colliding == 1 and not must_leave_area:
			start_dialogue()

func _physics_process(delta: float) -> void:
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
	
	accept.hide()
	decline.hide()
	button_5.hide()
	
	# --- PAGE 3 (Outcomes) ---
	if choice == "heal":
		var health_missing = healthbar.max_value - healthbar.value
		var heal_cost = health_missing * 1 
		
		if health_missing <= 0:
			Txt.text = "You're already at full health. Quit wasting my time."
			await get_tree().create_timer(0.1).timeout
			await interact_pressed
		elif player.money >= heal_cost:
			player.money -= heal_cost
			
			# Update UI Elements
			healthbar.value = healthbar.max_value
			
			# Safe way to update player script variables dynamically
			player.set("health", healthbar.max_value)
			player.set("hp", healthbar.max_value)
			
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
			
			
			var hp_increase = 20
			healthbar.max_value += hp_increase
			
			# Update player script max health safely if it exists
			var current_max = player.get("max_health")
			if current_max == null:
				current_max = player.get("max_hp")
				
			if current_max != null:
				player.set("max_health", current_max + hp_increase)
				player.set("max_hp", current_max + hp_increase)
				healthbar.value = healthbar.max_value
				healthbar.health = healthbar.value
			
			Txt.text = "Pleasure doing business. Try not to get yourself killed with that."
			healthbar.value = healthbar.max_value
			management.health_upgrades += 1
			print(management.health_upgrades)
			healthbar.health = healthbar.value
			print(health_upgrade_bought)
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
