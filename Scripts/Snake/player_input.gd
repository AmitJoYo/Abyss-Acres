## PlayerInput — Reads virtual joystick and boost button, feeds SnakeController.
## Attach as a child of the SnakeHead node alongside SnakeController.
class_name PlayerInput
extends Node

@export var controller: SnakeController = null

func _ready() -> void:
	if controller == null:
		controller = get_parent() as SnakeController

func set_joystick_direction(dir: Vector2) -> void:
	if controller:
		controller.set_target_direction(dir)

func set_boost(active: bool) -> void:
	if controller:
		controller.set_boost(active)

## Fallback: keyboard input for desktop testing.
func _process(_delta: float) -> void:
	if controller == null or not controller.is_alive:
		return

	var kb_dir := Vector2.ZERO
	if Input.is_action_pressed("ui_right"):
		kb_dir.x += 1
	if Input.is_action_pressed("ui_left"):
		kb_dir.x -= 1
	if Input.is_action_pressed("ui_down"):
		kb_dir.y += 1
	if Input.is_action_pressed("ui_up"):
		kb_dir.y -= 1

	if kb_dir.length_squared() > 0.01:
		controller.set_target_direction(kb_dir)

	controller.set_boost(Input.is_action_pressed("ui_accept"))
