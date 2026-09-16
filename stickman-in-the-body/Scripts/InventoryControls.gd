extends Node2D

@onready var binventory: ColorRect = $Binventory
@onready var ninventory: ColorRect = $Ninventory
@onready var minventory: ColorRect = $Minventory
@onready var healthbar: ProgressBar = $Binventory/Healthbar
@onready var player: CharacterBody2D = %Player

enum MenuState { CLOSED, B, N, M }
var current_state: MenuState = MenuState.CLOSED

func _ready() -> void:
	# Keeps UI responsive when the game is paused
	process_mode = Node.PROCESS_MODE_ALWAYS
	
	binventory.hide()
	ninventory.hide()
	minventory.hide()

	# Fix all mouse filters and scroll container sizes in code automatically
	for menu in [binventory, ninventory, minventory]:
		menu.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_configure_scroll_views(menu)

func _process(_delta: float) -> void:
	if is_instance_valid(player) and is_instance_valid(healthbar):
		healthbar.max_value = player.max_health
		healthbar.value = player.health

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("B"):
		toggle_menu(MenuState.B)
	elif event.is_action_pressed("N"):
		toggle_menu(MenuState.N)
	elif event.is_action_pressed("M"):
		toggle_menu(MenuState.M)

func toggle_menu(target_state: MenuState) -> void:
	if current_state == target_state:
		current_state = MenuState.CLOSED
		get_tree().paused = false
	else:
		current_state = target_state
		get_tree().paused = true
	
	binventory.visible = (current_state == MenuState.B)
	ninventory.visible = (current_state == MenuState.N)
	minventory.visible = (current_state == MenuState.M)

# Traverses subtrees to force ScrollContainer children to scroll correctly
func _configure_scroll_views(parent_node: Node) -> void:
	for child in parent_node.get_children():
		if child is ScrollContainer:
			child.process_mode = Node.PROCESS_MODE_ALWAYS
			child.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
			child.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
			
			for inner_child in child.get_children():
				if inner_child is Control:
					# Forces scroll bounds without manual editor adjustments
					inner_child.custom_minimum_size = Vector2(1500, 1200)
					inner_child.mouse_filter = Control.MOUSE_FILTER_PASS
					
		_configure_scroll_views(child)
