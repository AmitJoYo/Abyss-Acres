## SnakeLighting — Manages PointLight2D on head and additive glow on segments.
## Attach as child of SnakeController. Only active during Abyss theme.
class_name SnakeLighting
extends Node

var _head_light: PointLight2D = null
var _controller: SnakeController = null
var _enabled: bool = false

func setup(controller: SnakeController) -> void:
	_controller = controller
	ThemeManager.theme_changed.connect(_on_theme_changed)
	_on_theme_changed(ThemeManager.current_theme_name)

func _on_theme_changed(theme_name: String) -> void:
	_enabled = theme_name == "abyss"
	if _enabled:
		_ensure_head_light()
	_update_visibility()

func _ensure_head_light() -> void:
	if _head_light:
		return
	_head_light = PointLight2D.new()
	_head_light.name = "HeadLight"
	_head_light.energy = 1.5
	_head_light.texture_scale = 4.0
	_head_light.color = Color(0.2, 0.8, 1.0)
	# Create a simple radial gradient texture
	var gradient := GradientTexture2D.new()
	var grad := Gradient.new()
	grad.set_offset(0, 0.0)
	grad.set_color(0, Color(1, 1, 1, 1))
	grad.add_point(1.0, Color(1, 1, 1, 0))
	gradient.gradient = grad
	gradient.width = 64
	gradient.height = 64
	gradient.fill = GradientTexture2D.FILL_RADIAL
	gradient.fill_from = Vector2(0.5, 0.5)
	gradient.fill_to = Vector2(0.5, 0.0)
	_head_light.texture = gradient

	if _controller:
		_controller.add_child(_head_light)

func _update_visibility() -> void:
	if _head_light:
		_head_light.visible = _enabled

	# Update segment blend modes
	if _controller and _controller.body_manager:
		var segments := _controller.body_manager.get_segment_positions()
		# Actual blend mode changes happen via the ThemeManager applying modulate.
		# Here we just toggle the light.

func _process(_delta: float) -> void:
	# Pulse the light slightly for organic feel
	if _enabled and _head_light and _controller and _controller.is_alive:
		_head_light.energy = 1.5 + sin(Time.get_ticks_msec() * 0.003) * 0.3
