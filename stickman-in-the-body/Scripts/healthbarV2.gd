extends ProgressBar

@onready var timer: Timer = $Timer
@onready var damage_bar: ProgressBar = $DamageBar

var health = max_value : set = _set_health


# Initializes the main and damage bars to full health.
func _ready() -> void:
	value = max_value


# Updates health, triggers delayed damage-bar catch-up on damage taken.
func _set_health(new_health) -> void:
	var prev_health = health
	health = min(max_value, new_health)
	value = health

	if health < prev_health:
		@warning_ignore("standalone_expression")
		timer.start()
	else:
		damage_bar.value = health


# Sets starting health and syncs both bars to the same max/value.
func init_health(_health) -> void:
	health = _health
	max_value = health
	value = health
	damage_bar.max_value = health
	damage_bar.value = health


# Snaps the damage bar to the current health after the delay timer expires.
func _on_timer_timeout() -> void:
	damage_bar.value = health
	damage_bar.value = value


# Keeps the bar upright and mirrors its value onto the damage bar each frame.
func _process(_delta: float) -> void:
	rotation = 0
	damage_bar.value = value
