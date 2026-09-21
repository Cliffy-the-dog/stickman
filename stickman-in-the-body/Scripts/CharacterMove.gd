extends CharacterBody2D

# =============================================================================
# Node References
# =============================================================================

@onready var visuals: Node2D = $Visuals
@onready var anim_player: AnimationPlayer = $Visuals/PlayerAnimPlayer
@onready var grounder_hitbox: CollisionShape2D = $"Grounder Hitbox"
@onready var fazed_hitbox: Area2D = $"Fazed Hitbox"
@export var projectile_scene: PackedScene
@export var bloodmine_scene: PackedScene

@onready var bloodbar: ProgressBar = get_node_or_null("CanvasLayer/Bloodbar") if get_node_or_null("CanvasLayer/Bloodbar") else $Bloodbar
@onready var healthbar: ProgressBar = %Healthbar if has_node("%Healthbar") else get_node_or_null("CanvasLayer/Healthbar")
@onready var management: Node = %Management
@onready var pause_menu: Control = $Camera2D2/PauseMenu
@onready var node_2d: Node2D = $Node2D
@onready var particles = [$Node2D/CPUParticles2D, $Node2D/CPUParticles2D4, $Node2D/CPUParticles2D6, $Node2D/CPUParticles2D5]
@onready var dust_particles: GPUParticles2D = $GPUParticles2D
@export var particle_node: GPUParticles2D
@onready var moneyLabel: Label = $Camera2D2/Money

# --- Limb Trail References ---
@export var arm_l_trail: Line2D
@export var arm_r_trail: Line2D
@export var leg_l_trail: Line2D
@export var leg_r_trail: Line2D

const CHAIN_TOSS = preload("uid://cvoqnry8ssqo6")

# =============================================================================
# Adjustable Variables
# =============================================================================

@export var keyframe_x_shift: float = 0.0
@export var visual_offset_x: float = 190.0
@export var wall_slide_offset_x: float = 50.0
@export var pogo_cooldown_duration: float = 0.4
@export var wall_slide_speed: float = 300.0
@export var push_force = 100.0

# =============================================================================
# Player Stats & Flags
# =============================================================================

var health: float
var has_bloodbind: bool = false
var hasbloodbind: bool:
	get: return has_bloodbind
	set(v): has_bloodbind = v

var bootson: bool = true
const JUMP_VELOCITY = -2200.0
var money: float = 0.0

var skins: int = 0:
	set(value):
		skins = max(0, value)

var abletoheal: bool = true
var is_healing: bool = false
var damage: int = 20
var last_checkpoint: Vector2 = Vector2.ZERO
var attackers: Array[Node] = []
var last_floor_pos: Vector2 = Vector2.ZERO
var pause_Idleanimationforce: bool = false
var damage_taken_in_the_past_0point4seconds: bool = false
var damage_value: int = 10
var bouncing_in_progress: bool = false
var being_touched: bool = false
var health_upgrades: int = 1
var has_healer_health_upgrade: bool = false
var SPEED: float = 1440.0
var sprint_speed_boost: float = 400.0
var healthpause: bool = false
var is_safe_ground: bool = true
var max_health: int = 100 + 20 * health_upgrades
var bloodbind_in_progress: bool = false
var goo_spawn_cooldown: float = 0.0
var has_walljump: bool = false
var is_crouching: bool = false
var crouch_cooldown: float = 0.0
var has_sprint_unlocked: bool = false

# --- Dash & Movement Variables ---
var is_dashing: bool = false
var dash_timer: float = 0.0
var dash_direction: int = 1
var dash_cooldown_timer: float = 0.0
var is_pogo_sliding: bool = false
var wall_jump_lock_timer: float = 0.0

# --- Pogo Variables ---
var is_pogoing: bool = false
var was_pogoing: bool = false
var pogo_start_y: float = 0.0
var pogo_direction: float = 0.0
var pogo_fall_timer: float = 0.0
var pogo_cooldown_timer: float = 0.0

# --- Combo Variables ---
var combo_step: int = 0
var combo_timer: float = 0.0
var is_punching: bool = false
var punch_slide_speed: float = 1200.0
var facing_direction: float = 1.0
var _bloodbind_floor_y: float = 0.0
var _bloodbind_lock_y: bool = false

@onready var default_hitbox_pos_y = grounder_hitbox.position.y

# =============================================================================
# Initialization
# =============================================================================


