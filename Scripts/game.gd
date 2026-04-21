## Game — Main gameplay scene controller.
## Owns the world, spawns player + bots + food, runs collision loop.
extends Node2D

const FOOD_SCENE := preload("res://Scenes/Food/FoodPellet.tscn")
const SEGMENT_SCENE := preload("res://Scenes/Snake/SnakeSegment.tscn")
const SNAKE_HEAD_SCENE := preload("res://Scenes/Snake/SnakeHead.tscn")

@onready var camera: Camera2D = $Camera2D
@onready var hud: CanvasLayer = $HUD
@onready var world: Node2D = $World
@onready var player_node: SnakeController = $World/PlayerSnake
@onready var minimap: Minimap = $HUD/Minimap if has_node("HUD/Minimap") else null

var _food_pool: ObjectPool = null
var _segment_pool: ObjectPool = null
var _food_nodes: Array[Node2D] = []
var _bot_snakes: Array[SnakeController] = []
var _all_snakes: Array[SnakeController] = []   # player + bots
var _ghost_renderer: GhostRenderer = null
var _bot_respawn_queue: Array[float] = []       # timers
var _next_snake_id: int = 1
var _ambient_particles: AmbientParticles = null
var _player_lighting: SnakeLighting = null
var _bg_shader_rect: ColorRect = null
var _chromatic_rect: ColorRect = null

## ---------- Lifecycle ----------
func _ready() -> void:
	_setup_pools()
	_setup_ghost_renderer()
	_setup_background_layers()
	_setup_player()
	_spawn_initial_food()
	_spawn_initial_bots()
	_setup_ambient_particles()
	ThemeManager.theme_changed.connect(_on_theme_changed)
	GameManager.start_game()

func _physics_process(delta: float) -> void:
	if not GameManager.is_playing:
		return
	_update_camera()
	_feed_ai_data()
	_check_all_food_collisions()
	_check_all_death_collisions()
	_update_ghost_renderer()
	_update_minimap()
	_process_bot_respawns(delta)
	_process_screen_shake(delta)

## ---------- Setup ----------
func _setup_pools() -> void:
	_segment_pool = ObjectPool.new(SEGMENT_SCENE, 200)
	_segment_pool.name = "SegmentPool"
	add_child(_segment_pool)

	_food_pool = ObjectPool.new(FOOD_SCENE, GameManager.MAX_FOOD)
	_food_pool.name = "FoodPool"
	add_child(_food_pool)

	GameManager.segment_pool = _segment_pool
	GameManager.food_pool = _food_pool

func _setup_ghost_renderer() -> void:
	_ghost_renderer = GhostRenderer.new()
	_ghost_renderer.name = "GhostRenderer"
	add_child(_ghost_renderer)
	# Textures will be set when theme system provides them (Sprint 3).
	# For now, ghosts use null texture (invisible until art is added).

func _setup_player() -> void:
	var player_input: PlayerInput = player_node.get_node("PlayerInput") if player_node.has_node("PlayerInput") else null
	player_node.snake_id = 0
	player_node.initialize(_segment_pool, world, Vector2.ZERO)
	player_node.died.connect(_on_snake_died)
	_all_snakes.append(player_node)

	if hud and hud.has_method("setup"):
		hud.setup(player_node, player_input)

	_setup_player_lighting()

func _spawn_initial_bots() -> void:
	for i in GameManager.INITIAL_BOTS:
		_spawn_bot()

func _spawn_bot() -> void:
	if _bot_snakes.size() >= GameManager.MAX_BOTS:
		return
	var bot_node := SnakeController.new()
	bot_node.name = "Bot_%d" % _next_snake_id
	bot_node.snake_id = _next_snake_id
	_next_snake_id += 1

	# Replace PlayerInput with AIBrain
	var brain := AIBrain.new()
	brain.name = "AIBrain"
	bot_node.add_child(brain)

	# Add BodyManager
	var bm := BodyManager.new()
	bm.name = "BodyManager"
	bot_node.add_child(bm)

	world.add_child(bot_node)

	# Spawn at random edge position
	var spawn_pos := _random_edge_position()
	bot_node.initialize(_segment_pool, world, spawn_pos)
	bot_node.died.connect(_on_snake_died)

	# Scale speed with difficulty
	bot_node.base_speed = 200.0 * GameManager.get_bot_speed_multiplier()

	_bot_snakes.append(bot_node)
	_all_snakes.append(bot_node)

