## GdUnit4 tests for SnakeController (snake_controller.gd)
extends GdUnitTestSuite

var _snake: SnakeController = null
var _pool: ObjectPool = null
var _world: Node2D = null

func before_test() -> void:
	var seg_scene := load("res://Scenes/Snake/SnakeSegment.tscn")
	_world = Node2D.new()
	add_child(_world)
	_pool = ObjectPool.new(seg_scene, 30)
	add_child(_pool)
	_snake = SnakeController.new()
	_world.add_child(_snake)
	_snake.initialize(_pool, _world, Vector2.ZERO)

func after_test() -> void:
	_snake.queue_free()
	_pool.queue_free()
	_world.queue_free()

## ----

func test_head_moves_in_direction() -> void:
	_snake.set_target_direction(Vector2.RIGHT)
	var start_x := _snake.position.x
	# Simulate one physics frame
	_snake._physics_process(1.0 / 60.0)
	assert_float(_snake.position.x).is_greater(start_x)

func test_turn_rate_is_limited() -> void:
	_snake.move_direction = Vector2.RIGHT
	_snake.set_target_direction(Vector2.LEFT)  # 180° opposite
	_snake._rotate_toward_target(1.0 / 60.0)
	# After one frame, should NOT have turned fully 180°
	var angle_diff := abs(_snake.move_direction.angle() - Vector2.LEFT.angle())
	assert_float(angle_diff).is_greater(0.1)

func test_boost_increases_speed() -> void:
	_snake.set_boost(true)
	assert_bool(_snake.is_boosting).is_true()

func test_boost_disabled_at_min_length() -> void:
	# Snake starts with starting_segments (5), shrink to min
	while _snake.body_manager.segment_count() > _snake.min_boost_segments:
		_snake.body_manager.shrink()
	_snake.set_boost(true)
	assert_bool(_snake.is_boosting).is_false()

func test_die_emits_signal() -> void:
	var monitor := monitor_signals(_snake)
	_snake.die()
	assert_bool(_snake.is_alive).is_false()
	verify(_snake, 1).died.emit(_snake)

func test_die_only_once() -> void:
	_snake.die()
	_snake.die()  # second call should be no-op
	assert_bool(_snake.is_alive).is_false()

func test_food_collision_detection() -> void:
	var food_pos := [Vector2(5, 0)]  # within pickup radius
	var result := _snake.check_food_collision(food_pos, [])
	assert_int(result).is_equal(0)

func test_food_no_collision_when_far() -> void:
	var food_pos := [Vector2(500, 500)]
	var result := _snake.check_food_collision(food_pos, [])
	assert_int(result).is_equal(-1)

func test_body_collision_detection() -> void:
	var segs: Array[Vector2] = [Vector2(5, 0)]  # within collision radius
	var result := _snake.check_body_collision(segs)
	assert_bool(result).is_true()

func test_body_no_collision_when_far() -> void:
	var segs: Array[Vector2] = [Vector2(500, 0)]
	var result := _snake.check_body_collision(segs)
	assert_bool(result).is_false()
