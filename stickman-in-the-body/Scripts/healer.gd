extends AnimatedSprite2D

@onready var management: Node = %Management
@onready var label: Label = $Area2D/CollisionShape2D/Label
@onready var TxtBg: ColorRect = $"../Player/Camera2D2/ColorRect2"
@onready var Txt: RichTextLabel = $"../Player/Camera2D2/ColorRect2/RichTextLabel"

@onready var accept: Button = TxtBg.get_node("Accept")
@onready var decline: Button = TxtBg.get_node("Decline")
@onready var button_3: Button = TxtBg.get_node("Button3")
@onready var button_4: Button = TxtBg.get_node("Button4")
@onready var button_5: Button = TxtBg.get_node("Button5")

@onready var player: CharacterBody2D = %Player
@onready var healthbar: ProgressBar = $"../Player/Healthbar"

var in_dialog = false
var colliding = false
var must_leave_area = false 
var health_upgrade_bought = false

signal interact_pressed
signal choice_made(choice: String)

func _ready() -> void:
	for ui in [Txt, TxtBg, accept, decline, button_3, button_4, button_5]: 
		if ui: ui.hide()
	
	accept.pressed.connect(func(): choice_made.emit("heal"))
	decline.pressed.connect(func(): choice_made.emit("decline"))
	button_5.pressed.connect(func(): choice_made.emit("upgrade"))

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
	
	# Explicitly hide buttons 3 and 4 as they are unused here
	if button_3: button_3.hide()
	if button_4: button_4.hide()
	
	Txt.text = "Oi, you there. Scrawny. You look beat up. Don't expect yourself to last much longer in your condition."
	await get_tree().create_timer(0.1).timeout; await interact_pressed 
	
	Txt.text = "I've got some stuff you might last longer off. Take a look. If you're interested, tell me. I'll give it to you for the right price."
	await get_tree().create_timer(0.1).timeout; await interact_pressed 
	
	Txt.text = "Hurry it up."
	accept.show(); decline.show()
	accept.text = "Heal"; decline.text = "Nevermind"
	
	if not health_upgrade_bought:
		button_5.show(); button_5.text = "Health Upgrade"
	else:
		button_5.hide()
	
	var choice = await choice_made
	accept.hide(); decline.hide(); button_5.hide()
	
	if choice == "heal":
		var heal_cost = (healthbar.max_value - healthbar.value) * 1 
		if heal_cost <= 0:
			Txt.text = "You're already at full health. Quit wasting my time."
		elif player.money >= heal_cost:
			player.money -= heal_cost
			healthbar.value = healthbar.max_value
			player.set("health", healthbar.max_value)
			player.set("hp", healthbar.max_value)
			Txt.text = "Alright, patched you up. That'll be " + str(heal_cost) + " dollars."
		else:
			Txt.text = "You don't have enough money! You need " + str(heal_cost) + " dollars to fully heal."
			
	elif choice == "upgrade":
		if player.money >= 500:
			player.money -= 500
			health_upgrade_bought = true
			healthbar.max_value += 20
			
			var current_max = player.get("max_health") if player.get("max_health") != null else player.get("max_hp")
			if current_max != null:
				player.set("max_health", current_max + 20)
				player.set("max_hp", current_max + 20)
			
			healthbar.value = healthbar.max_value
			healthbar.health = healthbar.value
			management.health_upgrades += 1
			Txt.text = "Pleasure doing business. Try not to get yourself killed with that."
		else:
			Txt.text = "You need 500 dollars for this upgrade. Come back when you're not broke."

	await get_tree().create_timer(0.1).timeout; await interact_pressed 

	Txt.text = "Well then, if you think you can survive the roads ahead, go on! By all means, don't come back to me crying when you've bled yourself half to death"
	await get_tree().create_timer(0.1).timeout; await interact_pressed 
	
	must_leave_area = true 
	Txt.hide(); TxtBg.hide()
	player.SPEED = 1200; in_dialog = false

func _on_area_2d_body_entered(body: Node2D) -> void: if body.has_method("flash_red"): colliding = true
func _on_area_2d_body_exited(body: Node2D) -> void: if body.has_method("flash_red"): colliding = false; must_leave_area = false
