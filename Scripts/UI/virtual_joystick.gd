## VirtualJoystick — Touch joystick control for mobile.
## Place inside a CanvasLayer / HUD scene.
class_name VirtualJoystick
extends Control

signal direction_changed(direction: Vector2)
signal boost_pressed(active: bool)

@export var dead_zone: float = 10.0
@export var joystick_radius: float = 100.0

@onready var base: TextureRect = $Base if has_node("Base") else null
@onready var thumb: TextureRect = $Base/Thumb if has_node("Base/Thumb") else null

var _touch_index: int = -1
var _center: Vector2 = Vector2.ZERO
var _current_direction: Vector2 = Vector2.ZERO
var _is_active: bool = false

func _ready() -> void:
	if base:
		_center = base.position + base.size / 2.0

func _input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		_handle_touch(event as InputEventScreenTouch)
	elif event is InputEventScreenDrag:
		_handle_drag(event as InputEventScreenDrag)

func _handle_touch(event: InputEventScreenTouch) -> void:
	if event.pressed:
		# Only capture touches on the left half of screen (joystick zone)
		if event.position.x < get_viewport_rect().size.x * 0.5:
			_touch_index = event.index
			_is_active = true
			_center = event.position
			if base:
				base.position = _center - base.size / 2.0
	else:
		if event.index == _touch_index:
			_release()

func _handle_drag(event: InputEventScreenDrag) -> void:
	if event.index != _touch_index or not _is_active:
		return
	var diff := event.position - _center
	var dist := diff.length()

	if dist < dead_zone:
		_current_direction = Vector2.ZERO
		_update_thumb(Vector2.ZERO)
		direction_changed.emit(Vector2.ZERO)
		return

	var clamped_dist := minf(dist, joystick_radius)
	var norm := diff.normalized()
	_current_direction = norm
	_update_thumb(norm * clamped_dist)
	direction_changed.emit(norm)

func _release() -> void:
	_touch_index = -1
	_is_active = false
	_current_direction = Vector2.ZERO
	_update_thumb(Vector2.ZERO)
	direction_changed.emit(Vector2.ZERO)

func _update_thumb(offset: Vector2) -> void:
	if thumb and base:
		thumb.position = base.size / 2.0 + offset - thumb.size / 2.0

## Get current direction (for polling instead of signals).
func get_direction() -> Vector2:
	return _current_direction
