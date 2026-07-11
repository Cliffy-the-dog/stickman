extends Node2D

@onready var binventory: ColorRect = $Binventory
@onready var ninventory: ColorRect = $Ninventory
@onready var minventory: ColorRect = $Minventory
@onready var player: CharacterBody2D = %Player

# Define the possible states for your inventory
enum MenuState { CLOSED, B, N, M }
var current_state: MenuState = MenuState.CLOSED

func _process(_delta: float) -> void:
	global_position = player.global_position

func _input(event: InputEvent) -> void:
	# Using 'elif' ensures only one input is handled per frame
	if event.is_action_pressed("B"):
		toggle_menu(MenuState.B)
	elif event.is_action_pressed("N"):
		toggle_menu(MenuState.N)
	elif event.is_action_pressed("M"):
		toggle_menu(MenuState.M)

func toggle_menu(target_state: MenuState) -> void:
	# If the pressed menu is already open, close it. Otherwise, switch to it.
	if current_state == target_state:
		current_state = MenuState.CLOSED
	else:
		current_state = target_state
	
	# Set visibility instantly based on the current state
	binventory.visible = (current_state == MenuState.B)
	ninventory.visible = (current_state == MenuState.N)
	minventory.visible = (current_state == MenuState.M)
