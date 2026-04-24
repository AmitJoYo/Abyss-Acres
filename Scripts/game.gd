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

var _food_pool: ObjectPool = null
var _segment_pool: ObjectPool = null
var _food_nodes: Array[Node2D] = []
var _bot_snakes: Array[SnakeController] = []
var _all_snakes: Array[SnakeController] = []   # player + bots
var _ghost_renderer: GhostRenderer = null
var _bot_respawn_queue: Array[float] = []       # timers
var _next_snake_id: int = 1
var _ambient_particles: AmbientParticles = null
var _bg_shader_rect: ColorRect = null
var _crown_sprite: Sprite2D = null
var _grid_node: Node2D = null
var _physics_frame: int = 0
var _king_indicator: Node2D = null

## Power-up state
var _powerups: Array[Powerup] = []
var _powerup_spawn_timer: float = 8.0
const _POWERUP_SPAWN_INTERVAL_MIN := 12.0
const _POWERUP_SPAWN_INTERVAL_MAX := 22.0
const _POWERUP_MAX_ON_MAP := 5

## Textures loaded from PNG assets
var _tex_head: Texture2D = null
var _tex_bot_head: Texture2D = null
var _tex_segment: Texture2D = null
var _tex_food: Texture2D = null
var _head_textures: Array[Texture2D] = []
var _food_textures: Array[Texture2D] = []
var _grass_texture: Texture2D = null

const _HEAD_TEXTURE_PATHS := [
	"res://png/ui/cow.png",
	"res://png/ui/Pig.png",
	"res://png/ui/Chiken.png",
	"res://png/ui/Sheep.png",
]
const _FOOD_TEXTURE_PATHS := [
	"res://png/ui/food_apple.png",
	"res://png/ui/food_corn.png",
	"res://png/ui/food_carrot.png",
	"res://png/ui/food_cabbage.png",
]
const _SEGMENT_TEXTURE_PATH := "res://png/ui/segment.png"
const _GRASS_TEXTURE_PATH := "res://png/ui/grass_tile.png"

const _CROWN_EMOJI := "👑"

## Per-skin segment tint colors (matches SKIN order: Cow, Pig, Chicken, Sheep)
const _SKIN_SEGMENT_COLORS := [
	Color(0.75, 0.95, 0.7),   # Cow — soft green
	Color(1.0, 0.72, 0.78),   # Pig — pink
	Color(1.0, 0.92, 0.55),   # Chicken — warm yellow
	Color(0.85, 0.85, 0.95),  # Sheep — light blue-gray
]

## Target display sizes (pixels)
const _HEAD_DISPLAY_SIZE := 48.0
const _FOOD_DISPLAY_SIZE := 36.0
const _SEGMENT_DISPLAY_SIZE := 18.0

## ---------- Lifecycle ----------
func _ready() -> void:
	_load_textures()
	_setup_pools()
	_setup_ghost_renderer()
	_setup_background_layers()
	_setup_world_grid()
	_setup_player()
	_spawn_initial_food()
	_spawn_initial_bots()
	_setup_ambient_particles()
	_setup_king_indicator()
	GameManager.start_game()
	# Defer music start so first frame renders before any audio decode hitch
	call_deferred("_start_music")

func _start_music() -> void:
	AudioManager.play_music()

func _notification(what: int) -> void:
	# Android back button / system back gesture should return to main menu,
	# not quit the app.
	if what == NOTIFICATION_WM_GO_BACK_REQUEST:
		get_viewport().set_input_as_handled()
		_return_to_menu()

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		_return_to_menu()

func _return_to_menu() -> void:
	GameManager.is_playing = false
	AudioManager.stop_music()
	get_tree().change_scene_to_file("res://Scenes/Main.tscn")

func _physics_process(delta: float) -> void:
	if not GameManager.is_playing:
		return
	_physics_frame += 1
	_center_world_on_player()
	_update_camera()
	if _physics_frame % 3 == 0:
		_feed_ai_data()
	_check_all_food_collisions()
	if _physics_frame % 2 == 0:
		_check_all_death_collisions()
	_apply_magnet_pull(delta)
	_check_powerup_pickups()
	_tick_powerup_spawn(delta)
	_tick_food_lifetimes(delta)
	_update_ghost_renderer()
	if _physics_frame % 5 == 0:
		_update_minimap()
	_process_bot_respawns(delta)
	_process_screen_shake(delta)
	_tick_mode(delta)
	# Update bot speeds every 120 frames (~2 sec) for difficulty scaling
	if _physics_frame % 120 == 0:
		_update_bot_difficulty()
	_update_crown()
	_update_king_indicator()

