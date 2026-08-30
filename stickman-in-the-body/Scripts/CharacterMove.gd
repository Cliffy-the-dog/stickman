extends CharacterBody2D

# --- Node References ---
@onready var visuals: Node2D = $Visuals
@onready var anim_player: AnimationPlayer = $Visuals/PlayerAnimPlayer
@onready var grounder_hitbox: CollisionShape2D = $"Grounder Hitbox"
@onready var fazed_hitbox: Area2D = $"Fazed Hitbox" 
@onready var inventory: Node2D = $Inventory
@export var projectile_scene: PackedScene

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

# --- Adjustable Variables ---
@export var keyframe_x_shift: float = 0.0 
@export var visual_offset_x: float = 190.0 
@export var wall_slide_offset_x: float = 50.0 
@export var pogo_cooldown_duration: float = 0.4
@export var wall_slide_speed: float = 300.0 
@export var push_force = 100.0

# --- Player Stats & Flags ---
var health
var hasbloodbind = false
var bootson = true
const JUMP_VELOCITY = -2200.0
var money = 0.0
var skins = 0
var abletoheal = 1; var damage = 20; var last_checkpoint = Vector2.ZERO; var attackers: Array[Node] = []
var last_floor_pos = Vector2.ZERO; var pause_Idleanimationforce = 0; var damage_taken_in_the_past_0point4seconds = 0
var damage_value = 10; var bouncing_in_progress = 0; var being_touched = 0
var health_upgrades = 1; var SPEED = 1440.0; var healthpause = 0; var is_safe_ground = true
var max_health = 100 + 20 * health_upgrades
var bloodbind_in_progress = 0 
var goo_spawn_cooldown = 0.0
var has_walljump = false
var is_crouching = false
var crouch_cooldown = 0.0

# --- Dash & Movement Variables ---
var is_dashing = false
var dash_timer = 0.0
var dash_direction = 1
var dash_cooldown_timer = 0.0
var is_pogo_sliding = false 
var wall_jump_lock_timer = 0.0 

# --- Pogo Variables ---
var is_pogoing = false
var was_pogoing = false
var pogo_start_y = 0.0
var pogo_direction = 0.0 
var pogo_fall_timer = 0.0 
var pogo_cooldown_timer = 0.0 

# --- Combo Variables ---
var combo_step: int = 0
var combo_timer: float = 0.0
var is_punching: bool = false
var punch_slide_speed: float = 1200.0
var facing_direction: float = 1.0

@onready var default_hitbox_pos_y = grounder_hitbox.position.y

func _ready():
	%SlashArea2.hide()
	%SlashArea2.monitoring = false
	shift_all_keyframe_offsets(keyframe_x_shift)
	anim_player.animation_finished.connect(_on_animation_finished)
	pause_menu.load_game()
	
	_setup_limb_trails()
	
	if is_instance_valid(healthbar):
		healthbar.max_value = 100 + 20 * management.health_upgrades
		healthbar.value = healthbar.max_value
		healthbar.health = healthbar.max_value
		
	if is_instance_valid(bloodbar):
		bloodbar.value = 100
	
	for p in particles: 
		p.show()
		p.emitting = false
		p.restart()
		p.emitting = false
		
	if not %SlashArea2.area_entered.is_connected(_on_slash_area_2_area_entered):
		%SlashArea2.area_entered.connect(_on_slash_area_2_area_entered)

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

func update_limb_trails(step: int) -> void:
	var show_arm_l = is_pogoing or (step == 1 or step == 3 or step == 4)
	var show_arm_r = is_pogoing or (step == 1 or step == 2 or step == 3 or step == 4)
	var show_legs  = is_pogoing or (step == 3)

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

func flash_red():
	var t = create_tween()
	t.tween_property(self, "modulate", Color.DARK_RED, 0.2)
	t.tween_property(self, "modulate", Color.WHITE, 0.4)

func can_uncrouch() -> bool:
	for body in fazed_hitbox.get_overlapping_bodies():
		if body != self: 
			return false
	return true

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

	# Check for Pogo state change to toggle trails automatically
	if is_pogoing != was_pogoing:
		was_pogoing = is_pogoing
		update_limb_trails(combo_step)

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
	
	if is_on_floor() and Input.is_action_just_pressed("Heal") and is_instance_valid(healthbar) and healthbar.value < healthbar.max_value:
		while is_instance_valid(bloodbar) and bloodbar.value > 0 and healthbar.value < healthbar.max_value and abletoheal:
			for p in particles: p.emitting = true
			SPEED = 0
			bloodbar.value -= 1.0 
			healthbar.value += 1.0 
			await get_tree().create_timer(0.02).timeout
			healthbar.health = healthbar.value
		SPEED = 1440
		for p in particles: p.emitting = false

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
		bouncing_in_progress = 0
		
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
			anim_player.play("Pogo" if is_pogo_sliding else "CrouchWalk") 
		elif (anim_player.current_animation == "Walljump" or anim_player.current_animation == "Jumpstart") and anim_player.is_playing():
			pass 
		elif is_on_wall() and not is_on_floor() and velocity.y > 0 and not is_pogoing:
			anim_player.play("Slide")
		elif is_pogoing or bouncing_in_progress: 
			anim_player.play("Pogo") 
		elif is_crouching: 
			anim_player.play("CrouchWalk" if d != 0 else "CrouchIdle")
		elif d and is_on_floor(): 
			anim_player.play("Walk")
		elif not is_on_floor(): 
			anim_player.play("Leap" if d != 0 else "Jump")
		elif d == 0 and is_on_floor(): 
			anim_player.play("Idle")

	if bloodbind_in_progress:
		velocity = Vector2.ZERO
	elif is_dashing:
		velocity.x = dash_direction * 2500.0 
	elif is_pogoing:
		velocity.x = (pogo_direction * velocity.y) * 1.2
	elif is_punching:
		velocity.x = move_toward(velocity.x, 0, SPEED * delta * 8)
	elif wall_jump_lock_timer > 0.0:
		if d != 0: velocity.x = move_toward(velocity.x, d * SPEED, 3000 * delta)
	else:
		velocity.x = d * SPEED if d else move_toward(velocity.x, 0, SPEED)
	
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
			bouncing_in_progress = 0
			
		for i in get_slide_collision_count():
			var collision = get_slide_collision(i)
			if collision.get_normal().y < -0.5:
				var collider = collision.get_collider()
				if collider:
					var is_temporary = collider.has_method("passage") or (collider.get_parent() and collider.get_parent().has_method("passage"))
					is_safe_ground = not is_temporary
					
		if is_safe_ground:
			last_floor_pos = global_position

