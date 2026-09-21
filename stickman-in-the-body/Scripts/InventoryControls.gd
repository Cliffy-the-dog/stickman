extends Node2D

@onready var binventory: ColorRect = $Binventory
@onready var ninventory: ColorRect = $Ninventory
@onready var minventory: ColorRect = $Minventory
@onready var healthbar: ProgressBar = $Binventory/Healthbar
@onready var skill_lines: Control = $Ninventory/ScrollContainer/ColorRect/SkillLines
@onready var player: CharacterBody2D = %Player

enum MenuState { CLOSED, B, N, M }
var current_state: MenuState = MenuState.CLOSED


# Initializes inventory UI, hides menus, and configures scroll containers.
func _ready() -> void:
	add_to_group("inventory_ui")
	process_mode = Node.PROCESS_MODE_ALWAYS
	z_index = 4096
	z_as_relative = false

	binventory.hide()
	ninventory.hide()
	minventory.hide()

	for menu in [binventory, ninventory, minventory]:
		menu.mouse_filter = Control.MOUSE_FILTER_IGNORE
		menu.process_mode = Node.PROCESS_MODE_ALWAYS
		_configure_scroll_views(menu)


# Syncs the health bar and skill shaders while a menu is open.
func _process(_delta: float) -> void:
	if is_instance_valid(player) and is_instance_valid(healthbar):
		healthbar.max_value = player.max_health
		healthbar.value = player.health

	if current_state == MenuState.N:
		var shader_time := Time.get_ticks_msec() / 1000.0
		for node in get_tree().get_nodes_in_group("skill_nodes"):
			if node.has_method("update_shader_time"):
				node.update_shader_time(shader_time)


# Handles B/N/M key presses to open or close inventory menus.
func _input(event: InputEvent) -> void:
	if event.is_action_pressed("B"):
		toggle_menu(MenuState.B)
	elif event.is_action_pressed("N"):
		toggle_menu(MenuState.N)
	elif event.is_action_pressed("M"):
		toggle_menu(MenuState.M)


# Toggles a specific inventory menu and pauses the game when one is open.
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
	_update_menu_mouse_filters()

	var skills_open := current_state == MenuState.N
	if skills_open:
		_sync_skill_nodes()
		call_deferred("_rebuild_skill_lines")
	_set_skill_lines_visible(skills_open)


# Enables mouse input on the active menu panel only.
func _update_menu_mouse_filters() -> void:
	for menu in [binventory, ninventory, minventory]:
		menu.mouse_filter = (
			Control.MOUSE_FILTER_STOP if menu.visible else Control.MOUSE_FILTER_IGNORE
		)


# Recursively configures ScrollContainer children for scrolling while paused.
func _configure_scroll_views(parent_node: Node) -> void:
	for child in parent_node.get_children():
		if child is ScrollContainer:
			child.process_mode = Node.PROCESS_MODE_ALWAYS
			child.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
			child.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO

			for inner_child in child.get_children():
				if inner_child is VBoxContainer or inner_child is HBoxContainer:
					inner_child.custom_minimum_size = Vector2(1500, 1200)
					inner_child.mouse_filter = Control.MOUSE_FILTER_PASS

		_configure_scroll_views(child)


# Refreshes every skill node glow from the player's current unlocks.
func _sync_skill_nodes() -> void:
	for node in get_tree().get_nodes_in_group("skill_nodes"):
		if node.has_method("sync_from_player"):
			node.sync_from_player()


# Rebuilds connector lines after the skills panel layout is visible.
func _rebuild_skill_lines() -> void:
	if is_instance_valid(skill_lines) and skill_lines.has_method("rebuild_all"):
		skill_lines.rebuild_all()


# Shows or hides skill tree connector lines with the skills tab.
func _set_skill_lines_visible(should_show: bool) -> void:
	if is_instance_valid(skill_lines):
		skill_lines.visible = should_show