## ---------- Setup ----------
func _setup_pools() -> void:
	_segment_pool = ObjectPool.new(SEGMENT_SCENE)
	_segment_pool.name = "SegmentPool"
	add_child(_segment_pool)
	_segment_pool.preallocate(200)

	_food_pool = ObjectPool.new(FOOD_SCENE)
	_food_pool.name = "FoodPool"
	add_child(_food_pool)
	_food_pool.preallocate(GameManager.MAX_FOOD * 3)

	GameManager.segment_pool = _segment_pool
	GameManager.food_pool = _food_pool
	_apply_texture_to_pool(_segment_pool, _tex_segment, _SEGMENT_DISPLAY_SIZE)
	_apply_texture_to_pool(_food_pool, _tex_food, _FOOD_DISPLAY_SIZE)

func _setup_ghost_renderer() -> void:
	_ghost_renderer = GhostRenderer.new()
	_ghost_renderer.name = "GhostRenderer"
	world.add_child(_ghost_renderer)
	_ghost_renderer.setup(_tex_segment, _tex_head, _SEGMENT_DISPLAY_SIZE, _HEAD_DISPLAY_SIZE)

func _setup_player() -> void:
	var player_input: PlayerInput = player_node.get_node("PlayerInput") if player_node.has_node("PlayerInput") else null
	player_node.snake_id = 0
	var skin_idx := clampi(GameManager.selected_skin_index, 0, _head_textures.size() - 1)
	player_node.body_manager.segment_color = _SKIN_SEGMENT_COLORS[skin_idx]
	player_node.initialize(_segment_pool, world, Vector2.ZERO)
	player_node.died.connect(_on_snake_died)
	_all_snakes.append(player_node)
	_apply_sprite_texture(player_node, _head_textures[skin_idx], _HEAD_DISPLAY_SIZE)

	if hud and hud.has_method("setup"):
		hud.setup(player_node, player_input)

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

	# Add visible sprite
	var spr := Sprite2D.new()
	spr.name = "Sprite"
	bot_node.add_child(spr)

	# Assign skin
	var bot_skin := (_next_snake_id) % _head_textures.size()

	world.add_child(bot_node)

	# Now _ready() has run, body_manager is valid
	_apply_sprite_texture(bot_node, _head_textures[bot_skin], _HEAD_DISPLAY_SIZE)
	bot_node.body_manager.segment_color = _SKIN_SEGMENT_COLORS[bot_skin]

	# Spawn at random edge position
	var spawn_pos := _random_edge_position()
	bot_node.initialize(_segment_pool, world, spawn_pos)
	bot_node.died.connect(_on_snake_died)

	# Assign random personality so bots feel distinct
	if brain.has_method("set_personality"):
		brain.set_personality(randi() % AIBrain.PERSONALITY_NAMES.size())

	# Scale speed and size with difficulty
	bot_node.base_speed = 200.0 * GameManager.get_bot_speed_multiplier()
	bot_node.starting_segments = GameManager.get_bot_starting_segments()
	bot_node.turn_rate = 6.0  # slightly sharper turns than player

	_bot_snakes.append(bot_node)
	_all_snakes.append(bot_node)

## Food economy: a small starter pool seeds the early game, then food only
## comes from snake deaths. A hard cap keeps the per-frame collision/AI cost
## bounded no matter how many bots die in a row. Food also expires after a
## few seconds so the board self-cleans even when nobody eats it.
const _INITIAL_FOOD_COUNT := 60
const _MAX_FOOD_ON_MAP := 250
const _FOOD_LIFETIME_SEC := 12.0  # despawn after this many seconds
const _FOOD_FADE_TIME := 1.5      # last N seconds: fade alpha to telegraph despawn
var _food_ages: Array[float] = []  # parallel to _food_nodes

func _spawn_initial_food() -> void:
	for i in _INITIAL_FOOD_COUNT:
		_spawn_food_at(GameManager.random_world_position())

func _spawn_food_at(pos: Vector2) -> void:
	var food := _food_pool.acquire() as Node2D
	if food:
		if food.get_parent() != world:
			if food.get_parent():
				food.reparent(world)
			else:
				world.add_child(food)
		food.position = pos
		food.modulate.a = 1.0
		# Apply random food texture
		var food_tex := _food_textures[randi() % _food_textures.size()]
		_apply_sprite_texture(food, food_tex, _FOOD_DISPLAY_SIZE)
		_food_nodes.append(food)
		_food_ages.append(0.0)

