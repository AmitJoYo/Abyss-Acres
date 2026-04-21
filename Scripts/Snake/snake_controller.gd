## SnakeController — Shared base for player and AI snakes.
## Handles movement, boost, growth, death.
## Attach to a SnakeHead scene root (CharacterBody2D or Area2D).
class_name SnakeController
extends Node2D

signal died(snake: SnakeController)
signal ate_food(snake: SnakeController, food_node: Node2D)

## ---------- Tuning ----------
@export var base_speed: float = 200.0
@export var boost_speed: float = 350.0
@export var turn_rate: float = 4.0          # rad/s
@export var starting_segments: int = 5
@export var boost_shrink_interval: float = 0.8
@export var collision_radius: float = 14.0
@export var food_pickup_radius: float = 20.0
@export var min_boost_segments: int = 3

## ---------- Runtime ----------
var move_direction: Vector2 = Vector2.RIGHT
var target_direction: Vector2 = Vector2.RIGHT
var is_boosting: bool = false
var is_alive: bool = true
var snake_id: int = 0                        # unique per snake

var body_manager: BodyManager = null

var _current_speed: float = 0.0
var _boost_timer: float = 0.0

## ---------- Lifecycle ----------
func _ready() -> void:
	body_manager = $BodyManager if has_node("BodyManager") else BodyManager.new()
	if not has_node("BodyManager"):
		body_manager.name = "BodyManager"
		add_child(body_manager)

func initialize(seg_pool: ObjectPool, world_node: Node2D, start_pos: Vector2) -> void:
	position = WorldWrap.wrap_position(start_pos)
	move_direction = Vector2.RIGHT
	target_direction = Vector2.RIGHT
	is_alive = true
	is_boosting = false
	_boost_timer = 0.0
	body_manager.setup(seg_pool, world_node)
	for i in starting_segments:
		body_manager.grow()

func _physics_process(delta: float) -> void:
	if not is_alive:
		return
	_rotate_toward_target(delta)
	_move(delta)
	_handle_boost(delta)
	body_manager.record_head_position(position)
	body_manager.update_segments()

## ---------- Steering (set by player_input or ai_brain) ----------
func set_target_direction(dir: Vector2) -> void:
	if dir.length_squared() > 0.01:
		target_direction = dir.normalized()

func set_boost(active: bool) -> void:
	if active and body_manager.segment_count() <= min_boost_segments:
		is_boosting = false
		return
	is_boosting = active

## ---------- Growth ----------
func on_eat_food(food_node: Node2D, segments_gained: int, points: int) -> void:
	body_manager.grow(segments_gained)
	ate_food.emit(self, food_node)
	if snake_id == 0:  # player
		GameManager.add_score(points)

## ---------- Death ----------
func die() -> void:
	if not is_alive:
		return
	is_alive = false
	died.emit(self)

## ---------- Collision checks (called by Game scene) ----------
func check_food_collision(food_positions: Array, food_nodes: Array) -> int:
	## Returns index of eaten food, or -1.
	for i in food_positions.size():
		if WorldWrap.wrapped_distance(position, food_positions[i]) < food_pickup_radius:
			return i
	return -1

func check_body_collision(other_segments: Array[Vector2]) -> bool:
	for seg_pos in other_segments:
		if WorldWrap.wrapped_distance(position, seg_pos) < collision_radius:
			return true
	return false

## ---------- Internal ----------
func _rotate_toward_target(delta: float) -> void:
	var current_angle := move_direction.angle()
	var target_angle := target_direction.angle()
	var diff := angle_difference(current_angle, target_angle)
	var max_rot := turn_rate * delta
	var clamped := clampf(diff, -max_rot, max_rot)
	var new_angle := current_angle + clamped
	move_direction = Vector2.from_angle(new_angle)
	rotation = new_angle

func _move(delta: float) -> void:
	_current_speed = boost_speed if is_boosting else base_speed
	position += move_direction * _current_speed * delta
	position = WorldWrap.wrap_position(position)

func _handle_boost(delta: float) -> void:
	if not is_boosting:
		_boost_timer = 0.0
		return
	_boost_timer += delta
	if _boost_timer >= boost_shrink_interval:
		_boost_timer -= boost_shrink_interval
		body_manager.shrink()