func _spawn_initial_food() -> void:
	for i in GameManager.MAX_FOOD:
		_spawn_food_at(GameManager.random_world_position())

func _spawn_food_at(pos: Vector2) -> void:
	var food := _food_pool.acquire() as Node2D
	if food:
		food.position = pos
		if food.get_parent() != world:
			world.add_child(food)
		_food_nodes.append(food)

## ---------- Camera ----------
func _update_camera() -> void:
	if player_node and player_node.is_alive and camera:
		var target := player_node.position
		camera.position = camera.position.lerp(target, 0.08)
		# Zoom out as player grows
		var seg_count := player_node.body_manager.segment_count()
		var target_zoom := lerpf(1.0, 0.7, clampf(seg_count / 300.0, 0.0, 1.0))
		camera.zoom = camera.zoom.lerp(Vector2(target_zoom, target_zoom), 0.02)

## ---------- AI Data Feed ----------
func _feed_ai_data() -> void:
	# Collect all head positions and lengths for AI awareness
	var head_positions: Array[Vector2] = []
	var head_lengths: Array[int] = []
	for snake in _all_snakes:
		if snake.is_alive:
			head_positions.append(snake.position)
			head_lengths.append(snake.body_manager.segment_count())

	# Collect food positions
	var food_positions: Array[Vector2] = []
	for food in _food_nodes:
		food_positions.append(food.position)

	# Feed each bot
	for bot in _bot_snakes:
		if not bot.is_alive:
			continue
		var brain: AIBrain = bot.get_node("AIBrain") if bot.has_node("AIBrain") else null
		if brain:
			brain.nearby_food_positions = food_positions
			brain.nearby_head_positions = head_positions
			brain.nearby_head_lengths = head_lengths

## ---------- Ghost Rendering ----------
func _update_ghost_renderer() -> void:
	if not _ghost_renderer or not player_node or not player_node.is_alive:
		return
	var seg_positions := player_node.body_manager.get_segment_positions()
	_ghost_renderer.update_ghosts(player_node.position, seg_positions, player_node.rotation)

## ---------- Minimap ----------
func _update_minimap() -> void:
	if not minimap:
		return
	var bot_positions: Array[Vector2] = []
	for bot in _bot_snakes:
		if bot.is_alive:
			bot_positions.append(bot.position)
	var food_positions: Array[Vector2] = []
	for food in _food_nodes:
		food_positions.append(food.position)
	var player_pos := player_node.position if player_node and player_node.is_alive else Vector2.ZERO
	minimap.update_positions(player_pos, bot_positions, food_positions)

## ---------- Collisions ----------
func _check_all_food_collisions() -> void:
	for snake in _all_snakes:
		if not snake.is_alive:
			continue
		var i := 0
		while i < _food_nodes.size():
			var food := _food_nodes[i]
			if WorldWrap.wrapped_distance(snake.position, food.position) < snake.food_pickup_radius:
				snake.on_eat_food(food, 1, 10)
				_food_pool.release(food)
				_food_nodes.remove_at(i)
				_spawn_food_at(GameManager.random_world_position())
			else:
				i += 1

func _check_all_death_collisions() -> void:
	for snake in _all_snakes:
		if not snake.is_alive:
			continue
		# Check against every OTHER snake's body
		for other in _all_snakes:
			if other == snake or not other.is_alive:
				continue
			var other_segs := other.body_manager.get_segment_positions()
			if snake.check_body_collision(other_segs):
				snake.die()
				# Credit the kill
				if other.snake_id == 0:
					GameManager.add_score(100)
				GameManager.snake_killed.emit(other.snake_id, snake.snake_id)
				break

		# Self-collision (skip first 10 segments)
		if not snake.is_alive:
			continue
		var own_segs := snake.body_manager.get_segment_positions()
		if own_segs.size() > 10:
			for j in range(10, own_segs.size()):
				if WorldWrap.wrapped_distance(snake.position, own_segs[j]) < snake.collision_radius:
					snake.die()
					break

