extends CharacterBody2D

const SPEED = 300.0
const JUMP_VELOCITY = -400.0
var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")
# --- Save Data Variables ---
var last_checkpoint: Vector2 = Vector2.ZERO
var skins: int = 0
var damage: float = 10.0 # Or whatever your default starting damage is
var money: int = 0
var has_walljump: bool = false
# --- Nodes ---
@onready var player_anim_player: AnimationPlayer = $PlayerAnimPlayer
# Update this path if your visual node is named something else!
@onready var sprite: Sprite2D = $Sprite2D 

# --- Combo Variables ---
var combo_step: int = 0
var combo_timer: float = 0.0
var is_punching: bool = false
var punch_slide_speed: float = 200.0
var facing_direction: float = 1.0

func _ready() -> void:
	# Connect the animation finished signal via code
	player_anim_player.animation_finished.connect(_on_animation_finished)

func _physics_process(delta: float) -> void:
	# 1. Handle Combo Timer Countdown
	if not is_punching and combo_timer > 0.0:
		combo_timer -= delta
		if combo_timer <= 0.0:
			combo_step = 0 # Time ran out, reset combo

	# 2. Apply Gravity
	if not is_on_floor():
		velocity.y += gravity * delta

	# 3. Handle Jump
	if Input.is_action_just_pressed("ui_up") and is_on_floor() and not is_punching:
		velocity.y = JUMP_VELOCITY
		player_anim_player.play("jumpstart")

	# 4. Handle Attack Input (Make sure "attack" is mapped in your Input Map!)
	if Input.is_action_just_pressed("attack"):
		execute_punch()

	# 5. Handle Movement and Animations
	var direction = Input.get_axis("ui_left", "ui_right")
	
	if not is_punching:
		# Normal movement when not attacking
		if direction != 0:
			velocity.x = direction * SPEED
			facing_direction = sign(direction)
			sprite.flip_h = (facing_direction < 0) # Flips the sprite left
			
			if is_on_floor():
				player_anim_player.play("walk")
		else:
			velocity.x = move_toward(velocity.x, 0, SPEED)
			if is_on_floor():
				player_anim_player.play("Idle")
				
		# In-air animations
		if not is_on_floor():
			if velocity.y < 0 and player_anim_player.current_animation != "jumpstart":
				player_anim_player.play("jump")
			elif velocity.y >= 0:
				player_anim_player.play("leap")
	else:
		# Rapidly slow down the punch slide using friction
		velocity.x = move_toward(velocity.x, 0, SPEED * delta * 8)

	move_and_slide()

func execute_punch() -> void:
	if is_punching:
		return 

	# Progress the combo sequence
	if combo_timer > 0.0:
		combo_step += 1
		if combo_step > 4:
			combo_step = 1 # Loops back to Punch1
	else:
		combo_step = 1

	is_punching = true
	combo_timer = 0.0 
	
	# Apply the forward slide burst
	velocity.x = facing_direction * punch_slide_speed
	
	player_anim_player.play("Punch" + str(combo_step))

func _on_animation_finished(anim_name: String) -> void:
	# Open the 0.2s window when a punch finishes
	if anim_name.begins_with("Punch"):
		is_punching = false
		combo_timer = 0.2
		
	# Seamlessly transition from jumpstart to jump
	if anim_name == "jumpstart":
		player_anim_player.play("jump")
