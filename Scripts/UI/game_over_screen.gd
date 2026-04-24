## GameOverScreen — Overlay shown when player dies.
## Shows score, high score, and retry/menu buttons.
class_name GameOverScreen
extends Control

signal retry_pressed
signal menu_pressed

var _title_label: Label
var _score_label: Label
var _high_score_label: Label
var _retry_button: Button
var _menu_button: Button

func _ready() -> void:
	_build_ui()
	visible = false
	mouse_filter = Control.MOUSE_FILTER_STOP

func show_game_over(score: int, high_score: int) -> void:
	_score_label.text = "Score: %d" % score
	_high_score_label.text = "Best: %d" % high_score
	if score >= high_score and score > 0:
		_high_score_label.text += "  NEW!"
	visible = true

func _build_ui() -> void:
	# Full-screen dimming overlay
	anchors_preset = Control.PRESET_FULL_RECT
	set_anchors_preset(Control.PRESET_FULL_RECT)

	var dimmer := ColorRect.new()
	dimmer.set_anchors_preset(Control.PRESET_FULL_RECT)
	dimmer.color = Color(0, 0, 0, 0.6)
	dimmer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(dimmer)

	# Card panel
	var card := PanelContainer.new()
	card.set_anchors_preset(Control.PRESET_CENTER)
	card.custom_minimum_size = Vector2(500, 400)
	card.position = Vector2(-250, -200)
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.08, 0.08, 0.15, 0.92)
	style.corner_radius_top_left = 20
	style.corner_radius_top_right = 20
	style.corner_radius_bottom_left = 20
	style.corner_radius_bottom_right = 20
	style.border_width_top = 3
	style.border_width_bottom = 3
	style.border_width_left = 3
	style.border_width_right = 3
	style.border_color = Color(0.85, 0.65, 0.1)
	style.content_margin_left = 30
	style.content_margin_right = 30
	style.content_margin_top = 30
	style.content_margin_bottom = 30
	card.add_theme_stylebox_override("panel", style)
	add_child(card)

	var vbox := VBoxContainer.new()
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_theme_constant_override("separation", 20)
	card.add_child(vbox)

	# Title
	_title_label = Label.new()
	_title_label.text = "GAME OVER"
	_title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_title_label.add_theme_font_size_override("font_size", 52)
	_title_label.add_theme_color_override("font_color", Color(1.0, 0.3, 0.3))
	vbox.add_child(_title_label)

	# Score
	_score_label = Label.new()
	_score_label.text = "Score: 0"
	_score_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_score_label.add_theme_font_size_override("font_size", 36)
	vbox.add_child(_score_label)

	# High score
	_high_score_label = Label.new()
	_high_score_label.text = "Best: 0"
	_high_score_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_high_score_label.add_theme_font_size_override("font_size", 28)
	_high_score_label.add_theme_color_override("font_color", Color(0.85, 0.65, 0.1))
	vbox.add_child(_high_score_label)

	# Spacer
	var spacer := Control.new()
	spacer.custom_minimum_size = Vector2(0, 10)
	vbox.add_child(spacer)

	# Buttons
	var btn_box := HBoxContainer.new()
	btn_box.alignment = BoxContainer.ALIGNMENT_CENTER
	btn_box.add_theme_constant_override("separation", 40)
	vbox.add_child(btn_box)

	_retry_button = _make_button("RETRY", Color(0.2, 0.7, 0.3))
	_retry_button.pressed.connect(func(): retry_pressed.emit())
	btn_box.add_child(_retry_button)

	_menu_button = _make_button("MENU", Color(0.4, 0.4, 0.5))
	_menu_button.pressed.connect(func(): menu_pressed.emit())
	btn_box.add_child(_menu_button)

func _make_button(text: String, color: Color) -> Button:
	var btn := Button.new()
	btn.text = text
	btn.custom_minimum_size = Vector2(180, 60)
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.corner_radius_top_left = 12
	style.corner_radius_top_right = 12
	style.corner_radius_bottom_left = 12
	style.corner_radius_bottom_right = 12
	btn.add_theme_stylebox_override("normal", style)
	var hover := style.duplicate() as StyleBoxFlat
	hover.bg_color = color.lightened(0.2)
	btn.add_theme_stylebox_override("hover", hover)
	var pressed := style.duplicate() as StyleBoxFlat
	pressed.bg_color = color.darkened(0.2)
	btn.add_theme_stylebox_override("pressed", pressed)
	btn.add_theme_font_size_override("font_size", 28)
	return btn
