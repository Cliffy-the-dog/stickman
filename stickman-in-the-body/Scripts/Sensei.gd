extends AnimatedSprite2D

@onready var label: Label = $Area2D/CollisionShape2D/Label
@onready var TxtBg: ColorRect = $"../DirectionalLight2D/Management/Player/Camera2D2/ColorRect2"
@onready var Txt: RichTextLabel = $"../DirectionalLight2D/Management/Player/Camera2D2/ColorRect2/RichTextLabel"

@onready var accept: Button = TxtBg.get_node("Accept")
@onready var decline: Button = TxtBg.get_node("Decline")
@onready var button_3: Button = TxtBg.get_node_or_null("Button3")
@onready var button_4: Button = TxtBg.get_node_or_null("Button4")
@onready var button_5: Button = TxtBg.get_node_or_null("Button5")

@onready var player: CharacterBody2D = %Player

var in_dialog = false
var colliding = false
var must_leave_area = false

signal interact_pressed
signal choice_made(accepted: bool)


## Hides dialogue UI and connects accept/decline button signals.
func _ready() -> void:
	for ui in [Txt, TxtBg, accept, decline, button_3, button_4, button_5]:
		if ui:
			ui.hide()

	Txt.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART

	accept.pressed.connect(func(): choice_made.emit(true))
	decline.pressed.connect(func(): choice_made.emit(false))


## Handles interact input to advance or start dialogue.
func _input(event: InputEvent) -> void:
	if event.is_action_pressed("Interact"):
		if in_dialog:
			interact_pressed.emit()
		elif colliding and not must_leave_area:
			start_dialogue()


## Keeps idle animation playing and shows interact label when nearby.
func _physics_process(_delta: float) -> void:
	if not is_playing():
		play("Anim")
	label.visible = (not in_dialog and colliding and not must_leave_area)


## Runs Bloodbind unlock dialogue in exchange for skins.
func start_dialogue() -> void:
	in_dialog = true
	player.SPEED = 0
	Txt.show()
	TxtBg.show()

	for btn in [accept, decline, button_3, button_4, button_5]:
		if btn:
			btn.hide()

	Txt.text = "I saw what you did down there. You might stand a chance."
	await get_tree().create_timer(0.1).timeout
	await interact_pressed

	Txt.text = "I need some material for a project I'm working on. Give me 10 of those skin things, and I'll teach you a skill."
	accept.show()
	decline.show()

	if await choice_made:
		if player.skins >= 10:
			player.skins -= 10
			player.hasbloodbind = true
			_refresh_skill_tree()
			Txt.text = "Thanks. You have learned Bloodbind!"
		else:
			Txt.text = "You don't have enough skins..."
	else:
		Txt.text = "Alright. I'll just be here if you need me."
		must_leave_area = true

	await get_tree().create_timer(0.1).timeout
	await interact_pressed

	accept.hide()
	decline.hide()
	Txt.hide()
	TxtBg.hide()
	player.SPEED = 1440
	in_dialog = false


## Marks the player as inside the Sensei interaction area.
func _on_area_2d_body_entered(body: Node2D) -> void:
	if body.has_method("flash_red"):
		colliding = true


## Clears interaction state when the player leaves the area.
func _on_area_2d_body_exited(body: Node2D) -> void:
	if body.has_method("flash_red"):
		colliding = false
		must_leave_area = false


## Updates skill tree glows and saves after teaching Bloodbind.
func _refresh_skill_tree() -> void:
	for node in get_tree().get_nodes_in_group("skill_nodes"):
		if node.has_method("sync_from_player"):
			node.sync_from_player()
	var save_manager := get_tree().get_first_node_in_group("save_manager")
	if save_manager and save_manager.has_method("save_game"):
		save_manager.save_game()