## Resets player state, connects signals, and loads save data on spawn.
func _ready():
	add_to_group("player")
	has_bloodbind = false
	bloodbind_in_progress = false
	pause_Idleanimationforce = false
	SPEED = 1440.0

	%SlashArea2.hide()
	%SlashArea2.monitoring = false
	%SlashArea2.collision_mask = 0xFFFFFFFF

	shift_all_keyframe_offsets(keyframe_x_shift)
	anim_player.animation_finished.connect(_on_animation_finished)

	if pause_menu and pause_menu.has_method("load_game"):
		pause_menu.load_game()

	_setup_limb_trails()

	if is_instance_valid(healthbar):
		healthbar.max_value = 100 + 20 * management.health_upgrades
		healthbar.value = healthbar.max_value
		healthbar.health = healthbar.max_value

	if is_instance_valid(bloodbar):
		bloodbar.value = bloodbar.max_value

	for p in particles:
		p.show()
		p.emitting = false
		p.restart()
		p.emitting = false

	if not %SlashArea2.area_entered.is_connected(_on_slash_area_2_area_entered):
		%SlashArea2.area_entered.connect(_on_slash_area_2_area_entered)
	if not %SlashArea2.body_entered.is_connected(_on_slash_area_2_body_entered):
		%SlashArea2.body_entered.connect(_on_slash_area_2_body_entered)


## Finds and assigns limb trail Line2D nodes under the visuals hierarchy.
func _setup_limb_trails() -> void:
	var lines = visuals.find_children("*", "Line2D", true, false)
	for line in lines:
		if line is Line2D:
			line.visible = false
			var p_name = line.get_parent().name.to_lower()
			if "arm" in p_name or "hand" in p_name:
				if "r" in p_name and arm_r_trail == null: arm_r_trail = line
				elif "l" in p_name and arm_l_trail == null: arm_l_trail = line
				elif arm_l_trail == null: arm_l_trail = line
				elif arm_r_trail == null: arm_r_trail = line
			elif "leg" in p_name or "foot" in p_name:
				if "r" in p_name and leg_r_trail == null: leg_r_trail = line
				elif "l" in p_name and leg_l_trail == null: leg_l_trail = line
				elif leg_l_trail == null: leg_l_trail = line
				elif leg_r_trail == null: leg_r_trail = line


## Shows or hides limb trail effects based on combo step and pogo state.
func update_limb_trails(step: int) -> void:
	var show_arm_l = is_pogoing or (step == 1 or step == 3 or step == 4)
	var show_arm_r = is_pogoing or (step == 1 or step == 2 or step == 3 or step == 4)
	var show_legs = is_pogoing or (step == 3)

	if arm_l_trail:
		if "emitting" in arm_l_trail: arm_l_trail.emitting = show_arm_l
		else: arm_l_trail.visible = show_arm_l
	if arm_r_trail:
		if "emitting" in arm_r_trail: arm_r_trail.emitting = show_arm_r
		else: arm_r_trail.visible = show_arm_r
	if leg_l_trail:
		if "emitting" in leg_l_trail: leg_l_trail.emitting = show_legs
		else: leg_l_trail.visible = show_legs
	if leg_r_trail:
		if "emitting" in leg_r_trail: leg_r_trail.emitting = show_legs
		else: leg_r_trail.visible = show_legs


## Shifts all animation keyframe X positions by the given offset.
func shift_all_keyframe_offsets(offset_x: float) -> void:
	if offset_x == 0.0:
		return

	for anim_name in anim_player.get_animation_list():
		var anim = anim_player.get_animation(anim_name)
		for track in anim.get_track_count():
			if anim.track_get_type(track) == Animation.TYPE_VALUE and "position" in String(anim.track_get_path(track)):
				for key in anim.track_get_key_count(track):
					var val = anim.track_get_key_value(track, key)
					if val is Vector2:
						val.x += offset_x
						anim.track_set_key_value(track, key, val)


## Plays an animation only when it is not already playing (prevents restart every frame).
func _play_anim(anim_name: String) -> void:
	# Pogo clip is authored at 0.04s — slow it down so it is visible on high-refresh PCs.
	var target_speed := 0.08 if anim_name == "Pogo" else 1.0
	if not is_equal_approx(anim_player.speed_scale, target_speed):
		anim_player.speed_scale = target_speed
	if anim_player.current_animation != anim_name or not anim_player.is_playing():
		anim_player.play(anim_name)


