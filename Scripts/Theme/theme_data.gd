## ThemeData — Resource holding all visual/audio assets for one theme.
## Create one .tres per theme (e.g. ThemeMeadow.tres).
@tool
class_name ThemeData
extends Resource

@export var theme_name: String = ""

## Background
@export var background_texture: Texture2D
@export var background_shader: Shader
@export var background_color: Color = Color(0.2, 0.6, 0.1)

## Snake visuals
@export var head_sprites: Array[Texture2D] = []   # one per skin
@export var skin_names: Array[String] = []         # matching names
@export var segment_sprite: Texture2D
@export var segment_modulate: Color = Color.WHITE
@export var segment_blend_mode: int = 0            # 0=Mix, 1=Add

## Food
@export var food_sprites: Array[Texture2D] = []    # small, medium
@export var food_names: Array[String] = []
@export var food_small_segments: int = 1
@export var food_small_score: int = 10
@export var food_medium_segments: int = 2
@export var food_medium_score: int = 25

## Particles
@export var ambient_particle_scene: PackedScene    # pollen
@export var death_particle_scene: PackedScene       # feathers

## Audio
@export var music_track: AudioStream
@export var eat_sfx: AudioStream
@export var death_sfx: AudioStream
@export var boost_sfx: AudioStream
@export var kill_sfx: AudioStream