## Tick food ages and despawn anything older than _FOOD_LIFETIME_SEC. Called
## from _physics_process. Walks back-to-front so we can remove in place.
func _tick_food_lifetimes(delta: float) -> void:
	var i := _food_nodes.size() - 1
	while i >= 0:
		_food_ages[i] += delta
		var age := _food_ages[i]
		var food := _food_nodes[i]
		if age >= _FOOD_LIFETIME_SEC:
			if is_instance_valid(food):
				_food_pool.release(food)
			_food_nodes.remove_at(i)
			_food_ages.remove_at(i)
		elif age >= _FOOD_LIFETIME_SEC - _FOOD_FADE_TIME and is_instance_valid(food):
			var t := (_FOOD_LIFETIME_SEC - age) / _FOOD_FADE_TIME
			food.modulate.a = clampf(t, 0.0, 1.0)
		i -= 1

## ---------- Camera ----------
func _update_camera() -> void:
	if player_node and player_node.is_alive and camera:
		# Camera follows the player so the recenter step can happen lazily
		camera.position = player_node.position
		var seg_count := player_node.body_manager.segment_count()
		var target_zoom := lerpf(1.0, 0.7, clampf(seg_count / 300.0, 0.0, 1.0))
		camera.zoom = camera.zoom.lerp(Vector2(target_zoom, target_zoom), 0.02)

## ---------- AI Data Feed ----------
func _feed_ai_data() -> void:
	var head_positions: Array[Vector2] = []
	var head_lengths: Array[int] = []
	var snake_ids: Array[int] = []
	for snake in _all_snakes:
		if snake.is_alive:
			head_positions.append(snake.position)
			head_lengths.append(snake.body_manager.segment_count())
			snake_ids.append(snake.snake_id)

	var food_positions: Array[Vector2] = []
	for food in _food_nodes:
		food_positions.append(food.position)

	for bot in _bot_snakes:
		if not bot.is_alive:
			continue
		var brain: AIBrain = bot.get_node("AIBrain") if bot.has_node("AIBrain") else null
		if brain:
			brain.nearby_food_positions = food_positions
			brain.nearby_head_positions = head_positions
			brain.nearby_head_lengths = head_lengths
			brain.nearby_snake_ids = snake_ids

## ---------- Ghost Rendering ----------
func _update_ghost_renderer() -> void:
	if not _ghost_renderer or not player_node or not player_node.is_alive:
		return
	var seg_positions := player_node.body_manager.get_segment_positions()
	_ghost_renderer.update_ghosts(player_node.position, seg_positions, player_node.rotation)

## ---------- Minimap ----------
func _update_minimap() -> void:
	var minimap: Minimap = hud._minimap if hud and "_minimap" in hud else null
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
	# Build spatial hash of food for O(1) lookup per snake
	var cell_size := 60.0
	var food_grid := {}  # Vector2i → Array[int] (indices into _food_nodes)
	for i in _food_nodes.size():
		var fp: Vector2 = _food_nodes[i].position
		var cell := Vector2i(int(floorf(fp.x / cell_size)), int(floorf(fp.y / cell_size)))
		if not food_grid.has(cell):
			food_grid[cell] = []
		food_grid[cell].append(i)

	var eaten_indices: Array[int] = []
	for snake in _all_snakes:
		if not snake.is_alive:
			continue
		var hx := int(floorf(snake.position.x / cell_size))
		var hy := int(floorf(snake.position.y / cell_size))
		for cx in range(hx - 1, hx + 2):
			for cy in range(hy - 1, hy + 2):
				var cell := Vector2i(cx, cy)
				if not food_grid.has(cell):
					continue
				for idx in food_grid[cell]:
					if idx in eaten_indices:
						continue
					var food := _food_nodes[idx]
					if WorldWrap.wrapped_distance(snake.position, food.position) < snake.food_pickup_radius:
						snake.on_eat_food(food, 1, 10)
						if snake.snake_id == 0:
							AudioManager.play_eat()
						_food_pool.release(food)
						eaten_indices.append(idx)

	# Remove eaten food in reverse order. No respawn — the only new food on the
	# map comes from snake deaths (see `_on_snake_died`). Keeps the board from
	# accumulating crops and tanking framerate over time.
	eaten_indices.sort()
	for k in range(eaten_indices.size() - 1, -1, -1):
		var idx: int = eaten_indices[k]
		_food_nodes.remove_at(idx)
		_food_ages.remove_at(idx)

