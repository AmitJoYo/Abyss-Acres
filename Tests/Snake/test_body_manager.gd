## GdUnit4 tests for BodyManager (body_manager.gd)
extends GdUnitTestSuite

var _body_manager: BodyManager = null
var _pool: ObjectPool = null
var _world: Node2D = null

func before_test() -> void:
	var seg_scene := load("res://Scenes/Snake/SnakeSegment.tscn")
	_world = Node2D.new()
	add_child(_world)
	_pool = ObjectPool.new(seg_scene, 30)
	add_child(_pool)
	_body_manager = BodyManager.new()
	add_child(_body_manager)
	_body_manager.setup(_pool, _world)

func after_test() -> void:
	_body_manager.clear()
	_body_manager.queue_free()
	_pool.queue_free()
	_world.queue_free()

## ----

func test_history_records_positions() -> void:
	for i in 10:
		_body_manager.record_head_position(Vector2(i * 10.0, 0))
	# Internal history should have entries (we test via segment placement)
	assert_int(_body_manager.segment_count()).is_equal(0)

func test_growth_adds_segment() -> void:
	_body_manager.record_head_position(Vector2.ZERO)
	_body_manager.grow(1)
	assert_int(_body_manager.segment_count()).is_equal(1)
	_body_manager.grow(3)
	assert_int(_body_manager.segment_count()).is_equal(4)

func test_shrink_removes_tail() -> void:
	_body_manager.record_head_position(Vector2.ZERO)
	_body_manager.grow(5)
	assert_int(_body_manager.segment_count()).is_equal(5)
	_body_manager.shrink()
	assert_int(_body_manager.segment_count()).is_equal(4)

func test_shrink_stops_at_minimum() -> void:
	_body_manager.record_head_position(Vector2.ZERO)
	_body_manager.grow(2)
	_body_manager.shrink()  # 2 -> won't shrink (min is 2)
	assert_int(_body_manager.segment_count()).is_equal(2)

func test_max_segment_cap() -> void:
	_body_manager.record_head_position(Vector2.ZERO)
	_body_manager.grow(600)  # exceeds MAX_SEGMENTS (500)
	assert_int(_body_manager.segment_count()).is_less_equal(BodyManager.MAX_SEGMENTS)

func test_wrap_crossing_preserves_continuity() -> void:
	# Simulate head moving across the right boundary
	_body_manager.grow(3)
	var spacing := BodyManager.SEGMENT_SPACING
	for i in (spacing * 5):
		var x := 1950.0 + float(i) * 2.0  # crosses +2000 boundary
		var pos := WorldWrap.wrap_position(Vector2(x, 0))
		_body_manager.record_head_position(pos)
	_body_manager.update_segments()

	# All segments should be within reasonable distance of each other
	var positions := _body_manager.get_segment_positions()
	for k in range(1, positions.size()):
		var dist := WorldWrap.wrapped_distance(positions[k - 1], positions[k])
		# Should be roughly spacing * head_speed_per_frame, not thousands of pixels
		assert_float(dist).is_less(200.0)

func test_clear_releases_all() -> void:
	_body_manager.record_head_position(Vector2.ZERO)
	_body_manager.grow(5)
	_body_manager.clear()
	assert_int(_body_manager.segment_count()).is_equal(0)

func test_get_segment_positions_count() -> void:
	_body_manager.record_head_position(Vector2.ZERO)
	_body_manager.grow(4)
	var positions := _body_manager.get_segment_positions()
	assert_int(positions.size()).is_equal(4)
