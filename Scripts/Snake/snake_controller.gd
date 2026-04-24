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
@export var turn_rate: float = 5.0          # rad/s
@export var starting_segments: int = 5
@export var boost_shrink_interval: float = 0.8
@export var collision_radius: float = 20.0
@export var food_pickup_radius: float = 22.0
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
## Brief immunity right after spawn/respawn so a freshly placed snake can't die
## from a one-frame overlap with a nearby body / wrapped segment.
var _spawn_invuln_timer: float = 0.0
const SPAWN_INVULN_DURATION := 1.25

## ---------- Power-ups ----------
var speed_powerup_timer: float = 0.0   # > 0 = speed powerup active
var shield_active: bool = false        # consumed on next death
var magnet_timer: float = 0.0          # > 0 = pulls food toward head
var score_x2_timer: float = 0.0        # > 0 = double food points

const SPEED_POWERUP_MULT := 1.5
const SPEED_POWERUP_DURATION := 5.0
const MAGNET_DURATION := 8.0
const MAGNET_RANGE := 220.0
const MAGNET_PULL_SPEED := 320.0
const SCORE_X2_DURATION := 10.0

## ---------- Lifecycle ----------
func _ready() -> void:
	body_manager = $BodyManager if has_node("BodyManager") else BodyManager.new()
	if not has_node("BodyManager"):
		body_manager.name = "BodyManager"
		add_child(body_manager)
	_setup_shield_visual()

var _shield_visual: _ShieldRing = null

func _setup_shield_visual() -> void:
	_shield_visual = _ShieldRing.new()
	_shield_visual.name = "ShieldRing"
	_shield_visual.z_index = 5
	add_child(_shield_visual)

class _ShieldRing extends Node2D:
	var radius: float = 28.0
	var pulse: float = 0.0

	func _process(delta: float) -> void:
		pulse += delta * 3.0
		if visible:
			queue_redraw()

	func _draw() -> void:
		var alpha := 0.45 + 0.25 * sin(pulse)
		draw_arc(Vector2.ZERO, radius, 0.0, TAU, 32, Color(0.4, 0.85, 1.0, alpha), 3.0)

func initialize(seg_pool: ObjectPool, world_node: Node2D, start_pos: Vector2) -> void:
	position = WorldWrap.wrap_position(start_pos)
	move_direction = Vector2.RIGHT
	target_direction = Vector2.RIGHT
	is_alive = true
	is_boosting = false
	_boost_timer = 0.0
	_spawn_invuln_timer = SPAWN_INVULN_DURATION
	body_manager.setup(seg_pool, world_node)
	# Seed history so segments spawn behind the head, not at origin
	for i in (starting_segments + 1) * body_manager.SEGMENT_SPACING:
		body_manager.record_head_position(position)
	for i in starting_segments:
		body_manager.grow()

func _physics_process(delta: float) -> void:
	if not is_alive:
		return
	_tick_powerups(delta)
	_rotate_toward_target(delta)
	_move(delta)
	_handle_boost(delta)
	body_manager.record_head_position(position)
	body_manager.update_segments()

func _tick_powerups(delta: float) -> void:
	if speed_powerup_timer > 0.0:
		speed_powerup_timer = maxf(0.0, speed_powerup_timer - delta)
	if magnet_timer > 0.0:
		magnet_timer = maxf(0.0, magnet_timer - delta)
	if score_x2_timer > 0.0:
		score_x2_timer = maxf(0.0, score_x2_timer - delta)
	if _spawn_invuln_timer > 0.0:
		_spawn_invuln_timer = maxf(0.0, _spawn_invuln_timer - delta)
	if _shield_visual:
		_shield_visual.visible = shield_active or _spawn_invuln_timer > 0.0

## Apply a power-up pickup effect.
func apply_powerup(kind: int) -> void:
	match kind:
		0:  # SPEED
			speed_powerup_timer = SPEED_POWERUP_DURATION
		1:  # SHIELD
			shield_active = true
		2:  # MAGNET
			magnet_timer = MAGNET_DURATION
		3:  # SCORE_X2
			score_x2_timer = SCORE_X2_DURATION

## ---------- Steering (set by player_input or ai_brain) ----------
func set_target_direction(dir: Vector2) -> void:
	if dir.length_squared() > 0.01:
		target_direction = dir.normalized()

func set_boost(active: bool) -> void:
	if active and body_manager.segment_count() <= min_boost_segments:
		is_boosting = false
		return
	var was_boosting := is_boosting
	is_boosting = active
	if is_boosting and not was_boosting and snake_id == 0:
		AudioManager.play_boost()

## ---------- Growth ----------
func on_eat_food(food_node: Node2D, segments_gained: int, points: int) -> void:
	body_manager.grow(segments_gained)
	ate_food.emit(self, food_node)
	if snake_id == 0:  # player
		var awarded := points * 2 if score_x2_timer > 0.0 else points
		GameManager.add_score(awarded)

## ---------- Death ----------
func die() -> void:
	if not is_alive:
		return
	# Spawn invincibility absorbs all deaths during the window
	if _spawn_invuln_timer > 0.0:
		return
	# Shield absorbs one death
	if shield_active:
		shield_active = false
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
	var base := boost_speed if is_boosting else base_speed
	if speed_powerup_timer > 0.0:
		base *= SPEED_POWERUP_MULT
	_current_speed = base
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
