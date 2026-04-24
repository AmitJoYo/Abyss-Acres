## HUD — In-game overlay: score, joystick, boost button, game over.
extends CanvasLayer

@onready var score_label: Label = $ScoreLabel if has_node("ScoreLabel") else null
@onready var length_label: Label = $LengthLabel if has_node("LengthLabel") else null

var joystick: VirtualJoystick = null
var _player_input: PlayerInput = null
var _snake: SnakeController = null
var _game_over_screen: GameOverScreen = null
var _boost_touch_active: bool = false
var _boost_touch_index: int = -1
var _boost_button: Control = null
var _minimap: Minimap = null

func setup(snake: SnakeController, player_input: PlayerInput) -> void:
	_snake = snake
	_player_input = player_input
	GameManager.score_changed.connect(_on_score_changed)
	GameManager.game_over.connect(_on_game_over)

	_build_joystick()
	_build_boost_button()
	_build_score_panel()
	_build_minimap()
	_build_powerup_panel()
	_build_mode_label()

	# Game-over overlay (hidden initially)
	_game_over_screen = GameOverScreen.new()
	_game_over_screen.name = "GameOverScreen"
	add_child(_game_over_screen)
	_game_over_screen.retry_pressed.connect(_on_retry)
	_game_over_screen.menu_pressed.connect(_on_menu)

func _build_joystick() -> void:
	joystick = VirtualJoystick.new()
	joystick.name = "VirtualJoystick"
	add_child(joystick)
	joystick.direction_changed.connect(_on_joystick_direction)

var _boost_center: Vector2 = Vector2.ZERO
var _boost_radius: float = 80.0  # touch area slightly larger than visual

func _build_boost_button() -> void:
	var vp := get_viewport().get_visible_rect().size
	_boost_button = Control.new()
	_boost_button.name = "BoostArea"
	_boost_button.set_anchors_preset(Control.PRESET_FULL_RECT)
	_boost_button.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_boost_button)

	# Visual boost circle (bottom-right)
	var boost_visual := _BoostCircle.new()
	boost_visual.name = "BoostCircle"
	var btn_size := 120.0
	boost_visual.position = Vector2(vp.x - btn_size - 60, vp.y - btn_size - 200)
	boost_visual.size = Vector2(btn_size, btn_size)
	boost_visual.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_boost_button.add_child(boost_visual)

	# Store boost button center for touch detection
	_boost_center = boost_visual.position + Vector2(btn_size / 2.0, btn_size / 2.0)
	_boost_radius = btn_size / 2.0 + 20.0  # generous touch area

	# Tell joystick to exclude the boost area
	if joystick:
		var pad := 20.0
		joystick.exclude_rect = Rect2(boost_visual.position - Vector2(pad, pad), Vector2(btn_size + pad * 2, btn_size + pad * 2))

func _build_score_panel() -> void:
	var vp := get_viewport().get_visible_rect().size
	# Reposition existing labels for portrait mode
	if score_label:
		score_label.position = Vector2(vp.x - 200, 40)
		score_label.size = Vector2(180, 50)
		score_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		score_label.add_theme_font_size_override("font_size", 36)
		score_label.add_theme_color_override("font_color", Color(1.0, 0.9, 0.3))
	if length_label:
		length_label.position = Vector2(20, 40)
		length_label.size = Vector2(200, 50)
		length_label.add_theme_font_size_override("font_size", 28)
		length_label.add_theme_color_override("font_color", Color.WHITE)

func _build_minimap() -> void:
	_minimap = Minimap.new()
	_minimap.name = "Minimap"
	var vp := get_viewport().get_visible_rect().size
	_minimap.position = Vector2(vp.x - 170, 100)
	add_child(_minimap)

var _powerup_panel: HBoxContainer = null
var _mode_label: Label = null

func _build_mode_label() -> void:
	# Skip in classic mode — nothing extra to display
	if GameManager.selected_mode == GameManager.Mode.CLASSIC:
		return
	_mode_label = Label.new()
	_mode_label.position = Vector2(20, 150)
	_mode_label.add_theme_font_size_override("font_size", 28)
	_mode_label.add_theme_color_override("font_color", Color(1.0, 0.9, 0.4))
	add_child(_mode_label)

func _build_powerup_panel() -> void:
	_powerup_panel = HBoxContainer.new()
	_powerup_panel.name = "PowerupPanel"
	_powerup_panel.position = Vector2(20, 100)
	_powerup_panel.add_theme_constant_override("separation", 12)
	add_child(_powerup_panel)

func _on_score_changed(new_score: int) -> void:
	if score_label:
		score_label.text = str(new_score)

func _on_joystick_direction(dir: Vector2) -> void:
	if _player_input:
		_player_input.set_joystick_direction(dir)

