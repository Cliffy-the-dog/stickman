extends Line2D

@export var trail_lifespan: float = 0.25
@export var trail_width: float = 45.0
@export var min_move_dist: float = 5.0
@export var lead_offset: float = 25.0

@export var emitting: bool = false:
	set(value):
		emitting = value
		if emitting:
			visible = true
			last_raw_pos = Vector2.ZERO

var point_ages: Array[float] = []
var last_raw_pos: Vector2 = Vector2.ZERO


## Configures trail rendering and clears any existing points.
func _ready() -> void:
	top_level = true
	global_position = Vector2.ZERO
	clear_points()
	point_ages.clear()

	width = trail_width
	joint_mode = Line2D.LINE_JOINT_ROUND
	begin_cap_mode = Line2D.LINE_CAP_ROUND
	end_cap_mode = Line2D.LINE_CAP_ROUND
	antialiased = true

	var curve = Curve.new()
	curve.add_point(Vector2(0.0, 0.0))
	curve.add_point(Vector2(0.5, 1.0))
	curve.add_point(Vector2(1.0, 0.2))
	width_curve = curve

	var grad = Gradient.new()
	grad.set_color(0, Color(1, 1, 1, 0))
	grad.set_color(1, Color(1.5, 1.5, 1.5, 1.0))
	gradient = grad


## Ages trail points, adds new ones while emitting, and hides when faded.
func _process(delta: float) -> void:
	for i in range(point_ages.size() - 1, -1, -1):
		point_ages[i] += delta
		if point_ages[i] > trail_lifespan:
			remove_point(i)
			point_ages.remove_at(i)

	if emitting and get_parent():
		global_position = Vector2.ZERO
		var raw_target = get_parent().global_position
		var target = raw_target

		if last_raw_pos != Vector2.ZERO and last_raw_pos.distance_to(raw_target) > 0.1:
			var move_dir = (raw_target - last_raw_pos).normalized()
			target += move_dir * lead_offset

		last_raw_pos = raw_target

		if points.size() == 0 or points[points.size() - 1].distance_to(target) > min_move_dist:
			add_point(target)
			point_ages.append(0.0)

	if not emitting and points.size() == 0:
		visible = false