# --- Combat Functions ---
func execute_punch() -> void:
	if is_punching: return 
	
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
	anim_player.play("Punch" + str(combo_step))
	update_limb_trails(combo_step)

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

func _on_slash_area_2_area_entered(a):
	if a == self or a == fazed_hitbox: return
	var target = a if a.has_method("take_damage") else a.get_parent()
	if target and target.has_method("take_damage") and is_punching: 
		target.take_damage(damage)
		if is_instance_valid(bloodbar):
			bloodbar.value = min(bloodbar.max_value, bloodbar.value + 10)

# --- Hazards & Damage Logic ---
func _on_killzone_body_entered(_b):
	if is_instance_valid(healthbar) and healthbar.value > 0 and not damage_taken_in_the_past_0point4seconds: apply_damage(10)
	if is_instance_valid(healthbar) and healthbar.value > 0: global_position = last_floor_pos
	else: respawn_logic()

func respawn_logic():
	attackers.clear()
	
	if last_checkpoint != Vector2.ZERO: 
		global_position = last_checkpoint
		if is_instance_valid(healthbar):
			healthbar.value = healthbar.max_value 
	else: 
		get_tree().reload_current_scene()

func apply_damage(val):
	abletoheal = 0
	damage_taken_in_the_past_0point4seconds = 1
	flash_red()
	
	if is_instance_valid(healthbar):
		healthbar.value -= val
		healthbar.health = healthbar.value
		if "damage_bar" in healthbar and healthbar.damage_bar:
			healthbar.damage_bar.value = healthbar.health
			
	await get_tree().create_timer(0.4).timeout
	damage_taken_in_the_past_0point4seconds = 0
	abletoheal = 1

func die_sequence():
	healthpause = 1; SPEED = 0; pause_Idleanimationforce = 1
	anim_player.play("Die") 
	await anim_player.animation_finished
	pause_Idleanimationforce = 0; healthpause = 0; SPEED = 1440
	respawn_logic() 

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
		bouncing_in_progress = 1
		return
	if b.has_method("take_damage") and not attackers.has(b): 
		attackers.append(b)

func _on_fazed_hitbox_body_exited(b):
	if attackers.has(b): attackers.erase(b)

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
		bouncing_in_progress = 1
		return
		
	if is_hazard and not attackers.has(a): 
		attackers.append(a)
			
	if a.has_method("AreaIdentifier"):
		SPEED = 0
		if is_instance_valid(healthbar):
			while healthbar.value < healthbar.max_value: 
				healthbar.value += 1; await get_tree().create_timer(0.02).timeout
			healthbar.health = healthbar.max_value
		SPEED = 1440; last_checkpoint = global_position; pause_menu.save_game()
	if a.has_method("GITGUD"): 
		SPEED = 700; await get_tree().create_timer(0.2).timeout; SPEED = 1440

func _on_fazed_hitbox_area_exited(a):
	if attackers.has(a): 
		attackers.erase(a)

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
	
	if Input.is_action_just_pressed("BloodSpell") and not bloodbind_in_progress: 
		if projectile_scene != null:
			if is_instance_valid(bloodbar) and bloodbar.value >= 10.0: 
				bloodbar.value -= 10.0 
				shoot_projectile()
		else:
			print("DEBUG: Projectile Scene is missing in Inspector!")

# --- Spells ---
func shoot_projectile() -> void:
	if projectile_scene == null: return
	bloodbind_in_progress = 1
	pause_Idleanimationforce = 1
	SPEED = 0
	anim_player.play("Bloodbind Launch")
		
	var proj = projectile_scene.instantiate()
	proj.is_flipped = visuals.scale.x < 0
	proj.global_position = global_position
	proj.player_ref = self
	proj.direction = Vector2.LEFT if visuals.scale.x < 0 else Vector2.RIGHT
	get_tree().current_scene.add_child(proj)

func finish_bloodbind() -> void:
	bloodbind_in_progress = 0
	pause_Idleanimationforce = 0
	SPEED = 1440
	anim_player.play("Idle")

func trigger_endlag_punishment() -> void:
	$AudioStreamPlayer2D.play()
	visuals.position.y = -100 # <--- Shifts sprite up by 100px
	anim_player.play("Bloodbind Endlag")
	await anim_player.animation_finished
	visuals.position.y = 0    # <--- Snaps back down
	$AudioStreamPlayer2D.playing = false
	finish_bloodbind()
func take_damage(amount):
	if (is_pogoing and velocity.y > 0) or bouncing_in_progress: 
		return
		
	if not damage_taken_in_the_past_0point4seconds and not healthpause:
		apply_damage(amount)