## Flashes the player sprite red briefly to indicate damage taken.
func flash_red():
	var t = create_tween()
	t.tween_property(self, "modulate", Color.DARK_RED, 0.2)
	t.tween_property(self, "modulate", Color.WHITE, 0.4)


## Returns whether there is enough clearance above to stand up from crouch.
func can_uncrouch() -> bool:
	for body in fazed_hitbox.get_overlapping_bodies():
		if body != self:
			return false
	return true

# =============================================================================
# Physics & Movement
# =============================================================================


## Main movement loop: gravity, input, combat, animation, and collision.
func _physics_process(delta):
	if crouch_cooldown > 0.0: crouch_cooldown -= delta
	if dash_cooldown_timer > 0.0: dash_cooldown_timer -= delta
	if pogo_cooldown_timer > 0.0: pogo_cooldown_timer -= delta
	if wall_jump_lock_timer > 0.0: wall_jump_lock_timer -= delta

	if not is_punching and combo_timer > 0.0:
		combo_timer -= delta
		if combo_timer <= 0.0:
			combo_step = 0

	if is_dashing:
		dash_timer -= delta
		if dash_timer <= 0.0:
			is_dashing = false
			is_pogo_sliding = false

	if is_pogoing:
		pogo_fall_timer += delta

	if is_pogoing != was_pogoing:
		was_pogoing = is_pogoing
		update_limb_trails(combo_step)

	if is_instance_valid(moneyLabel):
		moneyLabel.text = "$" + str(money)

	if particle_node and particle_node.process_material is ParticleProcessMaterial:
		var process_mat = particle_node.process_material as ParticleProcessMaterial
		if visuals.scale.x < 0:
			dust_particles.position.x = 44
			process_mat.direction.x = 5
		else:
			dust_particles.position.x = -44
			process_mat.direction.x = -5

	dust_particles.emitting = false
	node_2d.global_position = global_position

	if not is_on_floor() and not bloodbind_in_progress and (not is_dashing or is_pogo_sliding):
		velocity += get_gravity() * delta * 5

		if is_on_wall() and velocity.y > 0 and not is_pogoing:
			velocity.y = min(velocity.y, wall_slide_speed)
			var wall_normal = get_wall_normal()
			visuals.scale.x = -1 if wall_normal.x > 0 else 1
			visuals.position.x = (wall_slide_offset_x * wall_normal.x) + visual_offset_x

	elif bloodbind_in_progress or (is_dashing and not is_pogo_sliding):
		velocity.y = 0

	if is_on_floor() and Input.is_action_just_pressed("Heal") and is_instance_valid(healthbar) and healthbar.value < healthbar.max_value and not is_healing:
		is_healing = true
		while is_instance_valid(bloodbar) and bloodbar.value > 0 and healthbar.value < healthbar.max_value and abletoheal:
			for p in particles: p.emitting = true
			SPEED = 0
			bloodbar.value -= 1.0
			healthbar.value += 1.0
			await get_tree().create_timer(0.02).timeout
			healthbar.health = healthbar.value
		SPEED = 1440
		for p in particles: p.emitting = false
		is_healing = false

	if Input.is_action_just_pressed("Slash") and is_on_floor() and not is_crouching:
		execute_punch()

	if Input.is_action_just_pressed("Jump") and is_on_floor() and not bloodbind_in_progress and not is_crouching and not is_punching:
		velocity.y = JUMP_VELOCITY
		anim_player.play("Jumpstart")

	if Input.is_action_just_pressed("Jump") and is_on_wall() and not is_on_floor() and has_walljump:
		is_pogoing = false
		pogo_fall_timer = 0.0

		var wall_direction = get_wall_normal()
		velocity.y = JUMP_VELOCITY
		wall_jump_lock_timer = 0.25
		anim_player.play("Walljump")

		if wall_direction.x < 0:
			velocity.x = -1500
			visuals.scale.x = 1
		if wall_direction.x > 0:
			velocity.x = 1500
			visuals.scale.x = -1

	if is_crouching and not is_dashing and dash_cooldown_timer <= 0.0 and (Input.is_action_just_pressed("Jump") or Input.is_action_just_pressed("Slash")):
		is_dashing = true
		is_pogo_sliding = false
		dash_timer = 0.2
		dash_direction = -1 if visuals.scale.x < 0 else 1
		dash_cooldown_timer = 1.0

	var d := 0.0
	if not bloodbind_in_progress and not is_dashing and not is_punching:
		d = Input.get_axis("Walk Left", "Walk Right")

	if d and anim_player.current_animation != "Slide":
		var desired_scale = -1 if d < 0 else 1

		if anim_player.current_animation == "Leap":
			desired_scale *= -1

		visuals.scale.x = desired_scale
		facing_direction = sign(d)

		if %SlashArea2.get_parent() == self:
			%SlashArea2.position.x = -60 * facing_direction
		else:
			%SlashArea2.position.x = -60
	elif anim_player.current_animation == "Leap":
		visuals.scale.x = 1 if facing_direction < 0 else -1

	if bouncing_in_progress and velocity.y >= 0:
		bouncing_in_progress = false

	var attempted_aerial_pogo = Input.is_action_just_pressed("Crouch") or Input.is_action_just_pressed("Slash")

	if Input.is_action_just_pressed("Crouch") and is_on_floor() and not bloodbind_in_progress and crouch_cooldown <= 0.0:
		if is_crouching:
			if can_uncrouch():
				is_crouching = false
				crouch_cooldown = 0.3
		else:
			is_crouching = true
			crouch_cooldown = 0.3

	elif attempted_aerial_pogo and not is_on_floor() and not is_on_wall() and not is_pogoing and not bloodbind_in_progress and pogo_cooldown_timer <= 0.0:
		is_pogoing = true
		pogo_start_y = global_position.y
		pogo_fall_timer = 0.0
		if velocity.y < 0: velocity.y = 0
		pogo_direction = sign(d) if d != 0 else 0.0

	if not is_on_floor() and crouch_cooldown <= 0.0 and not is_dashing and not is_pogoing:
		if is_crouching and can_uncrouch():
			is_crouching = false

	if is_crouching:
		grounder_hitbox.scale.y = 0.75
		grounder_hitbox.position.y = 60.0
	else:
		grounder_hitbox.scale.y = 1.5
		grounder_hitbox.position.y = default_hitbox_pos_y

	if not pause_Idleanimationforce and not is_punching:
		if is_dashing:
			_play_anim("Pogo" if is_pogo_sliding else "CrouchWalk")
		elif (anim_player.current_animation == "Walljump" or anim_player.current_animation == "Jumpstart") and anim_player.is_playing():
			pass
		elif is_on_wall() and not is_on_floor() and velocity.y > 0 and not is_pogoing:
			_play_anim("Slide")
		elif is_pogoing or bouncing_in_progress:
			_play_anim("Pogo")
		elif is_crouching:
			_play_anim("CrouchWalk" if d != 0 else "CrouchIdle")
		elif d and is_on_floor():
			_play_anim("Walk")
		elif not is_on_floor():
			_play_anim("Leap" if d != 0 else "Jump")
		elif d == 0 and is_on_floor():
			_play_anim("Idle")

	var current_speed = SPEED
	if Input.is_action_pressed("Sprint") and has_sprint_unlocked:
		current_speed += sprint_speed_boost

	if bloodbind_in_progress:
		velocity = Vector2.ZERO
		if _bloodbind_lock_y:
			global_position.y = _bloodbind_floor_y
	elif is_dashing:
		velocity.x = dash_direction * 2500.0
	elif is_pogoing:
		velocity.x = (pogo_direction * velocity.y) * 1.2
	elif is_punching:
		velocity.x = move_toward(velocity.x, 0, current_speed * delta * 8)
	elif wall_jump_lock_timer > 0.0:
		if d != 0: velocity.x = move_toward(velocity.x, d * current_speed, 3000 * delta)
	else:
		velocity.x = d * current_speed if d else move_toward(velocity.x, 0, current_speed)

	velocity.y = clamp(velocity.y, -3600.0, 3600.0)
	move_and_slide()

	if is_on_floor():
		wall_jump_lock_timer = 0.0
		if is_pogoing:
			if pogo_direction != 0.0:
				var distance_fallen = max(0, global_position.y - pogo_start_y)
				var slide_distance = distance_fallen / 2.0
				if slide_distance > 10.0:
					is_dashing = true
					is_pogo_sliding = true
					dash_direction = pogo_direction
					dash_timer = slide_distance / 2500.0
			is_pogoing = false
			pogo_fall_timer = 0.0
			pogo_cooldown_timer = pogo_cooldown_duration

		if bouncing_in_progress:
			bouncing_in_progress = false

		for i in get_slide_collision_count():
			var collision = get_slide_collision(i)
			if collision.get_normal().y < -0.5:
				var collider = collision.get_collider()
				if collider:
					var is_temporary = collider.has_method("passage") or (collider.get_parent() and collider.get_parent().has_method("passage"))
					is_safe_ground = not is_temporary

		if is_safe_ground:
			last_floor_pos = global_position

