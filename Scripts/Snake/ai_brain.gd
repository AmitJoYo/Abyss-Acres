## AIBrain — State-machine AI controller for bot snakes.
## Attach as a child of SnakeHead (replaces PlayerInput for bots).
class_name AIBrain
extends Node

enum State { WANDER, CHASE, AVOID, AGGRESSIVE }

@export var food_detect_range: float = 300.0
@export var threat_detect_range: float = 150.0
@export var aggressive_length_ratio: float = 3.0
@export var avoid_duration: float = 1.0
@export var wander_turn_interval: float = 1.5

var controller: SnakeController = null
var current_state: State = State.WANDER

## External data — set by Game scene each frame.
var nearby_food_positions: Array[Vector2] = []
var nearby_head_positions: Array[Vector2] = []  # other snake heads
var nearby_head_lengths: Array[int] = []         # their segment counts

var _wander_direction: Vector2 = Vector2.RIGHT
var _wander_timer: float = 0.0
var _avoid_timer: float = 0.0
var _avoid_direction: Vector2 = Vector2.ZERO

func _ready() -> void:
	controller = get_parent() as SnakeController
	_randomize_wander()

func _physics_process(delta: float) -> void:
	if controller == null or not controller.is_alive:
		return

	_evaluate_state()

	match current_state:
		State.WANDER:
			_do_wander(delta)
		State.CHASE:
			_do_chase()
		State.AVOID:
			_do_avoid(delta)
		State.AGGRESSIVE:
			_do_aggressive()

## ---------- State Evaluation ----------
func _evaluate_state() -> void:
	# Check threats first (highest priority)
	var nearest_threat := _find_nearest_threat()
	if nearest_threat.length_squared() > 0.01:
		var threat_dist := WorldWrap.wrapped_distance(controller.position, nearest_threat)
		if threat_dist < threat_detect_range:
			if current_state != State.AVOID:
				_avoid_direction = -WorldWrap.wrapped_direction(controller.position, nearest_threat)
				# Perpendicular escape
				_avoid_direction = Vector2(-_avoid_direction.y, _avoid_direction.x)
				_avoid_timer = avoid_duration
			current_state = State.AVOID
			return

	# Check if we're big enough to be aggressive
	var my_length := controller.body_manager.segment_count()
	var target_info := _find_smallest_nearby_snake()
	if target_info["pos"].length_squared() > 0.01:
		if my_length > target_info["length"] * aggressive_length_ratio:
			current_state = State.AGGRESSIVE
			return

	# Check food
	var nearest_food := _find_nearest_food()
	if nearest_food.length_squared() > 0.01:
		var food_dist := WorldWrap.wrapped_distance(controller.position, nearest_food)
		if food_dist < food_detect_range:
			current_state = State.CHASE
			return

	# Default
	current_state = State.WANDER

## ---------- Behaviors ----------
func _do_wander(delta: float) -> void:
	_wander_timer -= delta
	if _wander_timer <= 0.0:
		_randomize_wander()
	controller.set_target_direction(_wander_direction)
	controller.set_boost(false)

func _do_chase() -> void:
	var nearest_food := _find_nearest_food()
	if nearest_food.length_squared() > 0.01:
		var dir := WorldWrap.wrapped_direction(controller.position, nearest_food)
		controller.set_target_direction(dir)
	controller.set_boost(false)

func _do_avoid(delta: float) -> void:
	_avoid_timer -= delta
	controller.set_target_direction(_avoid_direction)
	# Boost to escape if we have enough segments
	controller.set_boost(controller.body_manager.segment_count() > 8)
	if _avoid_timer <= 0.0:
		current_state = State.WANDER

func _do_aggressive() -> void:
	var target := _find_smallest_nearby_snake()
	if target["pos"].length_squared() > 0.01:
		# Circle around the target — steer perpendicular to them
		var to_target := WorldWrap.wrapped_direction(controller.position, target["pos"])
		var perp := Vector2(-to_target.y, to_target.x)
		var dist := WorldWrap.wrapped_distance(controller.position, target["pos"])
		# Mix: steer toward when far, circle when close
		var mix := clampf(1.0 - dist / food_detect_range, 0.0, 1.0)
		var final_dir := (to_target * (1.0 - mix) + perp * mix).normalized()
		controller.set_target_direction(final_dir)
		controller.set_boost(dist < 100.0)
	else:
		current_state = State.WANDER

## ---------- Helpers ----------
func _find_nearest_food() -> Vector2:
	var best_dist := 999999.0
	var best_pos := Vector2.ZERO
	for pos in nearby_food_positions:
		var d := WorldWrap.wrapped_distance(controller.position, pos)
		if d < best_dist:
			best_dist = d
			best_pos = pos
	return best_pos

func _find_nearest_threat() -> Vector2:
	var best_dist := 999999.0
	var best_pos := Vector2.ZERO
	for pos in nearby_head_positions:
		var d := WorldWrap.wrapped_distance(controller.position, pos)
		if d < best_dist and d > 1.0:  # skip self
			best_dist = d
			best_pos = pos
	return best_pos

func _find_smallest_nearby_snake() -> Dictionary:
	var result := {"pos": Vector2.ZERO, "length": 9999}
	for i in nearby_head_positions.size():
		if i >= nearby_head_lengths.size():
			break
		var d := WorldWrap.wrapped_distance(controller.position, nearby_head_positions[i])
		if d < food_detect_range and d > 1.0 and nearby_head_lengths[i] < result["length"]:
			result["pos"] = nearby_head_positions[i]
			result["length"] = nearby_head_lengths[i]
	return result

func _randomize_wander() -> void:
	var angle := randf() * TAU
	_wander_direction = Vector2.from_angle(angle)
	_wander_timer = wander_turn_interval + randf() * 1.0
