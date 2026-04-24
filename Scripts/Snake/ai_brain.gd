## AIBrain — State-machine AI controller for bot snakes.
## Attach as a child of SnakeHead (replaces PlayerInput for bots).
class_name AIBrain
extends Node

enum State { WANDER, CHASE, AVOID, AGGRESSIVE, HUNT }

## ---------- Personality ----------
## Distinct behavior profiles. Set via set_personality() right after spawn.
enum Personality { BALANCED, AGGRESSIVE, COWARDLY, HUNTER, GLUTTON }
const PERSONALITY_NAMES := ["Balanced", "Aggressive", "Cowardly", "Hunter", "Glutton"]
var personality: int = Personality.BALANCED

@export var food_detect_range: float = 800.0
@export var threat_detect_range: float = 120.0
@export var hunt_detect_range: float = 400.0
@export var aggressive_length_ratio: float = 2.0
@export var avoid_duration: float = 0.6
@export var avoid_cooldown: float = 3.0
@export var fear_length_ratio: float = 1.5
@export var wander_turn_interval: float = 0.6

## Apply per-personality stat tweaks. Call right after spawn.
func set_personality(p: int) -> void:
	personality = p
	match p:
		Personality.AGGRESSIVE:
			# Quick to attack, slow to flee
			aggressive_length_ratio = 1.2
			fear_length_ratio = 2.5
			threat_detect_range = 80.0
			hunt_detect_range = 520.0
		Personality.COWARDLY:
			# Flees easily, never picks fights
			aggressive_length_ratio = 5.0
			fear_length_ratio = 0.8
			threat_detect_range = 220.0
			avoid_duration = 1.2
			avoid_cooldown = 1.5
		Personality.HUNTER:
			# Chases other snakes' heads to cut them off
			hunt_detect_range = 700.0
			aggressive_length_ratio = 1.6
			fear_length_ratio = 2.0
		Personality.GLUTTON:
			# Lives for food, ignores most threats until close
			food_detect_range = 1400.0
			threat_detect_range = 90.0
			fear_length_ratio = 3.0
			hunt_detect_range = 200.0
		_:
			pass  # BALANCED keeps export defaults

var controller: SnakeController = null
var current_state: State = State.WANDER
var snake_id: int = -1  # set by game to exclude self from head lists

## External data — set by Game scene each frame.
var nearby_food_positions: Array[Vector2] = []
var nearby_head_positions: Array[Vector2] = []
var nearby_head_lengths: Array[int] = []
var nearby_snake_ids: Array[int] = []

var _wander_direction: Vector2 = Vector2.RIGHT
var _wander_timer: float = 0.0
var _avoid_timer: float = 0.0
var _avoid_cooldown_timer: float = 0.0
var _avoid_direction: Vector2 = Vector2.ZERO

func _ready() -> void:
	controller = get_parent() as SnakeController
	_randomize_wander()

func _physics_process(delta: float) -> void:
	if controller == null or not controller.is_alive:
		return

	if _avoid_cooldown_timer > 0.0:
		_avoid_cooldown_timer -= delta

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
		State.HUNT:
			_do_hunt()

## ---------- State Evaluation ----------
func _evaluate_state() -> void:
	var my_length := controller.body_manager.segment_count()

	# Check threats first (highest priority) — avoid bigger snakes' heads
	var threat_info := _find_nearest_bigger_threat()
	if threat_info["pos"].length_squared() > 0.01 and _avoid_cooldown_timer <= 0.0:
		var threat_dist := WorldWrap.wrapped_distance(controller.position, threat_info["pos"])
		if threat_dist < threat_detect_range:
			if current_state != State.AVOID:
				var away := -WorldWrap.wrapped_direction(controller.position, threat_info["pos"])
				_avoid_direction = Vector2(-away.y, away.x)  # perpendicular escape
				_avoid_timer = avoid_duration
			current_state = State.AVOID
			return

	# Check if we're big enough to be aggressive — try to circle smaller snakes
	var target_info := _find_smallest_nearby_snake()
	if target_info["pos"].length_squared() > 0.01:
		if my_length > target_info["length"] * aggressive_length_ratio:
			current_state = State.AGGRESSIVE
			return

	# Hunt mode — cut off any nearby snake by steering in front of them
	var hunt_target := _find_huntable_snake()
	if hunt_target["pos"].length_squared() > 0.01 and my_length > 8:
		current_state = State.HUNT
		return

	# Check food
	var nearest_food := _find_nearest_food()
	if nearest_food.length_squared() > 0.01:
		var food_dist := WorldWrap.wrapped_distance(controller.position, nearest_food)
		if food_dist < food_detect_range:
			current_state = State.CHASE
			return

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
		var dist := WorldWrap.wrapped_distance(controller.position, nearest_food)
		controller.set_boost(dist < 120.0 and controller.body_manager.segment_count() > 8)
	else:
		controller.set_boost(false)

