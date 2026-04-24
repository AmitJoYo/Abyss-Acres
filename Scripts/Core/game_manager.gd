## GameManager — Autoload singleton. Owns game state, score, spawning.
extends Node

signal game_started
signal game_over(final_score: int)
signal score_changed(new_score: int)
signal snake_killed(killer_id: int, victim_id: int)

## ---------- Constants ----------
const MAX_FOOD: int = 120
const FOOD_RESPAWN_DELAY: float = 1.5
const MAX_BOTS: int = 15
const BOT_RESPAWN_DELAY: float = 3.0
const INITIAL_BOTS: int = 5
const DIFFICULTY_INTERVAL: float = 60.0
const DIFFICULTY_SPEED_MULT: float = 0.08
const DIFFICULTY_MAX_BOTS_PER_LEVEL: int = 2

## ---------- Game Modes ----------
enum Mode { CLASSIC, TIMED, SHRINKING, LAST_STANDING }
const MODE_NAMES := ["Classic", "Timed 3min", "Shrinking", "Last Standing"]
const TIMED_DURATION: float = 180.0          # 3 minutes
const SHRINK_INITIAL_RADIUS: float = 1900.0  # almost full world
const SHRINK_FINAL_RADIUS: float = 350.0
const SHRINK_DURATION: float = 240.0          # shrinks over 4 minutes

var selected_mode: int = Mode.CLASSIC

func is_timed() -> bool: return selected_mode == Mode.TIMED
func is_shrinking() -> bool: return selected_mode == Mode.SHRINKING
func is_last_standing() -> bool: return selected_mode == Mode.LAST_STANDING

func time_remaining() -> float:
	if not is_timed():
		return 0.0
	return maxf(0.0, TIMED_DURATION - elapsed_time)

func current_arena_radius() -> float:
	if not is_shrinking():
		return 99999.0
	var t := clampf(elapsed_time / SHRINK_DURATION, 0.0, 1.0)
	return lerpf(SHRINK_INITIAL_RADIUS, SHRINK_FINAL_RADIUS, t)

## ---------- State ----------
var score: int = 0
var high_score: int = 0
var is_playing: bool = false
var elapsed_time: float = 0.0
var difficulty_level: int = 0
var selected_skin_index: int = 0   # chosen from main menu

## Node references (assigned by Game scene)
var player_snake: Node = null
var food_pool: ObjectPool = null
var segment_pool: ObjectPool = null

## ---------- Lifecycle ----------
func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS

func _process(delta: float) -> void:
	if not is_playing:
		return
	elapsed_time += delta
	var new_level := int(elapsed_time / DIFFICULTY_INTERVAL)
	if new_level > difficulty_level:
		difficulty_level = new_level

## ---------- Game Flow ----------
func start_game() -> void:
	score = 0
	elapsed_time = 0.0
	difficulty_level = 0
	is_playing = true
	score_changed.emit(score)
	game_started.emit()

func end_game() -> void:
	is_playing = false
	if score > high_score:
		high_score = score
	game_over.emit(score)

func add_score(points: int) -> void:
	score += points
	score_changed.emit(score)

## ---------- Difficulty ----------
func get_bot_speed_multiplier() -> float:
	return 1.0 + difficulty_level * DIFFICULTY_SPEED_MULT

func get_max_bots() -> int:
	return mini(INITIAL_BOTS + difficulty_level * DIFFICULTY_MAX_BOTS_PER_LEVEL, MAX_BOTS)

func get_bot_starting_segments() -> int:
	return 5 + difficulty_level * 2

## ---------- World helpers ----------
func random_world_position() -> Vector2:
	return WorldWrap.random_world_position()
