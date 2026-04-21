## AudioManager — Plays SFX and music with theme awareness.
## Autoload or add to Game scene.
class_name AudioManager
extends Node

var _music_player: AudioStreamPlayer = null
var _sfx_player: AudioStreamPlayer = null

func _ready() -> void:
	_music_player = AudioStreamPlayer.new()
	_music_player.name = "MusicPlayer"
	_music_player.bus = "Music"
	add_child(_music_player)

	_sfx_player = AudioStreamPlayer.new()
	_sfx_player.name = "SFXPlayer"
	_sfx_player.bus = "SFX"
	add_child(_sfx_player)

	ThemeManager.theme_changed.connect(_on_theme_changed)

func play_sfx(stream: AudioStream) -> void:
	if stream and _sfx_player:
		_sfx_player.stream = stream
		_sfx_player.play()

func play_eat() -> void:
	play_sfx(ThemeManager.get_eat_sfx())

func play_death() -> void:
	play_sfx(ThemeManager.get_death_sfx())

func play_boost() -> void:
	play_sfx(ThemeManager.get_boost_sfx())

func play_music() -> void:
	var track := ThemeManager.get_music()
	if track and _music_player:
		_music_player.stream = track
		_music_player.play()

func stop_music() -> void:
	if _music_player:
		_music_player.stop()

func _on_theme_changed(_theme_name: String) -> void:
	play_music()
