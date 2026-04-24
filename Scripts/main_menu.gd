## MainMenu — Entry point. Play, skin select, high score.
extends Node

@onready var play_button: Button = $MainMenu/PlayButton if has_node("MainMenu/PlayButton") else null

var _skin_buttons: Array[Button] = []
var _selected_skin_index: int = 0
var _high_score_label: Label = null
var _skin_label: Label = null
var _mode_buttons: Array[Button] = []
var _selected_mode: int = 0

const SKIN_NAMES := ["Cow", "Pig", "Chicken", "Sheep"]
const SKIN_TEXTURE_PATHS := [
	"res://png/ui/cow.png",
	"res://png/ui/Pig.png",
	"res://png/ui/Chiken.png",
	"res://png/ui/Sheep.png",
]
const SKIN_COLORS := [
	Color(0.2, 0.7, 0.3),   # Cow (green placeholder)
	Color(1.0, 0.6, 0.7),   # Pig (pink)
	Color(1.0, 0.9, 0.5),   # Chicken (yellow)
	Color(0.85, 0.85, 0.9), # Sheep (light gray)
]
var _skin_textures: Array[Texture2D] = []

func _ready() -> void:
	_load_skin_textures()
	if play_button:
		play_button.pressed.connect(_on_play_pressed)
	_build_extras()

func _load_skin_textures() -> void:
	for path in SKIN_TEXTURE_PATHS:
		var tex := load(path) as Texture2D
		_skin_textures.append(tex)

func _build_extras() -> void:
	var menu_control: Control = $MainMenu if has_node("MainMenu") else null
	if not menu_control:
		return

	# Title styling
	var title: Label = $MainMenu/Title if has_node("MainMenu/Title") else null
	if title:
		title.add_theme_font_size_override("font_size", 72)
		title.add_theme_color_override("font_color", Color(0.85, 0.65, 0.1))

	# High score label
	_high_score_label = Label.new()
	_high_score_label.set_anchors_preset(Control.PRESET_CENTER_TOP)
	_high_score_label.position = Vector2(-200, 380)
	_high_score_label.size = Vector2(400, 60)
	_high_score_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_high_score_label.add_theme_font_size_override("font_size", 40)
	_high_score_label.add_theme_color_override("font_color", Color(0.85, 0.65, 0.1))
	var best: int = SaveManager.data.get("high_score", 0)
	_high_score_label.text = "Best: %d" % best if best > 0 else ""
	menu_control.add_child(_high_score_label)

	# Skin selection label
	_skin_label = Label.new()
	_skin_label.set_anchors_preset(Control.PRESET_CENTER_TOP)
	_skin_label.position = Vector2(-150, 620)
	_skin_label.size = Vector2(300, 50)
	_skin_label.text = "Choose Skin:"
	_skin_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_skin_label.add_theme_font_size_override("font_size", 36)
	menu_control.add_child(_skin_label)

	# Skin buttons in a row
	var btn_container := HBoxContainer.new()
	btn_container.set_anchors_preset(Control.PRESET_CENTER_TOP)
	btn_container.position = Vector2(-280, 690)
	btn_container.add_theme_constant_override("separation", 24)
	menu_control.add_child(btn_container)

	# Load selected skin from save
	var saved_skin: String = SaveManager.data.get("selected_skin", "cow")
	for i in SKIN_NAMES.size():
		if SKIN_NAMES[i].to_lower() == saved_skin.to_lower():
			_selected_skin_index = i

	for i in SKIN_NAMES.size():
		var btn := Button.new()
		btn.custom_minimum_size = Vector2(130, 130)
		# Build button content: texture + label in a VBox
		var vbox := VBoxContainer.new()
		vbox.alignment = BoxContainer.ALIGNMENT_CENTER
		vbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var tex_rect := TextureRect.new()
		tex_rect.custom_minimum_size = Vector2(72, 72)
		tex_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		tex_rect.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
		tex_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
		if i < _skin_textures.size() and _skin_textures[i]:
			tex_rect.texture = _skin_textures[i]
		vbox.add_child(tex_rect)
		var name_label := Label.new()
		name_label.text = SKIN_NAMES[i]
		name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		name_label.add_theme_font_size_override("font_size", 22)
		name_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		vbox.add_child(name_label)
		btn.add_child(vbox)
		var idx := i
		btn.pressed.connect(func(): _select_skin(idx))
		btn_container.add_child(btn)
		_skin_buttons.append(btn)

	_update_skin_buttons()

	# Mode selection row
	_build_mode_row(menu_control)

	# Play button styling
	if play_button:
		play_button.custom_minimum_size = Vector2(320, 100)
		play_button.add_theme_font_size_override("font_size", 44)
		var style := StyleBoxFlat.new()
		style.bg_color = Color(0.2, 0.7, 0.3)
		style.corner_radius_top_left = 16
		style.corner_radius_top_right = 16
		style.corner_radius_bottom_left = 16
		style.corner_radius_bottom_right = 16
		play_button.add_theme_stylebox_override("normal", style)
		var hover := style.duplicate() as StyleBoxFlat
		hover.bg_color = Color(0.3, 0.8, 0.4)
		play_button.add_theme_stylebox_override("hover", hover)

	# Multiplayer button — sits below Play button
	var mp_btn := Button.new()
	mp_btn.text = "MULTIPLAYER"
	mp_btn.custom_minimum_size = Vector2(320, 80)
	mp_btn.add_theme_font_size_override("font_size", 32)
	mp_btn.set_anchors_preset(Control.PRESET_CENTER_TOP)
	mp_btn.position = Vector2(-160, 1010)
	var mp_style := StyleBoxFlat.new()
	mp_style.bg_color = Color(0.25, 0.45, 0.85)
	mp_style.corner_radius_top_left = 14
	mp_style.corner_radius_top_right = 14
	mp_style.corner_radius_bottom_left = 14
	mp_style.corner_radius_bottom_right = 14
	mp_btn.add_theme_stylebox_override("normal", mp_style)
	var mp_hover := mp_style.duplicate() as StyleBoxFlat
	mp_hover.bg_color = Color(0.35, 0.55, 0.95)
	mp_btn.add_theme_stylebox_override("hover", mp_hover)
	mp_btn.pressed.connect(_on_multiplayer_pressed)
	menu_control.add_child(mp_btn)

	# Background — use main_menu_bg.png if available
	var bg: ColorRect = $MainMenu/Background if has_node("MainMenu/Background") else null
	var bg_tex := load("res://png/ui/main_menu_bg.png") as Texture2D
	if bg and bg_tex:
		# Hide the ColorRect, add a TextureRect behind everything
		bg.visible = false
		var bg_img := TextureRect.new()
		bg_img.name = "BackgroundImage"
		bg_img.texture = bg_tex
		bg_img.set_anchors_preset(Control.PRESET_FULL_RECT)
		bg_img.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
		bg_img.mouse_filter = Control.MOUSE_FILTER_IGNORE
		bg_img.modulate = Color(0.7, 0.7, 0.7, 1.0)  # slightly dimmed for readability
		var menu_ctrl: Control = $MainMenu
		menu_ctrl.add_child(bg_img)
		menu_ctrl.move_child(bg_img, 0)  # send to back
	elif bg:
		bg.color = Color(0.12, 0.18, 0.08)

