class_name WaveSpawner
extends Node2D

signal encounter_started
signal wave_started(wave_number: int)
signal wave_completed(wave_number: int)
signal encounter_completed

@export_group("Barrier & Persistence Settings")
## Drag and drop the door, wall, or object to destroy upon clearing the gauntlet
@export var barrier_to_remove: Node2D
## Optional: Assign a PersistencyTracker node. If empty, checks for a child node named "PersistencyTracker"
@export var persistency_tracker: Node
## Unique ID string for this gauntlet (e.g., "gauntlet_room_1")
@export var gauntlet_id: String = ""

@export_group("Trigger Settings")
@onready var player: CharacterBody2D = %Player
@export var trigger_distance: float = 1200.0

@export_group("Encounter Setup")
## Optional: Drag Marker2D nodes here for spawn locations. If empty, monsters spawn at this node's position.
@export var spawn_points: Array[Node2D] = []
@export var delay_between_waves: float = 2.0
## Add waves here in the Inspector using WaveData resources
@export var waves: Array[WaveData] = []

var active_monsters: Array[Node] = []
var is_active: bool = false

func _ready() -> void:
	# Disable _process immediately so start_encounter() cannot trigger on frame 1
	set_process(false)

	if not is_instance_valid(player):
		player = get_tree().get_first_node_in_group("player") as CharacterBody2D

	if not is_instance_valid(persistency_tracker) and has_node("PersistencyTracker"):
		persistency_tracker = get_node("PersistencyTracker")

	# Sync gauntlet_id to PersistencyTracker if entity_id was left empty
	if is_instance_valid(persistency_tracker) and "entity_id" in persistency_tracker:
		if persistency_tracker.entity_id == "":
			persistency_tracker.entity_id = gauntlet_id

	# Defer check to let save manager load save file state first
	call_deferred("_initialize_persistence_check")

func _initialize_persistence_check() -> void:
	if _is_already_cleared():
		_destroy_barrier_and_free()
		return
	
	# Only re-enable _process if the gauntlet hasn't been cleared yet
	set_process(true)

func _is_already_cleared() -> bool:
	# Check via PersistencyTracker
	if is_instance_valid(persistency_tracker):
		if persistency_tracker.has_method("is_defeated") and persistency_tracker.is_defeated():
			return true
		if "entity_id" in persistency_tracker and persistency_tracker.entity_id != "":
			var save_mgr = _find_save_manager()
			if save_mgr and "defeated_entity_ids" in save_mgr:
				if persistency_tracker.entity_id in save_mgr.defeated_entity_ids:
					return true

	# Check fallback gauntlet_id
	if gauntlet_id.strip_edges() != "":
		var save_mgr = _find_save_manager()
		if save_mgr and "defeated_entity_ids" in save_mgr:
			if gauntlet_id in save_mgr.defeated_entity_ids:
				return true

	return false

func _process(_delta: float) -> void:
	if is_active:
		return

	if is_instance_valid(player):
		if global_position.distance_to(player.global_position) <= trigger_distance:
			start_encounter()

func start_encounter() -> void:
	is_active = true
	encounter_started.emit()

	for i in range(waves.size()):
		var wave = waves[i]
		if not wave:
			continue

		wave_started.emit(i + 1)
		await spawn_wave(wave)
		await wait_for_wave_clear()
		wave_completed.emit(i + 1)

		if i < waves.size() - 1:
			await get_tree().create_timer(delay_between_waves).timeout

	encounter_completed.emit()
	_on_gauntlet_cleared()

func spawn_wave(wave: WaveData) -> void:
	if wave.enemies.is_empty():
		return

	var point_index = 0

	for enemy_entry in wave.enemies:
		if not enemy_entry or not enemy_entry.monster_scene:
			continue

		for c in range(enemy_entry.count):
			var monster = enemy_entry.monster_scene.instantiate()

			var spawn_pos = global_position
			if not spawn_points.is_empty():
				var max_points = min(spawn_points.size(), 3)
				var point_node = spawn_points[point_index % max_points]
				
				if is_instance_valid(point_node):
					spawn_pos = point_node.global_position
				
				point_index += 1

			get_parent().add_child.call_deferred(monster)
			monster.global_position = spawn_pos
			active_monsters.append(monster)

			monster.tree_exiting.connect(func(): active_monsters.erase(monster))

			if wave.spawn_delay > 0:
				await get_tree().create_timer(wave.spawn_delay).timeout

func wait_for_wave_clear() -> void:
	while not active_monsters.is_empty():
		active_monsters = active_monsters.filter(func(node): return is_instance_valid(node))
		if active_monsters.is_empty():
			break
		await get_tree().create_timer(0.25).timeout

func _on_gauntlet_cleared() -> void:
	var id_to_save = gauntlet_id

	if is_instance_valid(persistency_tracker):
		if "entity_id" in persistency_tracker and persistency_tracker.entity_id != "":
			id_to_save = persistency_tracker.entity_id
		
		if persistency_tracker.has_method("on_defeated"):
			persistency_tracker.on_defeated()
		elif persistency_tracker.has_method("register_entity_death") and id_to_save != "":
			persistency_tracker.register_entity_death(id_to_save)

	if id_to_save.strip_edges() != "":
		var save_mgr = _find_save_manager()
		if save_mgr and save_mgr.has_method("register_entity_death"):
			save_mgr.register_entity_death(id_to_save)

	_destroy_barrier_and_free()

func _destroy_barrier_and_free() -> void:
	if is_instance_valid(barrier_to_remove):
		var collider = barrier_to_remove.find_child("CollisionShape2D", true, false)
		if collider:
			collider.set_deferred("disabled", true)
		barrier_to_remove.queue_free()
	queue_free()

func _find_save_manager() -> Node:
	var sm = get_tree().get_first_node_in_group("save_manager")
	if sm:
		return sm
	return get_tree().current_scene.find_child("pause_menu", true, false)
