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
const DIFFICULTY_SPEED_MULT: float = 0.05

## ---------- State ----------
var score: int = 0
var high_score: int = 0
var is_playing: bool = false
var elapsed_time: float = 0.0
var difficulty_level: int = 0

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

## ---------- World helpers ----------
func random_world_position() -> Vector2:
	var hw := WorldWrap.HALF_WORLD
	return Vector2(
		randf_range(-hw, hw),
		randf_range(-hw, hw)
	)
