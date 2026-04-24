## BodyManager — Handles the position-history buffer and segment placement.
## Attach to the SnakeHead node. Segments are children of the Game world node.
class_name BodyManager
extends Node

## How many history entries between each body segment.
const SEGMENT_SPACING: int = 8
## Cap chosen for mobile perf — 200 segments × ~8 snakes already taxes the
## per-frame collision/render loop. Increase only if you've profiled headroom.
const MAX_SEGMENTS: int = 180
## Fixed-size ring buffer covering the longest possible snake plus a small margin.
const _HISTORY_CAPACITY: int = (MAX_SEGMENTS + 2) * SEGMENT_SPACING

var _history: PackedVector2Array = PackedVector2Array()  # ring buffer of head positions
var _history_head: int = 0               # index of the most recently written entry
var _history_count: int = 0              # number of valid entries (≤ _HISTORY_CAPACITY)
var _history_offset: Vector2 = Vector2.ZERO  # accumulated world shift (applied on read)
var _segments: Array[Node2D] = []        # active segment nodes
var _segment_pool: ObjectPool = null
var _world_node: Node2D = null           # parent for segment nodes
var _ghost_margin: float = 600.0         # screen-width margin for ghosts
var segment_color: Color = Color.WHITE   # tint color for this snake's segments

## Initialise with references.
func setup(segment_pool: ObjectPool, world_node: Node2D) -> void:
	_segment_pool = segment_pool
	_world_node = world_node
	if _history.size() != _HISTORY_CAPACITY:
		_history.resize(_HISTORY_CAPACITY)
	_history_head = 0
	_history_count = 0
	_history_offset = Vector2.ZERO
	_segments.clear()

## Call every physics frame with the head's current (wrapped) position.
func record_head_position(head_pos: Vector2) -> void:
	# Advance ring buffer head and write current position
	_history_head = (_history_head + 1) % _HISTORY_CAPACITY
	_history[_history_head] = head_pos + _history_offset
	if _history_count < _HISTORY_CAPACITY:
		_history_count += 1

## Read the history entry that's `back` steps before the most recent write.
## Returns Vector2.ZERO if the buffer doesn't have that much history yet.
func _history_at(back: int) -> Vector2:
	if _history_count == 0:
		return Vector2.ZERO
	var clamped: int = mini(back, _history_count - 1)
	var idx: int = (_history_head - clamped + _HISTORY_CAPACITY) % _HISTORY_CAPACITY
	return _history[idx]

## Add N body segments at the tail.
func grow(count: int = 1) -> void:
	for i in count:
		if _segments.size() >= MAX_SEGMENTS:
			return
		var seg: Node2D = _segment_pool.acquire()
		if seg.get_parent() != _world_node:
			if seg.get_parent():
				seg.reparent(_world_node)
			else:
				_world_node.add_child(seg)
		seg.position = _tail_position()
		seg.modulate = segment_color
		_segments.append(seg)

## Remove the last segment (used during boost).
func shrink() -> void:
	if _segments.size() <= 2:
		return
	var seg := _segments.pop_back() as Node2D
	seg.modulate = Color.WHITE
	_segment_pool.release(seg)

## Update all segment positions from history buffer (call in _physics_process).
func update_segments() -> void:
	if _history_count == 0:
		return
	var seg_count: int = _segments.size()
	for i in seg_count:
		var back: int = (i + 1) * SEGMENT_SPACING
		var target_pos: Vector2 = _history_at(back) - _history_offset
		var seg: Node2D = _segments[i]

		var delta := WorldWrap.wrap_delta(target_pos - seg.position)
		seg.position = WorldWrap.wrap_position(seg.position + delta)

		var prev_back: int = maxi(back - SEGMENT_SPACING, 0)
		var prev_pos: Vector2 = _history_at(prev_back) - _history_offset
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
		seg.modulate = Color.WHITE  # reset tint before returning to pool
		_segment_pool.release(seg)
	_segments.clear()
	_history_head = 0
	_history_count = 0
	_history_offset = Vector2.ZERO

## ---------- Internal ----------
func _tail_position() -> Vector2:
	if _segments.size() > 0:
		return _segments[-1].position
	if _history_count > 0:
		return _history_at(_history_count - 1) - _history_offset
	return Vector2.ZERO
