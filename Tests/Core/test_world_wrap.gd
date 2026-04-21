## GdUnit4 tests for WorldWrap (world_wrap.gd)
## Covers: wrap_position, wrap_delta, wrapped_distance, get_ghost_positions
extends GdUnitTestSuite

const WW := preload("res://Scripts/Core/world_wrap.gd")
const HALF := 2000.0
const SIZE := 4000.0

## ---- wrap_position ----

func test_center_stays_unchanged() -> void:
	var result := WW.wrap_position(Vector2(0, 0))
	assert_vector2(result).is_equal_approx(Vector2(0, 0), Vector2(0.01, 0.01))

func test_positive_overflow_wraps() -> void:
	var result := WW.wrap_position(Vector2(2500, 0))
	assert_vector2(result).is_equal_approx(Vector2(-1500, 0), Vector2(0.01, 0.01))

func test_negative_overflow_wraps() -> void:
	var result := WW.wrap_position(Vector2(-2500, 0))
	assert_vector2(result).is_equal_approx(Vector2(1500, 0), Vector2(0.01, 0.01))

func test_exact_boundary_wraps() -> void:
	var result := WW.wrap_position(Vector2(2000, 2000))
	assert_vector2(result).is_equal_approx(Vector2(-2000, -2000), Vector2(0.01, 0.01))

func test_both_axes_overflow() -> void:
	var result := WW.wrap_position(Vector2(3000, -3000))
	assert_vector2(result).is_equal_approx(Vector2(-1000, 1000), Vector2(0.01, 0.01))

## ---- wrap_delta ----

func test_small_delta_unchanged() -> void:
	var result := WW.wrap_delta(Vector2(10, -5))
	assert_vector2(result).is_equal_approx(Vector2(10, -5), Vector2(0.01, 0.01))

func test_cross_boundary_delta_positive() -> void:
	var result := WW.wrap_delta(Vector2(3500, 0))
	assert_vector2(result).is_equal_approx(Vector2(-500, 0), Vector2(0.01, 0.01))

func test_cross_boundary_delta_negative() -> void:
	var result := WW.wrap_delta(Vector2(-3800, 0))
	assert_vector2(result).is_equal_approx(Vector2(200, 0), Vector2(0.01, 0.01))

func test_diagonal_boundary_cross() -> void:
	var result := WW.wrap_delta(Vector2(3500, -3500))
	assert_vector2(result).is_equal_approx(Vector2(-500, 500), Vector2(0.01, 0.01))

## ---- wrapped_distance ----

func test_same_point_distance_zero() -> void:
	var result := WW.wrapped_distance(Vector2.ZERO, Vector2.ZERO)
	assert_float(result).is_equal_approx(0.0, 0.01)

func test_normal_distance() -> void:
	var result := WW.wrapped_distance(Vector2(100, 0), Vector2(0, 0))
	assert_float(result).is_equal_approx(100.0, 0.01)

func test_shorter_through_wrap() -> void:
	# Naive distance = 3800, wrapped = 200
	var result := WW.wrapped_distance(Vector2(1900, 0), Vector2(-1900, 0))
	assert_float(result).is_equal_approx(200.0, 0.01)

## ---- wrapped_direction ----

func test_direction_through_wrap() -> void:
	# From +1900 to -1900: shortest path is +200 (going right through the edge)
	var result := WW.wrapped_direction(Vector2(1900, 0), Vector2(-1900, 0))
	assert_float(result.x).is_greater(0.0)

func test_direction_same_point_is_zero() -> void:
	var result := WW.wrapped_direction(Vector2(50, 50), Vector2(50, 50))
	assert_vector2(result).is_equal_approx(Vector2.ZERO, Vector2(0.01, 0.01))

## ---- get_ghost_positions ----

func test_no_ghosts_at_center() -> void:
	var ghosts := WW.get_ghost_positions(Vector2(0, 0), 600.0)
	assert_int(ghosts.size()).is_equal(0)

func test_ghost_near_right_edge() -> void:
	var ghosts := WW.get_ghost_positions(Vector2(1800, 0), 600.0)
	assert_int(ghosts.size()).is_greater_equal(1)
	# Should have a ghost at x = 1800 - 4000 = -2200
	var found := false
	for g in ghosts:
		if abs(g.x - (-2200.0)) < 1.0:
			found = true
	assert_bool(found).is_true()

func test_ghost_near_corner() -> void:
	# Near top-right corner: should get 3 ghosts (right, top, diagonal)
	var ghosts := WW.get_ghost_positions(Vector2(1800, -1800), 600.0)
	assert_int(ghosts.size()).is_equal(3)