## ---------- Bot Respawns ----------
func _process_bot_respawns(delta: float) -> void:
	var i := 0
	while i < _bot_respawn_queue.size():
		_bot_respawn_queue[i] -= delta
		if _bot_respawn_queue[i] <= 0.0:
			_bot_respawn_queue.remove_at(i)
			_spawn_bot()
		else:
			i += 1

## ---------- Events ----------
func _on_snake_died(snake: SnakeController) -> void:
	# Death VFX
	var death_scene := ThemeManager.get_death_particle_scene()
	DeathVFX.spawn(death_scene, world, snake.position)

	# Convert body into food
	var seg_positions := snake.body_manager.get_segment_positions()
	snake.body_manager.clear()
	for pos in seg_positions:
		_spawn_food_at(pos)

	# Screen shake on player death
	if snake.snake_id == 0 and camera:
		_screen_shake(8.0, 0.3)

	if snake.snake_id == 0:
		# Player died
		GameManager.end_game()
	else:
		# Bot died — remove from lists and queue respawn
		_bot_snakes.erase(snake)
		_all_snakes.erase(snake)
		snake.queue_free()
		_bot_respawn_queue.append(GameManager.BOT_RESPAWN_DELAY)

## ---------- Background & VFX Layers ----------
func _setup_background_layers() -> void:
	# Background shader rect (water distortion for abyss, grass wind for meadow)
	_bg_shader_rect = ColorRect.new()
	_bg_shader_rect.name = "BackgroundShader"
	_bg_shader_rect.anchors_preset = Control.PRESET_FULL_RECT
	_bg_shader_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_bg_shader_rect.z_index = -100
	# Will be configured when theme is applied

	# Chromatic aberration overlay (abyss only)
	_chromatic_rect = ColorRect.new()
	_chromatic_rect.name = "ChromaticAberration"
	_chromatic_rect.anchors_preset = Control.PRESET_FULL_RECT
	_chromatic_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_chromatic_rect.z_index = 100
	_chromatic_rect.visible = false
	var chroma_shader := load("res://Shaders/chromatic_aberration.gdshader") as Shader
	if chroma_shader:
		var mat := ShaderMaterial.new()
		mat.shader = chroma_shader
		_chromatic_rect.material = mat

func _setup_ambient_particles() -> void:
	var scene := ThemeManager.get_ambient_particle_scene()
	if scene:
		var inst := scene.instantiate()
		if inst is AmbientParticles:
			_ambient_particles = inst
			_ambient_particles.setup(camera)
			add_child(_ambient_particles)

func _setup_player_lighting() -> void:
	_player_lighting = SnakeLighting.new()
	_player_lighting.name = "PlayerLighting"
	add_child(_player_lighting)
	_player_lighting.setup(player_node)

func _on_theme_changed(_theme_name: String) -> void:
	# Update chromatic aberration visibility
	if _chromatic_rect:
		_chromatic_rect.visible = ThemeManager.is_abyss()

	# Update background shader
	var bg_shader := ThemeManager.get_background_shader()
	if _bg_shader_rect and bg_shader:
		var mat := ShaderMaterial.new()
		mat.shader = bg_shader
		_bg_shader_rect.material = mat

	# Swap ambient particles
	if _ambient_particles:
		_ambient_particles.queue_free()
		_ambient_particles = null
	_setup_ambient_particles()

var _shake_timer: float = 0.0
var _shake_intensity: float = 0.0

func _screen_shake(intensity: float, duration: float) -> void:
	_shake_intensity = intensity
	_shake_timer = duration

func _process_screen_shake(delta: float) -> void:
	if _shake_timer > 0.0:
		_shake_timer -= delta
		if camera:
			camera.offset = Vector2(
				randf_range(-_shake_intensity, _shake_intensity),
				randf_range(-_shake_intensity, _shake_intensity)
			)
	else:
		if camera:
			camera.offset = Vector2.ZERO

## ---------- Helpers ----------
func _random_edge_position() -> Vector2:
	var hw := WorldWrap.HALF_WORLD
	var side := randi() % 4
	match side:
		0: return Vector2(randf_range(-hw, hw), -hw + 100)  # top
		1: return Vector2(randf_range(-hw, hw),  hw - 100)  # bottom
		2: return Vector2(-hw + 100, randf_range(-hw, hw))  # left
		_: return Vector2( hw - 100, randf_range(-hw, hw))  # right
