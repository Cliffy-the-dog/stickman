extends CharacterBody2D

@onready var AnimatedSprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var healthbar: ProgressBar = $Healthbar
@onready var boss_hitbox: Area2D = $BossHitbox

var head_scene = preload("res://entities/projectiles/head.tscn")
var spike_scene = preload("res://assets/sprites/Spike.tscn")
var limb_projectile_scene = preload("res://assets/sprites/LimbProjectile.tscn")

@export_group("Persistence")
## Unique ID for saving (auto-assigned to child PersistencyTracker if left empty there)
@export var entity_id: String = "former_guardian_boss"

@export_group("Guardian Settings")
@export var player: Node2D

# --- ADJUSTABLE EXPORT VARIABLES ---
@export var max_health: int = 1000
@export var attack_cooldown: float = 1.0 # Delay between attacks
@export var spike_gap: float = 150.0
@export var DASH_SPEED: float = 1500.0

# --- BOSS STATS ---
@onready var health: int = max_health
var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")

# --- ABILITY VARIABLES ---
var dash_distance_left = 0.0
var spin_timer = 0.0
var head_reference: Node2D = null
var attack_timer = 0.0
var headless_timeout = 0.0
var last_attack_choice: int = 0

# --- STATE MACHINE ---
enum State { SLEEP, WAKING, IDLE, DASH, SPIKE, START_SPIN, SPIN, SPREAD, THROW_HEAD, HEADLESS, DYING }
var current_state = State.SLEEP

var wake_delay = 0.2

func _ready():
	health = max_health
	healthbar.max_value = max_health
	healthbar.value = health
	AnimatedSprite.play("StartIdle")

	# Sync entity_id to child PersistencyTracker if it was left empty
	var tracker := _find_persistency_tracker()
	if tracker and "entity_id" in tracker and tracker.entity_id == "" and entity_id != "":
		tracker.entity_id = entity_id

func _physics_process(delta):
	# Apply gravity during air movement except active horizontal DASH
	if not is_on_floor() and current_state != State.DASH:
		velocity.y += gravity * delta

	match current_state:
		State.SLEEP:
			if wake_delay > 0.0:
				wake_delay -= delta
			elif player and global_position.distance_to(player.global_position) <= 1200:
				change_state(State.WAKING)
				AnimatedSprite.play("Starting")
				velocity = Vector2.ZERO
				
		State.WAKING:
			if not AnimatedSprite.is_playing() or AnimatedSprite.animation != "Starting":
				change_state(State.IDLE)
				
		State.IDLE:
			velocity.x = move_toward(velocity.x, 0, 2000 * delta)
			AnimatedSprite.play("Idle")
			
			attack_timer -= delta
			if attack_timer <= 0.0:
				pick_random_attack()
			
		State.DASH:
			process_dash(delta)
			
		State.SPIKE, State.START_SPIN, State.THROW_HEAD:
			velocity.x = move_toward(velocity.x, 0, 2000 * delta)
			
		State.SPIN:
			AnimatedSprite.play("Spinning")
			if velocity.x == 0 and player:
				var dir = sign(player.global_position.x - global_position.x)
				velocity.x = (dir if dir != 0 else 1) * 1800.0
			spin_timer -= delta
			if spin_timer <= 0:
				change_state(State.IDLE)
				
		State.SPREAD:
			velocity.x = move_toward(velocity.x, 0, 1000 * delta)
				
		State.HEADLESS:
			AnimatedSprite.play("Headless")
			velocity.x = move_toward(velocity.x, 0, 2000 * delta)
			
			headless_timeout -= delta
			if not is_instance_valid(head_reference) or headless_timeout <= 0.0:
				change_state(State.IDLE)
				
		State.DYING:
			velocity.x = move_toward(velocity.x, 0, 2000 * delta)

	update_facing()
	move_and_slide()

# --- STATE TRANSITION HELPER ---
func change_state(new_state: State):
	current_state = new_state
	if new_state == State.IDLE:
		attack_timer = attack_cooldown

# --- FACING LOGIC ---
func update_facing():
	if not player or current_state in [State.SLEEP, State.DYING]:
		return
		
	if current_state in [State.DASH, State.SPIN]:
		if velocity.x != 0:
			AnimatedSprite.flip_h = velocity.x < 0
	else:
		AnimatedSprite.flip_h = player.global_position.x < global_position.x

# --- ATTACK LOGIC ---
func pick_random_attack():
	if current_state != State.IDLE or not player: return 
	
	var attacks = [1, 2, 3, 4, 5]
	
	if last_attack_choice in attacks:
		attacks.erase(last_attack_choice)
		
	var chosen = attacks.pick_random()
	last_attack_choice = chosen
	
	match chosen:
		1: start_dash()
		2: start_spike()
		3: start_spin()
		4: start_spread()
		5: start_head_throw()

func start_dash():
	change_state(State.DASH)
	AnimatedSprite.play("Dash")
	dash_distance_left = 1800.0
	
	if not is_on_floor():
		velocity = global_position.direction_to(player.global_position) * DASH_SPEED
	else:
		var dir = sign(player.global_position.x - global_position.x)
		velocity = Vector2((dir if dir != 0 else 1) * DASH_SPEED, 0)