func _do_avoid(delta: float) -> void:
	_avoid_timer -= delta
	controller.set_target_direction(_avoid_direction)
	controller.set_boost(false)
	if _avoid_timer <= 0.0:
		_avoid_cooldown_timer = avoid_cooldown
		current_state = State.WANDER

func _do_aggressive() -> void:
	var target := _find_smallest_nearby_snake()
	if target["pos"].length_squared() > 0.01:
		var to_target := WorldWrap.wrapped_direction(controller.position, target["pos"])
		var perp := Vector2(-to_target.y, to_target.x)
		var dist := WorldWrap.wrapped_distance(controller.position, target["pos"])
		var mix := clampf(1.0 - dist / hunt_detect_range, 0.0, 1.0)
		var final_dir := (to_target * (1.0 - mix) + perp * mix).normalized()
		controller.set_target_direction(final_dir)
		controller.set_boost(dist < 100.0 and controller.body_manager.segment_count() > 6)
	else:
		current_state = State.WANDER

func _do_hunt() -> void:
	var target := _find_huntable_snake()
	if target["pos"].length_squared() > 0.01:
		# Steer to intercept — aim ahead of the target's direction
		var to_target := WorldWrap.wrapped_direction(controller.position, target["pos"])
		var dist := WorldWrap.wrapped_distance(controller.position, target["pos"])
		# Lead the target by steering slightly ahead
		var lead := to_target.rotated(0.3 if randf() > 0.5 else -0.3)
		controller.set_target_direction(lead)
		controller.set_boost(dist < 150.0 and controller.body_manager.segment_count() > 6)
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

func _find_nearest_bigger_threat() -> Dictionary:
	var my_length := controller.body_manager.segment_count()
	var best_dist := 999999.0
	var result := {"pos": Vector2.ZERO, "length": 0}
	for i in nearby_head_positions.size():
		if i >= nearby_snake_ids.size() or nearby_snake_ids[i] == controller.snake_id:
			continue
		if i >= nearby_head_lengths.size():
			break
		# Only fear snakes that are significantly bigger
		if nearby_head_lengths[i] <= int(float(my_length) * fear_length_ratio):
			continue
		var d := WorldWrap.wrapped_distance(controller.position, nearby_head_positions[i])
		if d < best_dist:
			best_dist = d
			result["pos"] = nearby_head_positions[i]
			result["length"] = nearby_head_lengths[i]
	return result

func _find_smallest_nearby_snake() -> Dictionary:
	var result := {"pos": Vector2.ZERO, "length": 9999}
	for i in nearby_head_positions.size():
		if i >= nearby_snake_ids.size() or nearby_snake_ids[i] == controller.snake_id:
			continue
		if i >= nearby_head_lengths.size():
			break
		var d := WorldWrap.wrapped_distance(controller.position, nearby_head_positions[i])
		if d < hunt_detect_range and nearby_head_lengths[i] < result["length"]:
			result["pos"] = nearby_head_positions[i]
			result["length"] = nearby_head_lengths[i]
	return result

func _find_huntable_snake() -> Dictionary:
	var result := {"pos": Vector2.ZERO, "length": 9999}
	for i in nearby_head_positions.size():
		if i >= nearby_snake_ids.size() or nearby_snake_ids[i] == controller.snake_id:
			continue
		if i >= nearby_head_lengths.size():
			break
		var d := WorldWrap.wrapped_distance(controller.position, nearby_head_positions[i])
		if d < hunt_detect_range:
			result["pos"] = nearby_head_positions[i]
			result["length"] = nearby_head_lengths[i]
			return result
	return result

func _randomize_wander() -> void:
	var angle := randf() * TAU
	_wander_direction = Vector2.from_angle(angle)
	_wander_timer = wander_turn_interval + randf() * 0.8