func _check_all_death_collisions() -> void:
	# Snapshot alive snakes to avoid modification during iteration
	var alive_snakes: Array[SnakeController] = []
	for snake in _all_snakes:
		if snake.is_alive:
			alive_snakes.append(snake)

	# Build spatial hash of all body segments for fast lookup
	var seg_grid := {}  # Dictionary[Vector2i, Array] — grid cell → [{pos, owner_id}]
	var cell_size := 80.0  # ~4x collision radius
	var hw := WorldWrap.HALF_WORLD
	var ws := WorldWrap.WORLD_SIZE
	for snake in alive_snakes:
		var segs := snake.body_manager.get_segment_positions()
		# Cache on snake for self-collision check later
		snake.set_meta("_cached_segs", segs)
		# Sample every 3rd segment into the hash. Segments are 8px apart, so a
		# stride of 3 still gives a 24px sample density — well below the smallest
		# collision radius (~20px). Cuts insertion cost ~3x for long snakes.
		var stride := 3
		var k := 1
		while k < segs.size():
			var pos := segs[k]
			var cell := Vector2i(int(floorf(pos.x / cell_size)), int(floorf(pos.y / cell_size)))
			var entry := {"pos": pos, "id": snake.snake_id}
			if not seg_grid.has(cell):
				seg_grid[cell] = []
			seg_grid[cell].append(entry)
			# Insert wrapped copies near world edges for torus collision
			var near_x := absf(pos.x) > hw - cell_size
			var near_y := absf(pos.y) > hw - cell_size
			if near_x:
				var wc := Vector2i(int(floorf((pos.x - signf(pos.x) * ws) / cell_size)), cell.y)
				if not seg_grid.has(wc):
					seg_grid[wc] = []
				seg_grid[wc].append(entry)
			if near_y:
				var wc := Vector2i(cell.x, int(floorf((pos.y - signf(pos.y) * ws) / cell_size)))
				if not seg_grid.has(wc):
					seg_grid[wc] = []
				seg_grid[wc].append(entry)
			if near_x and near_y:
				var wc := Vector2i(int(floorf((pos.x - signf(pos.x) * ws) / cell_size)), int(floorf((pos.y - signf(pos.y) * ws) / cell_size)))
				if not seg_grid.has(wc):
					seg_grid[wc] = []
				seg_grid[wc].append(entry)
			k += stride

	for snake in alive_snakes:
		if not snake.is_alive:
			continue

		# Head-to-head: if two heads are close, both die
		for other in alive_snakes:
			if other == snake or not other.is_alive:
				continue
			if WorldWrap.wrapped_distance(snake.position, other.position) < snake.collision_radius + other.collision_radius:
				snake.die()
				other.die()
				break
		if not snake.is_alive:
			continue

		# Check head against spatial hash (other snakes' body segments)
		var hx := int(floorf(snake.position.x / cell_size))
		var hy := int(floorf(snake.position.y / cell_size))
		var hit := false
		for cx in range(hx - 1, hx + 2):
			if hit:
				break
			for cy in range(hy - 1, hy + 2):
				if hit:
					break
				var cell := Vector2i(cx, cy)
				if not seg_grid.has(cell):
					continue
				for entry in seg_grid[cell]:
					if entry["id"] == snake.snake_id:
						continue  # skip own segments (handled separately)
					if WorldWrap.wrapped_distance(snake.position, entry["pos"]) < snake.collision_radius:
						snake.die()
						# Award kill credit
						if entry["id"] == 0:
							GameManager.add_score(100)
						GameManager.snake_killed.emit(entry["id"], snake.snake_id)
						hit = true
						break
		if not snake.is_alive:
			continue

		# Self-collision — only for snakes long enough that the head can
		# legitimately loop back over its own tail. Skip ~80% of the body so a
		# normal turn never registers as self-hit.
		var own_segs: Array = snake.get_meta("_cached_segs", [])
		var seg_count: int = own_segs.size()
		if seg_count < 120:
			continue
		var self_skip := maxi(100, int(seg_count * 0.8))
		var self_radius := snake.collision_radius * 0.25
		for j in range(self_skip, seg_count):
			if WorldWrap.wrapped_distance(snake.position, own_segs[j]) < self_radius:
				snake.die()
				break

## ---------- Bot Respawns ----------
func _process_bot_respawns(delta: float) -> void:
	# Last Snake Standing: bots never respawn
	if GameManager.is_last_standing():
		_bot_respawn_queue.clear()
		return
	var i := 0
	while i < _bot_respawn_queue.size():
		_bot_respawn_queue[i] -= delta
		if _bot_respawn_queue[i] <= 0.0:
			_bot_respawn_queue.remove_at(i)
			_spawn_bot()
		else:
			i += 1
	# Difficulty scaling — spawn extra bots when difficulty allows more
	var target_bots := GameManager.get_max_bots()
	var alive_bots := 0
	for bot in _bot_snakes:
		if bot.is_alive:
			alive_bots += 1
	var pending := _bot_respawn_queue.size()
	while alive_bots + pending < target_bots:
		_bot_respawn_queue.append(randf_range(1.0, 3.0))
		pending += 1