func _process(_delta: float) -> void:
	if _snake and length_label:
		length_label.text = "🐍 %d" % (_snake.body_manager.segment_count() + 1)

	# Update boost visual
	var boost_circle := _boost_button.get_node("BoostCircle") as _BoostCircle if _boost_button else null
	if boost_circle and _snake:
		boost_circle.is_boosting = _snake.is_boosting
		boost_circle.can_boost = _snake.body_manager.segment_count() > _snake.min_boost_segments
		boost_circle.queue_redraw()

	_update_powerup_panel()
	_update_mode_label()

func _update_mode_label() -> void:
	if not _mode_label:
		return
	if GameManager.is_timed():
		var t := GameManager.time_remaining()
		_mode_label.text = "⏱ %d:%02d" % [int(t) / 60, int(t) % 60]
	elif GameManager.is_shrinking():
		_mode_label.text = "🌀 Arena: %d" % int(GameManager.current_arena_radius())
	elif GameManager.is_last_standing():
		var alive := 0
		for s in get_tree().get_nodes_in_group("snakes"):
			if s.has_method("get") and s.get("is_alive"):
				alive += 1
		_mode_label.text = "👑 Bots left"

func _update_powerup_panel() -> void:
	if not _powerup_panel or not _snake:
		return
	# Build a list of (icon, color, timer_or_-1) tuples for active effects
	var active: Array = []
	if _snake.speed_powerup_timer > 0.0:
		active.append(["⚡", Color(1.0, 0.9, 0.2), _snake.speed_powerup_timer])
	if _snake.shield_active:
		active.append(["🛡", Color(0.4, 0.85, 1.0), -1.0])
	if _snake.magnet_timer > 0.0:
		active.append(["🧲", Color(0.8, 0.4, 1.0), _snake.magnet_timer])
	if _snake.score_x2_timer > 0.0:
		active.append(["★", Color(1.0, 0.65, 0.0), _snake.score_x2_timer])

	# Reuse / grow children
	while _powerup_panel.get_child_count() < active.size():
		var lbl := Label.new()
		lbl.add_theme_font_size_override("font_size", 22)
		_powerup_panel.add_child(lbl)
	for i in _powerup_panel.get_child_count():
		var l := _powerup_panel.get_child(i) as Label
		if i < active.size():
			var entry: Array = active[i]
			l.visible = true
			l.add_theme_color_override("font_color", entry[1])
			if entry[2] >= 0.0:
				l.text = "%s %.0f" % [entry[0], ceilf(entry[2])]
			else:
				l.text = "%s" % entry[0]
		else:
			l.visible = false

func _input(event: InputEvent) -> void:
	# Boost only when touching the boost circle button
	if event is InputEventScreenTouch:
		var touch := event as InputEventScreenTouch
		if touch.pressed and _boost_touch_index == -1:
			if touch.position.distance_to(_boost_center) <= _boost_radius:
				_boost_touch_index = touch.index
				_boost_touch_active = true
				if _player_input:
					_player_input.set_boost(true)
		elif not touch.pressed and touch.index == _boost_touch_index:
			_boost_touch_index = -1
			_boost_touch_active = false
			if _player_input:
				_player_input.set_boost(false)

func _on_game_over(final_score: int) -> void:
	SaveManager.update_high_score(final_score)
	var best: int = SaveManager.data.get("high_score", 0)
	_game_over_screen.show_game_over(final_score, best)

func _on_retry() -> void:
	get_tree().reload_current_scene()

func _on_menu() -> void:
	get_tree().change_scene_to_file("res://Scenes/Main.tscn")

## Visual boost button drawn in code.
class _BoostCircle extends Control:
	var is_boosting: bool = false
	var can_boost: bool = true

	func _draw() -> void:
		var center := size / 2.0
		var radius := size.x / 2.0

		# Outer ring
		var ring_color := Color(1.0, 0.5, 0.1, 0.15) if not can_boost else Color(1.0, 0.6, 0.1, 0.3)
		if is_boosting:
			ring_color = Color(1.0, 0.85, 0.2, 0.6)
		draw_circle(center, radius, ring_color)
		draw_arc(center, radius, 0, TAU, 48, Color(1.0, 0.7, 0.2, 0.5), 3.0)

		# Lightning bolt emoji
		var font := ThemeDB.fallback_font
		if font:
			var fs := 40
			var text_size := font.get_string_size("⚡", HORIZONTAL_ALIGNMENT_CENTER, -1, fs)
			var text_pos := center - text_size / 2.0 + Vector2(0, text_size.y * 0.75)
			draw_string(font, text_pos, "⚡", HORIZONTAL_ALIGNMENT_CENTER, -1, fs)
