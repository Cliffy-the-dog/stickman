extends CharacterBody2D

@onready var healthbar: ProgressBar = $Healthbar
const speed = 600.0
@export var detection_range = 1000.0
@onready var music_manager: Node = %MusicManager
@export var player: Node2D
@onready var nav_agent := $NavigationAgent2D
@onready var animatedSprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var sprite = $AnimatedSprite2D

var not_dying = 1
var movable = 1
var damage_value = 20
var playera = null
var is_chasing = false


## Locates the player node in the scene tree.
func _ready():
	playera = get_tree().root.find_child("Player", true, false)


## Starts chase music and navigates toward the player when in range.
func _physics_process(_delta):
	if playera:
		var distance = position.distance_to(playera.position)
		if distance < detection_range and not is_chasing:
			is_chasing = true
			music_manager.start_chase(get_instance_id())
	if is_chasing == true:
		var dir = to_local(nav_agent.get_next_path_position()).normalized()
		velocity = dir * 1200
		move_and_slide()

	if healthbar.value < 0:
		if healthbar.value - 10 > -1:
			for a in range(damage_value):
				healthbar.value = healthbar.value - 1
				await get_tree().create_timer(0.02).timeout
				healthbar.damage_bar.value = healthbar.value


## Applies damage and plays death animation when health reaches zero.
func take_damage(damage_amount) -> void:
	healthbar.value -= 20
	if healthbar.value < 0:
		healthbar.value = 0
	var direction = 0
	if sprite.flip_h == true:
		direction = 1
	if sprite.flip_h == false:
		direction = -1
	else:
		direction = 0
	if healthbar.value == 0:
		movable = 0
		not_dying = 0
		animatedSprite.play("Die")
		await animatedSprite.animation_finished
		queue_free()