## ---------- Difficulty ----------
func _update_bot_difficulty() -> void:
	var speed_mult := GameManager.get_bot_speed_multiplier()
	for bot in _bot_snakes:
		if bot.is_alive:
			bot.base_speed = 200.0 * speed_mult

## ---------- Game Modes ----------
## Anchor for shrinking-arena center; shifts with world recenter so it stays
## in the same on-screen spot relative to the player's spawn point.
var _arena_center: Vector2 = Vector2.ZERO

func _tick_mode(_delta: float) -> void:
	if GameManager.is_timed():
		if GameManager.time_remaining() <= 0.0 and player_node and player_node.is_alive:
			player_node.die()
		return

	if GameManager.is_shrinking():
		var r := GameManager.current_arena_radius()
		# Kill snakes drifting outside the playable circle
		for snake in _all_snakes:
			if not is_instance_valid(snake) or not snake.is_alive:
				continue
			if WorldWrap.wrapped_distance(snake.position, _arena_center) > r:
				snake.die()
		return

	if GameManager.is_last_standing():
		var alive_bots := 0
		for bot in _bot_snakes:
			if bot.is_alive:
				alive_bots += 1
		if alive_bots == 0 and player_node and player_node.is_alive:
			# Player wins — award bonus and end the run
			GameManager.add_score(1000)
			GameManager.end_game()

## ---------- Events ----------
func _on_snake_died(snake: SnakeController) -> void:
	# Death VFX
	var death_scene := ThemeManager.get_death_particle_scene()
	DeathVFX.spawn(death_scene, world, snake.position)

	# Death sound
	if snake.snake_id == 0:
		AudioManager.play_death()

	# Convert body into food. Drop every other segment so deaths feel like a
	# real harvest, but respect the global cap.
	var seg_positions := snake.body_manager.get_segment_positions()
	snake.body_manager.clear()
	var drop_stride := 2  # one food pellet per 2 segments (~16px apart)
	var i := 0
	while i < seg_positions.size():
		if _food_nodes.size() >= _MAX_FOOD_ON_MAP:
			break
		_spawn_food_at(seg_positions[i])
		i += drop_stride

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
	# Background shader rect (grass wind for meadow)
	_bg_shader_rect = ColorRect.new()
	_bg_shader_rect.name = "BackgroundShader"
	_bg_shader_rect.anchors_preset = Control.PRESET_FULL_RECT
	_bg_shader_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_bg_shader_rect.z_index = -100
	var bg_shader := ThemeManager.get_background_shader()
	if bg_shader:
		var mat := ShaderMaterial.new()
		mat.shader = bg_shader
		_bg_shader_rect.material = mat

func _setup_ambient_particles() -> void:
	# Use butterfly PNGs as ambient particles instead of theme scene
	var butterfly_paths := [
		"res://png/ui/butterfly_01.png",
		"res://png/ui/butterfly_02.png",
		"res://png/ui/butterfly_03.png",
		"res://png/ui/butterfly_04.png",
	]
	var butterfly_textures: Array[Texture2D] = []
	for path in butterfly_paths:
		var tex := load(path) as Texture2D
		if tex:
			butterfly_textures.append(tex)
	if butterfly_textures.size() > 0:
		_spawn_butterflies(butterfly_textures)
	else:
		# Fallback to theme-provided particles
		var scene := ThemeManager.get_ambient_particle_scene()
		if scene:
			var inst := scene.instantiate()
			if inst is AmbientParticles:
				_ambient_particles = inst
				_ambient_particles.setup(camera)
				add_child(_ambient_particles)

func _spawn_butterflies(textures: Array[Texture2D]) -> void:
	# Scatter butterflies randomly across the world — they drift on their own
	for i in 20:
		var butterfly := _Butterfly.new()
		butterfly.texture = textures[i % textures.size()]
		butterfly.scale = Vector2(0.5, 0.5)
		butterfly.z_index = 5
		butterfly.modulate.a = 0.75
		# Random position within a large area
		butterfly.position = Vector2(
			randf_range(-WorldWrap.HALF_WORLD * 0.8, WorldWrap.HALF_WORLD * 0.8),
			randf_range(-WorldWrap.HALF_WORLD * 0.8, WorldWrap.HALF_WORLD * 0.8)
		)
		world.add_child(butterfly)

func _setup_king_indicator() -> void:
	_king_indicator = Node2D.new()
	_king_indicator.name = "KingIndicator"
	_king_indicator.z_index = 20
	_king_indicator.visible = false
	add_child(_king_indicator)

