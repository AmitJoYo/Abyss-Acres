## BodyManager — Handles the position-history buffer and segment placement.
## Attach to the SnakeHead node. Segments are children of the Game world node.
class_name BodyManager
extends Node

## How many history entries between each body segment.
const SEGMENT_SPACING: int = 18
const MAX_SEGMENTS: int = 500

var _history: Array[Vector2] = []        # ring buffer of head positions
var _segments: Array[Node2D] = []        # active segment nodes
var _segment_pool: ObjectPool = null
var _world_node: Node2D = null           # parent for segment nodes
var _ghost_margin: float = 600.0         # screen-width margin for ghosts

## Initialise with references.
func setup(segment_pool: ObjectPool, world_node: Node2D) -> void:
	_segment_pool = segment_pool
	_world_node = world_node
	_history.clear()
	_segments.clear()

## Call every physics frame with the head's current (wrapped) position.
func record_head_position(head_pos: Vector2) -> void:
	_history.push_front(head_pos)
	# Keep buffer only as long as needed
	var needed := (_segments.size() + 1) * SEGMENT_SPACING + 2
	if _history.size() > needed:
		_history.resize(needed)

## Add N body segments at the tail.
func grow(count: int = 1) -> void:
	for i in count:
		if _segments.size() >= MAX_SEGMENTS:
			return
		var seg: Node2D = _segment_pool.acquire()
		_world_node.add_child(seg) if seg.get_parent() == null or seg.get_parent() != _world_node else null
		seg.position = _tail_position()
		_segments.append(seg)

## Remove the last segment (used during boost).
func shrink() -> void:
	if _segments.size() <= 2:
		return
	var seg := _segments.pop_back() as Node2D
	_segment_pool.release(seg)

## Update all segment positions from history buffer (call in _physics_process).
func update_segments() -> void:
	for i in _segments.size():
		var idx: int = (i + 1) * SEGMENT_SPACING
		if idx >= _history.size():
			# Not enough history yet — park at last known
			idx = _history.size() - 1
		if idx < 0:
			continue

		var target_pos: Vector2 = _history[idx]
		var seg: Node2D = _segments[i]

		# Compute wrapped position relative to where the segment currently is
		var delta := WorldWrap.wrap_delta(target_pos - seg.position)
		seg.position = WorldWrap.wrap_position(seg.position + delta)

		# Rotation: face toward the previous segment / head
		var prev_idx: int = maxi(idx - SEGMENT_SPACING, 0)
		var prev_pos: Vector2 = _history[prev_idx]
		var dir := WorldWrap.wrap_delta(prev_pos - target_pos)
		if dir.length_squared() > 0.01:
			seg.rotation = dir.angle()

## Get positions of all segments (for collision checks).
func get_segment_positions() -> Array[Vector2]:
	var positions: Array[Vector2] = []
	positions.resize(_segments.size())
	for i in _segments.size():
		positions[i] = _segments[i].position
	return positions

## Current segment count.
func segment_count() -> int:
	return _segments.size()

## Release all segments back to pool.
func clear() -> void:
	for seg in _segments:
		_segment_pool.release(seg)
	_segments.clear()
	_history.clear()

## ---------- Internal ----------
func _tail_position() -> Vector2:
	if _segments.size() > 0:
		return _segments[-1].position
	if _history.size() > 0:
		return _history[-1]
	return Vector2.ZERO
