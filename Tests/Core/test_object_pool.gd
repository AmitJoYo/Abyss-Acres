## GdUnit4 tests for ObjectPool (object_pool.gd)
extends GdUnitTestSuite

var _pool: ObjectPool = null
var _test_scene: PackedScene = null

func before() -> void:
	# Use FoodPellet as a simple test scene
	_test_scene = load("res://Scenes/Food/FoodPellet.tscn")

func before_test() -> void:
	_pool = ObjectPool.new(_test_scene, 10)
	add_child(_pool)

func after_test() -> void:
	_pool.queue_free()

## ----

func test_pool_initializes_with_correct_count() -> void:
	assert_int(_pool.available_count()).is_equal(10)
	assert_int(_pool.active_count()).is_equal(0)

func test_acquire_returns_instance() -> void:
	var inst := _pool.acquire()
	assert_object(inst).is_not_null()

func test_acquire_sets_active() -> void:
	var inst := _pool.acquire()
	assert_bool(inst.visible).is_true()
	assert_int(inst.process_mode).is_equal(Node.PROCESS_MODE_INHERIT)
	assert_int(_pool.active_count()).is_equal(1)

func test_release_returns_to_pool() -> void:
	var inst := _pool.acquire()
	_pool.release(inst)
	assert_bool(inst.visible).is_false()
	assert_int(_pool.active_count()).is_equal(0)
	assert_int(_pool.available_count()).is_equal(10)

func test_pool_exhaustion_creates_new() -> void:
	# Acquire more than initial count
	var nodes: Array[Node] = []
	for i in 15:
		nodes.append(_pool.acquire())
	assert_int(_pool.active_count()).is_equal(15)
	# Pool grew beyond initial 10
	for n in nodes:
		_pool.release(n)

func test_double_release_is_safe() -> void:
	var inst := _pool.acquire()
	_pool.release(inst)
	_pool.release(inst)  # second release should not crash
	assert_int(_pool.available_count()).is_greater_equal(10)

func test_release_all() -> void:
	for i in 5:
		_pool.acquire()
	assert_int(_pool.active_count()).is_equal(5)
	_pool.release_all()
	assert_int(_pool.active_count()).is_equal(0)