func _update_king_indicator() -> void:
	if not player_node or not player_node.is_alive:
		if _king_indicator:
			_king_indicator.visible = false
		return

	# Find the longest alive snake (the king)
	var longest: SnakeController = null
	var max_len := 0
	for snake in _all_snakes:
		if snake.is_alive:
			var seg_count := snake.body_manager.segment_count()
			if seg_count > max_len:
				max_len = seg_count
				longest = snake

	if not longest or longest == player_node:
		# Player IS the king, or no king found
		_king_indicator.visible = false
		return

	_king_indicator.visible = true
	# Direction from player (at origin) to king
	var dir := WorldWrap.wrap_delta(longest.position - player_node.position).normalized()
	# Place arrow at edge of screen (180px from player) — follow player so it tracks the camera
	var indicator_dist := 180.0
	_king_indicator.position = player_node.position + dir * indicator_dist
	_king_indicator.rotation = dir.angle()
	_king_indicator.queue_redraw()

	# Draw arrow if not drawn yet
	if _king_indicator.get_child_count() == 0:
		var arrow := _KingArrow.new()
		_king_indicator.add_child(arrow)

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

## ---------- Power-ups ----------
func _tick_powerup_spawn(delta: float) -> void:
	_powerup_spawn_timer -= delta
	if _powerup_spawn_timer > 0.0:
		return
	_powerup_spawn_timer = randf_range(_POWERUP_SPAWN_INTERVAL_MIN, _POWERUP_SPAWN_INTERVAL_MAX)
	if _powerups.size() >= _POWERUP_MAX_ON_MAP:
		return
	_spawn_powerup()

func _spawn_powerup() -> void:
	var pu := Powerup.new()
	pu.kind = randi() % 4
	# Spawn near player but not on top of them
	var anchor := player_node.position if player_node and player_node.is_alive else Vector2.ZERO
	var angle := randf() * TAU
	var dist := randf_range(280.0, 700.0)
	pu.position = WorldWrap.wrap_position(anchor + Vector2(cos(angle), sin(angle)) * dist)
	world.add_child(pu)
	_powerups.append(pu)

func _check_powerup_pickups() -> void:
	if _powerups.is_empty():
		return
	var pickup_radius := 30.0
	var i := _powerups.size() - 1
	while i >= 0:
		var pu := _powerups[i]
		var picked := false
		for snake in _all_snakes:
			if not snake.is_alive:
				continue
			if WorldWrap.wrapped_distance(snake.position, pu.position) < pickup_radius:
				snake.apply_powerup(pu.kind)
				if snake.snake_id == 0:
					AudioManager.play_eat()  # reuse eat ding for pickup
				picked = true
				break
		if picked:
			pu.queue_free()
			_powerups.remove_at(i)
		i -= 1

func _apply_magnet_pull(delta: float) -> void:
	# Only the player gets visible magnet pull (cheap, focused)
	if not player_node or not player_node.is_alive:
		return
	if player_node.magnet_timer <= 0.0:
		return
	var range_sq := player_node.MAGNET_RANGE * player_node.MAGNET_RANGE
	var pull_step := player_node.MAGNET_PULL_SPEED * delta
	var head := player_node.position
	for food in _food_nodes:
		if not is_instance_valid(food):
			continue
		var d := WorldWrap.wrap_delta(head - food.position)
		var dl_sq := d.length_squared()
		if dl_sq > range_sq or dl_sq < 0.01:
			continue
		var move := d.normalized() * pull_step
		food.position = WorldWrap.wrap_position(food.position + move)

## ---------- Helpers ----------
func _random_edge_position() -> Vector2:
	# Spawn bots far from center in a random direction
	var angle := randf() * TAU
	var dist := randf_range(WorldWrap.HALF_WORLD * 0.5, WorldWrap.HALF_WORLD * 0.9)
	return Vector2(cos(angle), sin(angle)) * dist

## ---------- Texture Loading ----------
func _load_textures() -> void:
	# Load head textures
	for path in _HEAD_TEXTURE_PATHS:
		var tex := load(path) as Texture2D
		if tex:
			_head_textures.append(tex)
		else:
			push_warning("Missing head texture: %s" % path)
			_head_textures.append(_create_circle_texture(20, Color.WHITE))

	# Load food textures
	for path in _FOOD_TEXTURE_PATHS:
		var tex := load(path) as Texture2D
		if tex:
			_food_textures.append(tex)
		else:
			push_warning("Missing food texture: %s" % path)
			_food_textures.append(_create_circle_texture(8, Color.RED))

	# Segment texture — use a white circle so per-skin modulate tint shows clearly
	_tex_segment = _create_circle_texture(10, Color.WHITE)

	# Load grass tile
	_grass_texture = load(_GRASS_TEXTURE_PATH) as Texture2D

	# Convenience refs
	var skin_idx := clampi(GameManager.selected_skin_index, 0, _head_textures.size() - 1)
	_tex_head = _head_textures[skin_idx]
	_tex_bot_head = _head_textures[(skin_idx + 1) % _head_textures.size()]
	_tex_food = _food_textures[0]

	# Crown sprite — use generated texture (emoji doesn't render on Android)
	_crown_sprite = Sprite2D.new()
	_crown_sprite.z_index = 10
	_crown_sprite.visible = false
	_crown_sprite.texture = _create_crown_texture()
	_crown_sprite.scale = Vector2(1.5, 1.5)