# =============================================================================
# Combat
# =============================================================================


## Starts the next punch in the combo chain and activates the slash hitbox.
func execute_punch() -> void:
	if is_punching:
		return

	if combo_timer > 0.0:
		combo_step += 1
		if combo_step > 4: combo_step = 1
	else:
		combo_step = 1

	is_punching = true
	combo_timer = 0.0
	velocity.x = facing_direction * punch_slide_speed

	visuals.scale.x = facing_direction

	if %SlashArea2.get_parent() == self:
		%SlashArea2.position.x = -120 * facing_direction
	else:
		%SlashArea2.position.x = 120

	%SlashArea2.show()
	%SlashArea2.monitoring = true

	var anim_name = "Punch" + str(combo_step)
	if anim_player.has_animation(anim_name):
		anim_player.play(anim_name)
		update_limb_trails(combo_step)

	await get_tree().process_frame
	_check_slash_hitbox_overlaps()


## Checks for enemies already overlapping the slash hitbox on punch start.
func _check_slash_hitbox_overlaps() -> void:
	if not is_punching: return

	var bodies = %SlashArea2.get_overlapping_bodies()
	var areas = %SlashArea2.get_overlapping_areas()

	for body in bodies:
		_process_hit_target(body)

	for area in areas:
		_process_hit_target(area)


