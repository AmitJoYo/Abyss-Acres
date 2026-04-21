## MainMenu — Entry point. Start game button.
extends Node

@onready var play_button: Button = $MainMenu/PlayButton if has_node("MainMenu/PlayButton") else null

func _ready() -> void:
	if play_button:
		play_button.pressed.connect(_on_play_pressed)

func _on_play_pressed() -> void:
	get_tree().change_scene_to_file("res://Scenes/Game.tscn")
