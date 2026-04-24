## ThemeManager — Autoload singleton. Loads ThemeData resources, swaps visuals at runtime.
extends Node

signal theme_changed(theme_name: String)

const THEME_PATHS := {
	"meadow": "res://Resources/ThemeMeadow.tres",
}

var current_theme_name: String = "meadow"
var current_theme: ThemeData = null

## Cached themes to avoid reload.
var _themes: Dictionary = {}

func _ready() -> void:
	# Pre-load themes (silently skip if assets are missing)
	for key in THEME_PATHS:
		var path: String = THEME_PATHS[key]
		if ResourceLoader.exists(path):
			var res = load(path)
			if res is ThemeData:
				_themes[key] = res
			else:
				push_warning("ThemeManager: '%s' failed to load (missing assets?)" % path)

func set_theme(theme_name: String) -> void:
	if theme_name not in THEME_PATHS:
		push_warning("Unknown theme: %s" % theme_name)
		return

	current_theme_name = theme_name

	if theme_name in _themes:
		current_theme = _themes[theme_name]
	else:
		# Fallback: create empty ThemeData
		current_theme = ThemeData.new()
		current_theme.theme_name = theme_name

	theme_changed.emit(current_theme_name)

## ---------- Asset accessors ----------
func get_head_sprite(skin_index: int = 0) -> Texture2D:
	if current_theme and skin_index < current_theme.head_sprites.size():
		return current_theme.head_sprites[skin_index]
	return null

func get_segment_sprite() -> Texture2D:
	return current_theme.segment_sprite if current_theme else null

func get_segment_modulate() -> Color:
	return current_theme.segment_modulate if current_theme else Color.WHITE

func get_food_sprite(index: int = 0) -> Texture2D:
	if current_theme and index < current_theme.food_sprites.size():
		return current_theme.food_sprites[index]
	return null

func get_death_particle_scene() -> PackedScene:
	return current_theme.death_particle_scene if current_theme else null

func get_ambient_particle_scene() -> PackedScene:
	return current_theme.ambient_particle_scene if current_theme else null

func get_background_shader() -> Shader:
	return current_theme.background_shader if current_theme else null

func get_background_color() -> Color:
	return current_theme.background_color if current_theme else Color(0.2, 0.6, 0.1)

## ---------- Audio ----------
func get_eat_sfx() -> AudioStream:
	return current_theme.eat_sfx if current_theme else null

func get_death_sfx() -> AudioStream:
	return current_theme.death_sfx if current_theme else null

func get_boost_sfx() -> AudioStream:
	return current_theme.boost_sfx if current_theme else null

func get_music() -> AudioStream:
	return current_theme.music_track if current_theme else null