## Resets punch state and starts combo reset timer when punch animation ends.
func _on_animation_finished(anim_name: String) -> void:
	if anim_name.begins_with("Punch"):
		is_punching = false
		%SlashArea2.hide()
		%SlashArea2.monitoring = false
		combo_timer = 0.2
		update_limb_trails(0)
	if anim_name == "Jumpstart":
		if not is_on_floor():
			anim_player.play("Leap" if velocity.x != 0 else "Jump")


## Handles slash hitbox collision with an area target.
func _on_slash_area_2_area_entered(a):
	_process_hit_target(a)


## Handles slash hitbox collision with a body target.
func _on_slash_area_2_body_entered(b):
	_process_hit_target(b)


## Damages a target node and restores blood on successful hit.
func _process_hit_target(node: Node) -> void:
	if not is_punching or node == self or node == fazed_hitbox:
		return

	var target = node
	while target != null and not target.has_method("take_damage"):
		target = target.get_parent()
		if target == get_tree().root:
			target = null
			break

	if target and target.has_method("take_damage"):
		target.take_damage(damage)
		if is_instance_valid(bloodbar):
			bloodbar.value = min(bloodbar.max_value, bloodbar.value + 10)

# =============================================================================
# Hazards & Damage
# =============================================================================


## Applies killzone damage and teleports or respawns the player.
func _on_killzone_body_entered(_b):
	if is_instance_valid(healthbar) and healthbar.value > 0 and not damage_taken_in_the_past_0point4seconds: apply_damage(10)
	if is_instance_valid(healthbar) and healthbar.value > 0: global_position = last_floor_pos
	else: respawn_logic()


## Teleports to last checkpoint or reloads the scene on death.
func respawn_logic():
	attackers.clear()

	if last_checkpoint != Vector2.ZERO:
		global_position = last_checkpoint
		if is_instance_valid(healthbar):
			healthbar.value = healthbar.max_value
	else:
		get_tree().reload_current_scene()


## Reduces health, flashes red, and applies brief damage invulnerability.
func apply_damage(val):
	abletoheal = false
	damage_taken_in_the_past_0point4seconds = true
	flash_red()

	if is_instance_valid(healthbar):
		healthbar.value -= val
		healthbar.health = healthbar.value
		if "damage_bar" in healthbar and healthbar.damage_bar:
			healthbar.damage_bar.value = healthbar.health

	await get_tree().create_timer(0.4).timeout
	damage_taken_in_the_past_0point4seconds = false
	abletoheal = true


## Plays death animation and triggers respawn logic.
func die_sequence():
	healthpause = true; SPEED = 0; pause_Idleanimationforce = true
	anim_player.play("Die")
	await anim_player.animation_finished
	pause_Idleanimationforce = false; healthpause = false; SPEED = 1440
	respawn_logic()