func _generate_placeholder_textures() -> void:
	_load_textures()

## ---------- Placeholder texture generation ----------
static func _create_circle_texture(radius: int, color: Color) -> ImageTexture:
	var size := radius * 2
	var img := Image.create(size, size, false, Image.FORMAT_RGBA8)
	var center := Vector2(radius, radius)
	for x in size:
		for y in size:
			var dist := Vector2(x, y).distance_to(center)
			if dist <= radius:
				var shade := 1.0 - (dist / float(radius)) * 0.3
				img.set_pixel(x, y, Color(color.r * shade, color.g * shade, color.b * shade, 1.0))
	return ImageTexture.create_from_image(img)

## Create a centered Label showing an emoji at the given font size.
static func _make_emoji_label(emoji: String, font_size: int) -> Label:
	var lbl := Label.new()
	lbl.text = emoji
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	lbl.add_theme_font_size_override("font_size", font_size)
	lbl.size = Vector2(font_size * 2, font_size * 2)
	lbl.position = Vector2(-font_size, -font_size)
	lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return lbl

func _apply_texture_to_pool(pool: ObjectPool, tex: Texture2D, display_size: float = 0.0) -> void:
	for node in pool._pool:
		_apply_sprite_texture(node, tex, display_size)

func _apply_sprite_texture(node: Node, tex: Texture2D, display_size: float = 0.0) -> void:
	var spr := node.get_node("Sprite") as Sprite2D if node.has_node("Sprite") else null
	if spr:
		spr.texture = tex
		if display_size > 0.0 and tex:
			var tex_w := float(tex.get_width())
			spr.scale = Vector2.ONE * (display_size / tex_w)

## Add a centered emoji Label to a Node2D (head, segment, or food).
func _add_emoji_to_node(node: Node, emoji: String, font_size: int) -> void:
	if node.has_node("EmojiLabel"):
		return
	var lbl := _make_emoji_label(emoji, font_size)
	lbl.name = "EmojiLabel"
	node.add_child(lbl)

func _create_crown_texture() -> ImageTexture:
	var w := 24
	var h := 16
	var img := Image.create(w, h, false, Image.FORMAT_RGBA8)
	var gold := Color(1.0, 0.85, 0.0)
	var jewel := Color(1.0, 0.2, 0.2)
	# Base band
	for x in w:
		for y in range(h / 2, h):
			img.set_pixel(x, y, gold)
	# Three peaks
	for peak_x in [4, 12, 20]:
		for py in range(0, h / 2):
			var half_width: int = int(float(py) * 0.6) + 1
			for px in range(peak_x - half_width, peak_x + half_width + 1):
				if px >= 0 and px < w:
					img.set_pixel(px, h / 2 - 1 - py, gold)
	# Jewel dots on peaks
	for peak_x in [4, 12, 20]:
		if peak_x < w and 1 < h:
			img.set_pixel(peak_x, 1, jewel)
	return ImageTexture.create_from_image(img)

## ---------- Crown ----------
func _update_crown() -> void:
	if not _crown_sprite:
		return
	# Find longest alive snake
	var longest: SnakeController = null
	var max_len := 0
	for snake in _all_snakes:
		if snake.is_alive:
			var seg_count := snake.body_manager.segment_count()
			if seg_count > max_len:
				max_len = seg_count
				longest = snake
	if longest:
		if _crown_sprite.get_parent() != longest:
			if _crown_sprite.get_parent():
				_crown_sprite.reparent(longest)
			else:
				longest.add_child(_crown_sprite)
		_crown_sprite.position = Vector2(0, -20)
		_crown_sprite.visible = true
	else:
		_crown_sprite.visible = false

## ---------- World Grid ----------
func _setup_world_grid() -> void:
	_grid_node = _WorldGrid.new()
	_grid_node.z_index = -50
	if _grass_texture:
		_grid_node.grass_texture = _grass_texture
	world.add_child(_grid_node)

## Shift the entire world so the player stays at the origin.
## Only runs when the player has drifted past a threshold — keeps coordinates
## numerically small without paying the cost every frame.
const _RECENTER_THRESHOLD_SQ := 100.0 * 100.0  # rebase when drift > 100 px

