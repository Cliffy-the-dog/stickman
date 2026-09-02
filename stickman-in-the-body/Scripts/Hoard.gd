extends CharacterBody2D

@onready var Target: CharacterBody2D = %Player
@onready var healthbar: ProgressBar = $Healthbar
@onready var Respawnpoint: Area2D = $"../Area2D2"
@onready var character: AnimatedSprite2D = $Character
@onready var video_stream_player: VideoStreamPlayer = $CanvasLayer/VideoStreamPlayer
@onready var pause_menu: Control = $"../Player/Camera2D2/PauseMenu"
@onready var MusicManager: Node = %MusicManager

enum BossState { ASLEEP, WAKING, AWAKENED, DEAD }
var current_state = BossState.ASLEEP

var exists_in_previous_save = true:
	set(value):
		exists_in_previous_save = value
		if not exists_in_previous_save:
			queue_free()
var cooldown = 0
const SPEED = 1200.0
const JUMP_VELOCITY = -1800.0
var distance
var side
var head_scene = load("res://entities/projectiles/head.tscn")

func _ready() -> void:
	if not exists_in_previous_save:
		queue_free()
	velocity = Vector2.ZERO
	healthbar.value = healthbar.max_value
	character.play("Unawakened")
	video_stream_player.hide()

func _physics_process(delta: float) -> void:
	if current_state == BossState.DEAD:
		return
		
	distance = global_position.distance_to(Target.global_position)
	
	match current_state:
		BossState.ASLEEP:
			if distance < 800:
				trigger_awakening()
			else:
				character.play("Unawakened")
				
		BossState.WAKING:
			pass
				
		BossState.AWAKENED:
			combat_loop(delta)

func trigger_awakening():
	if current_state == BossState.WAKING: return
	
	current_state = BossState.WAKING
	character.play("Awakening")
	
	await character.animation_finished
	
	if distance < 800:
		current_state = BossState.AWAKENED
		MusicManager.start_chase(self.name, true)
	else:
		current_state = BossState.ASLEEP
		character.play("Unawakened")

func combat_loop(delta):
	var to_target = Target.global_position - global_position
	side = sign(transform.x.dot(to_target))
	
	if not is_on_floor():
		velocity += get_gravity() * delta
	
	if cooldown == 0:
		cooldown = 1
		Fight()
		character.play("Idle")
	
	move_and_slide()
	
	if Target.healthbar.value <= 0:
		reset_boss()

func reset_boss():
	current_state = BossState.ASLEEP
	healthbar.value = healthbar.max_value
	global_position = Respawnpoint.global_position
	character.play("Unawakened")
	MusicManager.stop_chase(self.name, true)

func take_damage(damage):
	if current_state == BossState.DEAD:
		return

	healthbar.value -= damage
	if healthbar.value <= 0:
		current_state = BossState.DEAD
		await get_tree().create_timer(0.01).timeout
		die_and_play_video()

func die_and_play_video():
	MusicManager.stop_chase(self.name, true)
	
	character.hide()
	healthbar.hide()
	
	for child in get_children():
		if child is CollisionShape2D or child is CollisionPolygon2D:
			child.set_deferred("disabled", true)
	
	video_stream_player.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	video_stream_player.expand = true
	
	video_stream_player.process_mode = Node.PROCESS_MODE_ALWAYS
	get_tree().paused = true
	
	video_stream_player.show()
	video_stream_player.play()
	
	if not video_stream_player.finished.is_connected(_on_video_finished):
		video_stream_player.finished.connect(_on_video_finished)

func _on_video_finished():
	get_tree().paused = false
	queue_free()

# -- Attack Functions --
func Jump():
	velocity.y = JUMP_VELOCITY
	velocity.x = randi_range(-100,100)

func Projectile(target_node: Node2D):
	var head_instance = head_scene.instantiate()
	get_parent().add_child(head_instance)
	head_instance.global_position = global_position
	var direction = (target_node.global_position - global_position).normalized()
	if head_instance.has_method("launch"):
		head_instance.launch(direction, target_node)
		
func Dash():
	velocity.x = SPEED * side
	await get_tree().create_timer(0.3).timeout
	velocity.x = 0

func Fight():
	var RNG = randi_range(1, 5)
	if RNG == 1 or RNG == 2:
		Dash()
	elif RNG == 3 or RNG == 4:
		Projectile(Target)
	elif RNG == 5:
		Jump()
		await get_tree().create_timer(0.1).timeout 
		while not is_on_floor():
			await get_tree().process_frame 
	await get_tree().create_timer(0.3).timeout
	cooldown = 0
