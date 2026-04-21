## HUD — In-game overlay: score, joystick, boost button.
extends CanvasLayer

@onready var score_label: Label = $ScoreLabel if has_node("ScoreLabel") else null
@onready var length_label: Label = $LengthLabel if has_node("LengthLabel") else null
@onready var joystick: VirtualJoystick = $VirtualJoystick if has_node("VirtualJoystick") else null
@onready var boost_button: TouchScreenButton = $BoostButton if has_node("BoostButton") else null

var _player_input: PlayerInput = null
var _snake: SnakeController = null

func setup(snake: SnakeController, player_input: PlayerInput) -> void:
	_snake = snake
	_player_input = player_input
	GameManager.score_changed.connect(_on_score_changed)
	if joystick:
		joystick.direction_changed.connect(_on_joystick_direction)

func _on_score_changed(new_score: int) -> void:
	if score_label:
		score_label.text = str(new_score)

func _on_joystick_direction(dir: Vector2) -> void:
	if _player_input:
		_player_input.set_joystick_direction(dir)

func _process(_delta: float) -> void:
	if _snake and length_label:
		length_label.text = "Length: %d" % (_snake.body_manager.segment_count() + 1)

	# Boost button handling via touch
	if _player_input and boost_button:
		_player_input.set_boost(boost_button.is_pressed())

func _input(event: InputEvent) -> void:
	# Boost via right-side screen tap (fallback if no TouchScreenButton)
	if boost_button:
		return
	if event is InputEventScreenTouch:
		var touch := event as InputEventScreenTouch
		if touch.position.x > get_viewport_rect().size.x * 0.5:
			if _player_input:
				_player_input.set_boost(touch.pressed)
