## VirtualJoystick — Touch joystick control for mobile.
## Draws its own visuals — no textures needed.
class_name VirtualJoystick
extends Control

signal direction_changed(direction: Vector2)

@export var dead_zone: float = 15.0
@export var joystick_radius: float = 80.0
@export var base_radius: float = 90.0

var _touch_index: int = -1
var _center: Vector2 = Vector2.ZERO
var _thumb_offset: Vector2 = Vector2.ZERO
var _is_active: bool = false

## Colours
var _base_color := Color(1.0, 1.0, 1.0, 0.12)
var _ring_color := Color(1.0, 1.0, 1.0, 0.25)
var _thumb_color := Color(1.0, 1.0, 1.0, 0.4)
var _thumb_active_color := Color(1.0, 0.85, 0.3, 0.6)

func _ready() -> void:
	mouse_filter = MOUSE_FILTER_IGNORE
	# Default resting position: bottom-left of viewport
	var vp := get_viewport_rect().size
	_center = Vector2(160, vp.y - 280)
	set_anchors_preset(PRESET_FULL_RECT)

func _draw() -> void:
	if not _is_active:
		# Resting state: faint circle at default position
		draw_circle(_center, base_radius, _base_color)
		draw_arc(_center, base_radius, 0, TAU, 48, _ring_color, 2.0)
		draw_circle(_center, 25.0, _thumb_color)
	else:
		# Active: show base at touch origin + thumb following finger
		draw_circle(_center, base_radius, _base_color)
		draw_arc(_center, base_radius, 0, TAU, 48, _ring_color, 2.5)
		draw_circle(_center + _thumb_offset, 30.0, _thumb_active_color)

func _input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		_handle_touch(event as InputEventScreenTouch)
	elif event is InputEventScreenDrag:
		_handle_drag(event as InputEventScreenDrag)

## Rect to exclude from joystick capture (e.g. boost button area).
var exclude_rect: Rect2 = Rect2()

func _handle_touch(event: InputEventScreenTouch) -> void:
	if event.pressed:
		# Capture any touch not inside the exclusion zone
		if _touch_index == -1 and not exclude_rect.has_point(event.position):
			_touch_index = event.index
			_is_active = true
			_center = event.position
			_thumb_offset = Vector2.ZERO
			queue_redraw()
	else:
		if event.index == _touch_index:
			_release()

func _handle_drag(event: InputEventScreenDrag) -> void:
	if event.index != _touch_index or not _is_active:
		return
	var diff := event.position - _center
	var dist := diff.length()

	if dist < dead_zone:
		_thumb_offset = Vector2.ZERO
		direction_changed.emit(Vector2.ZERO)
		queue_redraw()
		return

	var clamped_dist := minf(dist, joystick_radius)
	var norm := diff.normalized()
	_thumb_offset = norm * clamped_dist
	direction_changed.emit(norm)
	queue_redraw()

func _release() -> void:
	_touch_index = -1
	_is_active = false
	_thumb_offset = Vector2.ZERO
	direction_changed.emit(Vector2.ZERO)
	# Return to default position
	var vp := get_viewport_rect().size
	_center = Vector2(160, vp.y - 280)
	queue_redraw()

## Get current direction (for polling).
func get_direction() -> Vector2:
	if not _is_active or _thumb_offset.length() < dead_zone:
		return Vector2.ZERO
	return _thumb_offset.normalized()