func _center_world_on_player() -> void:
	if not player_node or not player_node.is_alive:
		return
	var offset := player_node.position
	if offset.length_squared() < _RECENTER_THRESHOLD_SQ:
		return

	# --- Player ---
	player_node.position = Vector2.ZERO
	player_node.body_manager._history_offset += offset
	for seg in player_node.body_manager._segments:
		if is_instance_valid(seg):
			seg.position = WorldWrap.wrap_position(seg.position - offset)

	# --- Bots ---
	for bot in _bot_snakes:
		if not is_instance_valid(bot) or not bot.is_alive:
			continue
		bot.position = WorldWrap.wrap_position(bot.position - offset)
		bot.body_manager._history_offset += offset
		for seg in bot.body_manager._segments:
			if is_instance_valid(seg):
				seg.position = WorldWrap.wrap_position(seg.position - offset)

	# --- Food ---
	for food in _food_nodes:
		if is_instance_valid(food):
			food.position = WorldWrap.wrap_position(food.position - offset)

	# --- Power-ups (must shift with the world or they appear to chase the player) ---
	for pu in _powerups:
		if is_instance_valid(pu):
			pu.position = WorldWrap.wrap_position(pu.position - offset)

	# --- Grid (fposmod keeps the repeating pattern seamless) ---
	if _grid_node:
		_grid_node.position -= offset
		var tile: float = _grid_node.tile_size if _grid_node.tile_size > 0.0 else 512.0
		_grid_node.position.x = fposmod(_grid_node.position.x, tile)
		_grid_node.position.y = fposmod(_grid_node.position.y, tile)

	# --- Mode-anchored center (shrinking arena) ---
	_arena_center = WorldWrap.wrap_position(_arena_center - offset)

## Draws a seamless tiled grass background (only tiles visible on screen).
class _WorldGrid extends Node2D:
	var grass_texture: Texture2D = null
	var tile_size: float = 512.0

	func _draw() -> void:
		if grass_texture:
			tile_size = float(grass_texture.get_width())
			# Draw enough tiles to cover the viewport (accounting for zoom)
			var half_range := 2400.0  # covers 4800px which handles zoom 0.7 + grid offset
			var x := -half_range
			while x <= half_range:
				var y := -half_range
				while y <= half_range:
					draw_texture(grass_texture, Vector2(x, y))
					y += tile_size
				x += tile_size
		else:
			# Fallback dot grid
			var spacing := 200.0
			var dot_color := Color(1.0, 1.0, 1.0, 0.08)
			var x := -1600.0
			while x <= 1600.0:
				var y := -1600.0
				while y <= 1600.0:
					draw_circle(Vector2(x, y), 3.0, dot_color)
					y += spacing
				x += spacing

## Arrow pointing toward the king snake.
class _KingArrow extends Node2D:
	func _draw() -> void:
		var gold := Color(1.0, 0.85, 0.0, 0.9)
		var red := Color(1.0, 0.2, 0.2, 0.9)
		# Arrow pointing right (parent rotation handles direction)
		var points := PackedVector2Array([
			Vector2(15, 0),
			Vector2(-8, -10),
			Vector2(-3, 0),
			Vector2(-8, 10),
		])
		draw_colored_polygon(points, gold)
		# Small crown icon on the arrow
		draw_circle(Vector2(-12, 0), 6.0, red)
		draw_circle(Vector2(-12, 0), 4.0, gold)

## Self-animating butterfly that drifts randomly.
class _Butterfly extends Sprite2D:
	var _dir: float = 0.0
	var _speed: float = 0.0
	var _turn_timer: float = 0.0
	var _bob_phase: float = 0.0

	func _ready() -> void:
		_dir = randf() * TAU
		_speed = randf_range(15.0, 35.0)
		_turn_timer = randf_range(1.0, 3.0)
		_bob_phase = randf() * TAU

	func _process(delta: float) -> void:
		# Gentle random turning
		_turn_timer -= delta
		if _turn_timer <= 0.0:
			_dir += randf_range(-1.2, 1.2)
			_speed = randf_range(15.0, 35.0)
			_turn_timer = randf_range(1.5, 4.0)

		# Move
		position += Vector2(cos(_dir), sin(_dir)) * _speed * delta

		# Wrap within world bounds
		position = WorldWrap.wrap_position(position)

		# Gentle bobbing scale (wing flap feel)
		_bob_phase += delta * 6.0
		var bob := 0.9 + sin(_bob_phase) * 0.15
		scale = Vector2(0.5 * bob, 0.5)

		# Face movement direction
		rotation = _dir