func process_dash(delta):
	var distance_moved = DASH_SPEED * delta
	dash_distance_left -= distance_moved
	
	if is_on_floor() and velocity.y > 0:
		velocity.y = 0
		var dir = sign(player.global_position.x - global_position.x)
		velocity.x = (dir if dir != 0 else 1) * DASH_SPEED
	
	if dash_distance_left <= 0:
		change_state(State.IDLE)

func start_spike():
	if not is_on_floor(): 
		attack_timer = 0.1 
		return
		
	change_state(State.SPIKE)
	velocity.x = 0
	
	var facing_dir = -1 if AnimatedSprite.flip_h else 1
	var start_x = global_position.x + (facing_dir * 100)
	var warning_spikes = []
	
	for i in range(8):
		var warning = spike_scene.instantiate()
		warning.global_position = Vector2(start_x + (i * spike_gap * facing_dir), global_position.y)
		warning.modulate.a = 0.4
		
		for child in warning.get_children():
			if child is Area2D:
				child.set_deferred("monitoring", false)
				child.set_deferred("monitorable", false)
				
		get_parent().add_child(warning)
		warning_spikes.append(warning)

	AnimatedSprite.play("Spike")
	await AnimatedSprite.animation_finished
	
	for w in warning_spikes:
		if is_instance_valid(w):
			w.queue_free()
	
	if current_state == State.DYING: return 
	
	for i in range(8):
		var spike = spike_scene.instantiate()
		spike.global_position = Vector2(start_x + (i * spike_gap * facing_dir), global_position.y)
		get_parent().add_child(spike)
		
	change_state(State.IDLE)

func start_spin():
	change_state(State.START_SPIN)
	velocity.x = 0
	AnimatedSprite.play("Start Spin")
	await AnimatedSprite.animation_finished
	if current_state == State.DYING: return 
	
	var dir = sign(player.global_position.x - global_position.x)
	velocity.x = (dir if dir != 0 else 1) * 1800.0
	spin_timer = 2.0 
	change_state(State.SPIN)

func start_spread():
	change_state(State.SPREAD)
	velocity.x = 0
	AnimatedSprite.play("Spread")
	
	await get_tree().create_timer(0.2).timeout 
	if current_state == State.DYING: return
	
	velocity.y = -1200.0 
	
	while velocity.y < 0 and current_state == State.SPREAD:
		await get_tree().physics_frame
	
	if current_state == State.DYING: return
	
	for i in range(6):
		if current_state == State.DYING: return
		var limb = limb_projectile_scene.instantiate()
		limb.global_position = global_position
		
		var aim_dir = global_position.direction_to(player.global_position)
		aim_dir = aim_dir.rotated(randf_range(-0.5, 0.5))
		
		if limb.has_method("set_direction"):
			limb.set_direction(aim_dir, player)
			
		get_parent().add_child(limb)
		await get_tree().create_timer(0.15).timeout 
		
	change_state(State.IDLE)

func start_head_throw():
	change_state(State.THROW_HEAD)
	velocity.x = 0
	
	AnimatedSprite.play("Throw head")
	await AnimatedSprite.animation_finished
	if current_state == State.DYING: return
	
	var head = head_scene.instantiate()
	head.global_position = global_position
	var aim_dir = global_position.direction_to(player.global_position)
	
	if head.has_method("launch"):
		head.launch(aim_dir, player)
	
	get_parent().add_child(head)
	head_reference = head
	
	headless_timeout = 6.0 
	change_state(State.HEADLESS)

# --- DAMAGE AND COLLISIONS ---
func take_damage(amount):
	if current_state == State.DYING: return 
	
	health -= amount
	healthbar.value = health
	
	if health <= 0:
		change_state(State.DYING)
		velocity.x = 0 
		if is_instance_valid(healthbar):
			healthbar.hide()
			
		AnimatedSprite.play("Keeling over and dying")
		await AnimatedSprite.animation_finished
		
		# --- REGISTER PERSISTENT DEATH ---
		var tracker := _find_persistency_tracker()
		if tracker and tracker.has_method("on_defeated"):
			tracker.on_defeated()
		elif entity_id.strip_edges() != "":
			var save_mgr = get_tree().get_first_node_in_group("save_manager")
			if not save_mgr:
				save_mgr = get_tree().current_scene.find_child("pause_menu", true, false)
			if save_mgr and save_mgr.has_method("register_entity_death"):
				save_mgr.register_entity_death(entity_id)

		queue_free()

func _find_persistency_tracker() -> Node:
	for child in get_children():
		if child is PersistencyTracker:
			return child
	return get_node_or_null("PersistencyTracker")

func _on_boss_hitbox_body_entered(body):
	if current_state == State.DYING: return 
	
	if body == player:
		# 1. Base contact damage applied in ALL states
		if body.has_method("take_damage"): 
			body.take_damage(10)
		
		# 2. State-specific bonuses and knockbacks
		if current_state == State.DASH:
			if body.has_method("take_damage"): 
				body.take_damage(10)
			
			var knock_dir = sign(global_position.x - player.global_position.x)
			global_position.x += (knock_dir if knock_dir != 0 else 1.0) * 100
			change_state(State.IDLE)
			
		elif current_state == State.SPIN:
			pass