## Handles pogo bounce off bodies and tracks overlapping attackers.
func _on_fazed_hitbox_body_entered(b):
	if b == self: return
	var is_bouncable = b.has_method("take_damage") or "Spike" in b.name or "Limb" in b.name
	if is_pogoing and velocity.y > 0 and is_bouncable:
		if b.has_method("take_damage"):
			b.take_damage(damage_value)
			if is_instance_valid(bloodbar):
				bloodbar.value = min(bloodbar.max_value, bloodbar.value + 10)
		velocity.y = JUMP_VELOCITY * sqrt(1.5)
		is_pogoing = false
		pogo_fall_timer = 0.0
		pogo_cooldown_timer = pogo_cooldown_duration
		bouncing_in_progress = true
		return
	if b.has_method("take_damage") and not attackers.has(b):
		attackers.append(b)


## Removes a body from the active attackers list when it exits.
func _on_fazed_hitbox_body_exited(b):
	if attackers.has(b): attackers.erase(b)


## Handles pogo bounce, hazards, checkpoints, and special area triggers.
func _on_fazed_hitbox_area_entered(a):
	if a == self or a.get_parent() == self: return
	var target = a if a.has_method("take_damage") else a.get_parent()

	var t_name = target.name.to_lower() if target else ""
	var a_name = a.name.to_lower()
	var is_hazard = "damage" in a_name or "spike" in a_name or "limb" in a_name or "head" in a_name or "spike" in t_name or "limb" in t_name or "head" in t_name

	var is_bouncable = (target and target.has_method("take_damage")) or is_hazard

	if is_pogoing and velocity.y > 0 and is_bouncable:
		if target and target.has_method("take_damage"):
			target.take_damage(damage_value)
			if is_instance_valid(bloodbar):
				bloodbar.value = min(bloodbar.max_value, bloodbar.value + 10)
		velocity.y = JUMP_VELOCITY * sqrt(1.5)
		is_pogoing = false
		pogo_fall_timer = 0.0
		pogo_cooldown_timer = pogo_cooldown_duration
		bouncing_in_progress = true
		return

	if is_hazard and not attackers.has(a):
		attackers.append(a)

	if a.has_method("AreaIdentifier"):
		if not is_healing:
			is_healing = true
			SPEED = 0
			if is_instance_valid(healthbar):
				while healthbar.value < healthbar.max_value:
					healthbar.value += 1
					await get_tree().create_timer(0.02).timeout
				healthbar.health = healthbar.max_value
			SPEED = 1440; last_checkpoint = global_position; pause_menu.save_game()
			is_healing = false

	if a.has_method("GITGUD"):
		SPEED = 700; await get_tree().create_timer(0.2).timeout; SPEED = 1440


## Removes an area from the active attackers list when it exits.
func _on_fazed_hitbox_area_exited(a):
	if attackers.has(a):
		attackers.erase(a)


## Resets visual offset, processes attacker damage, death, and blood spell input.
func _process(_delta):
	if not is_on_wall():
		visuals.position.x = visual_offset_x

	for i in range(attackers.size() - 1, -1, -1):
		if not is_instance_valid(attackers[i]):
			attackers.remove_at(i)

	if attackers.size() > 0 and is_instance_valid(healthbar) and healthbar.value > 0 and not damage_taken_in_the_past_0point4seconds and not healthpause:
		if not (is_pogoing and velocity.y > 0):
			apply_damage(damage_value)

	if is_instance_valid(healthbar):
		if healthbar.value < 1 and not healthpause: die_sequence()
		health = healthbar.value

	if Input.is_action_just_pressed("BloodSpell") and has_bloodbind and not bloodbind_in_progress:
		if projectile_scene != null:
			if is_instance_valid(bloodbar) and bloodbar.value >= 10.0:
				bloodbar.value -= 10.0
				shoot_projectile()

# =============================================================================
# Spells & Helpers
# =============================================================================


## Attempts to spend skins and returns whether the cost was affordable.
func spend_skins(amount: int) -> bool:
	if skins >= amount:
		skins -= amount
		return true
	return false


## Unlocks bloodbind ability if the player has enough skins.
func unlock_bloodbind() -> bool:
	if spend_skins(10):
		has_bloodbind = true

		var save_manager = get_tree().get_first_node_in_group("save_manager")
		if save_manager and save_manager.has_method("save_game"):
			save_manager.save_game()
		return true
	return false


