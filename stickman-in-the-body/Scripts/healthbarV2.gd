extends ProgressBar


@onready var timer: Timer = $Timer
@onready var damage_bar: ProgressBar = $DamageBar


var health = max_value : set = _set_health

func _ready() -> void:
	value = max_value

func _set_health(new_health):
	var prev_health = health
	health = min(max_value, new_health)
	value = health
	
	# I DELETED THE QUEUE_FREE() LOGIC HERE
	
	if health < prev_health:
		@warning_ignore("standalone_expression")
		timer.start()
		
	else:
		damage_bar.value = health


func init_health(_health):
	health = _health
	max_value = health
	value = health
	damage_bar.max_value = health
	damage_bar.value = health

func _on_timer_timeout() -> void:
	damage_bar.value = health
	damage_bar.value = value
func _process(delta: float) -> void:
	rotation = 0
	damage_bar.value = value
