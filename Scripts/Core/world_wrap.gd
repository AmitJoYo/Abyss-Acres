## WorldWrap — Autoload singleton for torus-world math.
## All positions live in [-HALF_WORLD, +HALF_WORLD] on each axis.
extends Node

const WORLD_SIZE: float = 4000.0
const HALF_WORLD: float = WORLD_SIZE / 2.0

## Wrap an absolute position into the canonical world range.
static func wrap_position(pos: Vector2) -> Vector2:
	pos.x = fposmod(pos.x + HALF_WORLD, WORLD_SIZE) - HALF_WORLD
	pos.y = fposmod(pos.y + HALF_WORLD, WORLD_SIZE) - HALF_WORLD
	return pos

## Return the shortest-path delta between two points on the torus.
static func wrap_delta(delta: Vector2) -> Vector2:
	delta.x = delta.x - WORLD_SIZE * roundf(delta.x / WORLD_SIZE)
	delta.y = delta.y - WORLD_SIZE * roundf(delta.y / WORLD_SIZE)
	return delta

## Wrapped Euclidean distance (shortest path on torus).
static func wrapped_distance(a: Vector2, b: Vector2) -> float:
	return wrap_delta(a - b).length()

## Wrapped direction from A toward B (unit vector, shortest path).
static func wrapped_direction(from: Vector2, to: Vector2) -> Vector2:
	var d := wrap_delta(to - from)
	return d.normalized() if d.length_squared() > 0.0001 else Vector2.ZERO

## Check if a position is near a world edge (within margin pixels).
static func is_near_edge(pos: Vector2, margin: float) -> Dictionary:
	return {
		"left":   pos.x < -HALF_WORLD + margin,
		"right":  pos.x >  HALF_WORLD - margin,
		"top":    pos.y < -HALF_WORLD + margin,
		"bottom": pos.y >  HALF_WORLD - margin,
	}

## Return ghost positions for edge rendering (0-2 extra positions).
static func get_ghost_positions(pos: Vector2, margin: float) -> Array[Vector2]:
	var ghosts: Array[Vector2] = []
	var near := is_near_edge(pos, margin)

	var offset_x := 0.0
	var offset_y := 0.0

	if near["left"]:
		offset_x = WORLD_SIZE
	elif near["right"]:
		offset_x = -WORLD_SIZE

	if near["top"]:
		offset_y = WORLD_SIZE
	elif near["bottom"]:
		offset_y = -WORLD_SIZE

	if offset_x != 0.0:
		ghosts.append(pos + Vector2(offset_x, 0))
	if offset_y != 0.0:
		ghosts.append(pos + Vector2(0, offset_y))
	if offset_x != 0.0 and offset_y != 0.0:
		ghosts.append(pos + Vector2(offset_x, offset_y))

	return ghosts