## Spawns and launches the bloodbind chain projectile.
func shoot_projectile() -> void:
	if projectile_scene == null:
		return
	if not is_on_floor():
		return

	bloodbind_in_progress = true
	_bloodbind_lock_y = true
	_bloodbind_floor_y = global_position.y
	pause_Idleanimationforce = true
	SPEED = 0
	velocity = Vector2.ZERO

	var is_facing_left: bool = facing_direction < 0
	var launch_dir: Vector2 = Vector2.LEFT if is_facing_left else Vector2.RIGHT

	var proj = projectile_scene.instantiate()
	proj.is_flipped = is_facing_left
	proj.direction = launch_dir
	proj.player_ref = self
	proj.global_position = global_position

	get_tree().current_scene.add_child(proj)

	if anim_player and anim_player.has_animation("Bloodbind Launch"):
		anim_player.play("Bloodbind Launch")


## Restores movement and idle state after bloodbind completes.
func finish_bloodbind() -> void:
	bloodbind_in_progress = false
	_bloodbind_lock_y = false
	pause_Idleanimationforce = false
	SPEED = 1440
	visuals.position.y = 0.0
	_play_anim("Idle")


## Plays bloodbind miss punishment animation and audio.
func trigger_endlag_punishment() -> void:
	$AudioStreamPlayer2D.play()
	_play_anim("Bloodbind Endlag")
	await anim_player.animation_finished
	$AudioStreamPlayer2D.playing = false
	finish_bloodbind()


## Applies damage unless the player is pogo-bouncing or invulnerable.
func take_damage(amount):
	if (is_pogoing and velocity.y > 0) or bouncing_in_progress:
		return

	if not damage_taken_in_the_past_0point4seconds and not healthpause:
		apply_damage(amount)

# =============================================================================
# Skill Tree Upgrades
# =============================================================================


## Unlocks sprint speed boost if wall jump is already unlocked.
func sprint(cost: int = 10, speed_boost: float = 400.0) -> bool:
	if has_sprint_unlocked:
		print("Sprint is already unlocked.")
		return true

	if not has_walljump:
		push_warning("Cannot unlock Sprint: Wall Jump (Root) is required first.")
		return false

	if spend_skins(cost):
		has_sprint_unlocked = true
		sprint_speed_boost = speed_boost
		print("Sprint unlocked successfully!")

		var save_manager = get_tree().get_first_node_in_group("save_manager")
		if save_manager and save_manager.has_method("save_game"):
			save_manager.save_game()
		return true
	else:
		print("Not enough skins to unlock Sprint!")
		return false


## Places a bloodmine at the player's position if bloodbind is unlocked.
func bloodmine() -> void:
	if not has_bloodbind:
		push_warning("Cannot use Bloodmine: Bloodbind (Root) is required first.")
		return
	if bloodmine_scene == null:
		push_error("Player: bloodmine_scene is not assigned in the Inspector!")
		return
	var mine = bloodmine_scene.instantiate()
	mine.global_position = global_position
	get_tree().current_scene.add_child(mine)


## Increases maximum blood bar capacity if bloodbind is unlocked.
func blood_increase_1(amount: float = 20.0) -> bool:
	if not has_bloodbind:
		push_warning("Cannot unlock Blood Increase I: Bloodbind (Root) is required first.")
		return false
	if is_instance_valid(bloodbar):
		bloodbar.max_value += amount
		bloodbar.value = bloodbar.max_value
	return true


## Applies the healer health upgrade and raises max health.
func healer_health_upgrade(amount: float = 20.0) -> void:
	has_healer_health_upgrade = true
	health_upgrades += 1
	max_health += amount
	if is_instance_valid(healthbar):
		healthbar.max_value = max_health
		healthbar.value = max_health
		healthbar.health = max_health


## Applies a second health upgrade tier if prerequisites are met.
func health_upgrade_2(amount: float = 20.0) -> bool:
	if not has_healer_health_upgrade and health_upgrades < 1:
		push_warning("Cannot unlock Health Upgrade II: Healer Health Upgrade (Root) is required first.")
		return false
	health_upgrades += 1
	max_health += amount
	if is_instance_valid(healthbar):
		healthbar.max_value = max_health
		healthbar.value = max_health
		healthbar.health = max_health
	return true