func _select_skin(index: int) -> void:
	_selected_skin_index = index
	SaveManager.data["selected_skin"] = SKIN_NAMES[index].to_lower()
	SaveManager.save_data()
	_update_skin_buttons()

func _update_skin_buttons() -> void:
	for i in _skin_buttons.size():
		var btn := _skin_buttons[i]
		var style := StyleBoxFlat.new()
		style.corner_radius_top_left = 10
		style.corner_radius_top_right = 10
		style.corner_radius_bottom_left = 10
		style.corner_radius_bottom_right = 10
		if i == _selected_skin_index:
			style.bg_color = SKIN_COLORS[i]
			style.border_width_top = 3
			style.border_width_bottom = 3
			style.border_width_left = 3
			style.border_width_right = 3
			style.border_color = Color.WHITE
		else:
			style.bg_color = SKIN_COLORS[i].darkened(0.4)
		btn.add_theme_stylebox_override("normal", style)

func _on_play_pressed() -> void:
	GameManager.selected_skin_index = _selected_skin_index
	GameManager.selected_mode = _selected_mode
	get_tree().change_scene_to_file("res://Scenes/Game.tscn")

func _on_multiplayer_pressed() -> void:
	get_tree().change_scene_to_file("res://Scenes/Lobby.tscn")

## ---------- Mode Selection ----------
func _build_mode_row(menu_control: Control) -> void:
	var label := Label.new()
	label.set_anchors_preset(Control.PRESET_CENTER_TOP)
	label.position = Vector2(-150, 850)
	label.size = Vector2(300, 40)
	label.text = "Mode:"
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 32)
	menu_control.add_child(label)

	# Restore saved mode
	_selected_mode = clampi(int(SaveManager.data.get("selected_mode", 0)), 0, GameManager.MODE_NAMES.size() - 1)

	var row := HBoxContainer.new()
	row.set_anchors_preset(Control.PRESET_CENTER_TOP)
	row.position = Vector2(-340, 900)
	row.add_theme_constant_override("separation", 12)
	menu_control.add_child(row)

	for i in GameManager.MODE_NAMES.size():
		var btn := Button.new()
		btn.text = GameManager.MODE_NAMES[i]
		btn.custom_minimum_size = Vector2(160, 70)
		btn.add_theme_font_size_override("font_size", 22)
		var idx := i
		btn.pressed.connect(func(): _select_mode(idx))
		row.add_child(btn)
		_mode_buttons.append(btn)
	_update_mode_buttons()

func _select_mode(index: int) -> void:
	_selected_mode = index
	SaveManager.data["selected_mode"] = index
	SaveManager.save_data()
	_update_mode_buttons()

func _update_mode_buttons() -> void:
	for i in _mode_buttons.size():
		var btn := _mode_buttons[i]
		var style := StyleBoxFlat.new()
		style.corner_radius_top_left = 10
		style.corner_radius_top_right = 10
		style.corner_radius_bottom_left = 10
		style.corner_radius_bottom_right = 10
		if i == _selected_mode:
			style.bg_color = Color(0.85, 0.65, 0.1)
			style.border_width_top = 3
			style.border_width_bottom = 3
			style.border_width_left = 3
			style.border_width_right = 3
			style.border_color = Color.WHITE
		else:
			style.bg_color = Color(0.25, 0.25, 0.3)
		btn.add_theme_stylebox_override("normal", style)
