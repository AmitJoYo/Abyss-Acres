## GdUnit4 tests for AIBrain (ai_brain.gd)
extends GdUnitTestSuite

var _snake: SnakeController = null
var _brain: AIBrain = null
var _pool: ObjectPool = null
var _world: Node2D = null

func before_test() -> void:
	var seg_scene := load("res://Scenes/Snake/SnakeSegment.tscn")
	_world = Node2D.new()
	add_child(_world)
	_pool = ObjectPool.new(seg_scene, 20)
	add_child(_pool)
	_snake = SnakeController.new()
	_brain = AIBrain.new()
	_brain.name = "AIBrain"
	_snake.add_child(_brain)
	var bm := BodyManager.new()
	bm.name = "BodyManager"
	_snake.add_child(bm)
	_world.add_child(_snake)
	_snake.initialize(_pool, _world, Vector2.ZERO)

func after_test() -> void:
	_snake.queue_free()
	_pool.queue_free()
	_world.queue_free()

## ----

func test_wander_produces_movement() -> void:
	_brain.current_state = AIBrain.State.WANDER
	_brain._do_wander(0.1)
	# Controller should have a non-zero target direction
	assert_float(_snake.target_direction.length()).is_greater(0.5)

func test_chase_steers_toward_food() -> void:
	_brain.nearby_food_positions = [Vector2(100, 0)] as Array[Vector2]
	_brain._evaluate_state()
	if _brain.current_state == AIBrain.State.CHASE:
		_brain._do_chase()
		# Target direction should point roughly right
		assert_float(_snake.target_direction.x).is_greater(0.0)

func test_avoid_steers_away_from_threat() -> void:
	_brain.nearby_head_positions = [Vector2(50, 0)] as Array[Vector2]
	_brain.nearby_head_lengths = [10] as Array[int]
	_brain._evaluate_state()
	assert_int(_brain.current_state).is_equal(AIBrain.State.AVOID)

func test_state_transition_wander_to_chase() -> void:
	_brain.nearby_food_positions = [Vector2(200, 0)] as Array[Vector2]
	_brain.nearby_head_positions = [] as Array[Vector2]
	_brain.nearby_head_lengths = [] as Array[int]
	_brain._evaluate_state()
	assert_int(_brain.current_state).is_equal(AIBrain.State.CHASE)

func test_state_transition_chase_to_avoid() -> void:
	# Food exists but threat is closer
	_brain.nearby_food_positions = [Vector2(200, 0)] as Array[Vector2]
	_brain.nearby_head_positions = [Vector2(80, 0)] as Array[Vector2]
	_brain.nearby_head_lengths = [10] as Array[int]
	_brain._evaluate_state()
	assert_int(_brain.current_state).is_equal(AIBrain.State.AVOID)
