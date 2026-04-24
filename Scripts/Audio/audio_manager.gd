## AudioManager — Plays SFX and music with theme awareness.
## Generates procedural sounds when no audio files are provided.
extends Node

var _music_player: AudioStreamPlayer = null
var _sfx_players: Array[AudioStreamPlayer] = []
var _next_sfx: int = 0
const SFX_POOL_SIZE := 4

## Cached procedural sounds
var _eat_sound: AudioStreamWAV = null
var _death_sound: AudioStreamWAV = null
var _boost_sound: AudioStreamWAV = null

func _ready() -> void:
	_music_player = AudioStreamPlayer.new()
	_music_player.name = "MusicPlayer"
	add_child(_music_player)

	# Pool of SFX players so sounds can overlap
	for i in SFX_POOL_SIZE:
		var p := AudioStreamPlayer.new()
		p.name = "SFX_%d" % i
		add_child(p)
		_sfx_players.append(p)

	_generate_sounds()
	_start_threaded_music_load()

func play_sfx(stream: AudioStream) -> void:
	if not stream:
		return
	var player := _sfx_players[_next_sfx]
	_next_sfx = (_next_sfx + 1) % SFX_POOL_SIZE
	player.stream = stream
	player.volume_db = -6.0
	player.play()

func play_eat() -> void:
	var sfx := ThemeManager.get_eat_sfx()
	play_sfx(sfx if sfx else _eat_sound)

func play_death() -> void:
	var sfx := ThemeManager.get_death_sfx()
	play_sfx(sfx if sfx else _death_sound)

func play_boost() -> void:
	var sfx := ThemeManager.get_boost_sfx()
	play_sfx(sfx if sfx else _boost_sound)

## Optional override — drop a music file here and it will be used in-game.
const MUSIC_PATHS := [
	"res://Audio/Music/starostin-comedy-cartoon-funny-background-music-492540.mp3",
]

var _cached_music_track: AudioStream = null
var _music_threaded_path: String = ""

func _start_threaded_music_load() -> void:
	for path in MUSIC_PATHS:
		if ResourceLoader.exists(path):
			_music_threaded_path = path
			ResourceLoader.load_threaded_request(path)
			return

func _process(_delta: float) -> void:
	if _music_threaded_path == "" or _cached_music_track != null:
		return
	var status := ResourceLoader.load_threaded_get_status(_music_threaded_path)
	if status == ResourceLoader.THREAD_LOAD_LOADED:
		var res = ResourceLoader.load_threaded_get(_music_threaded_path)
		_music_threaded_path = ""
		_cached_music_track = res as AudioStream
		if _cached_music_track:
			if _cached_music_track is AudioStreamMP3:
				(_cached_music_track as AudioStreamMP3).loop = true
			elif _cached_music_track is AudioStreamOggVorbis:
				(_cached_music_track as AudioStreamOggVorbis).loop = true
			# If a play_music() call was waiting for the track, start it now.
			if _music_player and _music_player.stream == null and _music_wanted:
				_music_player.stream = _cached_music_track
				_music_player.volume_db = -18.0
				_music_player.play()
	elif status == ResourceLoader.THREAD_LOAD_FAILED:
		_music_threaded_path = ""

var _music_wanted: bool = false

func play_music() -> void:
	_music_wanted = true
	if not _music_player:
		return
	# Already playing? Don't restart.
	if _music_player.playing:
		return
	# Use cached track if available, else the procedural pad as placeholder
	# until the threaded load finishes.
	var track := _cached_music_track
	if not track:
		track = ThemeManager.get_music()
	if not track:
		track = _make_ambient_loop()
	_music_player.stream = track
	_music_player.volume_db = -18.0
	_music_player.play()

func stop_music() -> void:
	if _music_player:
		_music_player.stop()

## Procedural ambient pad — 4-second seamless loop, soft sine chord.
func _make_ambient_loop() -> AudioStreamWAV:
	var sample_rate := 22050
	var duration := 4.0
	var samples := int(sample_rate * duration)
	var data := PackedByteArray()
	data.resize(samples * 2)
	# Major chord stack: A3, C#4, E4 + slow LFO swell
	var freqs := [220.0, 277.18, 329.63]
	for i in samples:
		var t := float(i) / sample_rate
		var lfo := 0.65 + 0.35 * sin(t * 0.5 * TAU / duration)
		var s := 0.0
		for f in freqs:
			s += sin(t * f * TAU) * 0.18
		var val := s * lfo * 0.5
		var sample_int := clampi(int(val * 32767.0), -32768, 32767)
		data[i * 2] = sample_int & 0xFF
		data[i * 2 + 1] = (sample_int >> 8) & 0xFF
	var wav := AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = sample_rate
	wav.stereo = false
	wav.loop_mode = AudioStreamWAV.LOOP_FORWARD
	wav.loop_begin = 0
	wav.loop_end = samples
	wav.data = data
	return wav

## ---------- Procedural Sound Generation ----------
func _generate_sounds() -> void:
	_eat_sound = _make_eat_sfx()
	_death_sound = _make_death_sfx()
	_boost_sound = _make_boost_sfx()

func _make_eat_sfx() -> AudioStreamWAV:
	# Short cheerful "pop" — rising pitch
	var sample_rate := 22050
	var duration := 0.12
	var samples := int(sample_rate * duration)
	var data := PackedByteArray()
	data.resize(samples * 2)  # 16-bit
	for i in samples:
		var t := float(i) / sample_rate
		var freq := 600.0 + t * 3000.0  # rising chirp
		var envelope := (1.0 - t / duration)
		var val := sin(t * freq * TAU) * envelope * 0.5
		var sample_int := clampi(int(val * 32767.0), -32768, 32767)
		data[i * 2] = sample_int & 0xFF
		data[i * 2 + 1] = (sample_int >> 8) & 0xFF
	var wav := AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = sample_rate
	wav.stereo = false
	wav.data = data
	return wav

func _make_death_sfx() -> AudioStreamWAV:
	# Low descending "thud" with noise
	var sample_rate := 22050
	var duration := 0.35
	var samples := int(sample_rate * duration)
	var data := PackedByteArray()
	data.resize(samples * 2)
	for i in samples:
		var t := float(i) / sample_rate
		var freq := 300.0 - t * 600.0  # falling tone
		var envelope := (1.0 - t / duration) * (1.0 - t / duration)
		var tone := sin(t * maxf(freq, 50.0) * TAU) * 0.4
		var noise := (randf() * 2.0 - 1.0) * 0.15 * envelope
		var val := (tone + noise) * envelope * 0.5
		var sample_int := clampi(int(val * 32767.0), -32768, 32767)
		data[i * 2] = sample_int & 0xFF
		data[i * 2 + 1] = (sample_int >> 8) & 0xFF
	var wav := AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = sample_rate
	wav.stereo = false
	wav.data = data
	return wav

func _make_boost_sfx() -> AudioStreamWAV:
	# Quick "whoosh" sweep
	var sample_rate := 22050
	var duration := 0.18
	var samples := int(sample_rate * duration)
	var data := PackedByteArray()
	data.resize(samples * 2)
	for i in samples:
		var t := float(i) / sample_rate
		var freq := 200.0 + t * 1500.0
		var envelope := sin(t / duration * PI)  # bell curve
		var val := sin(t * freq * TAU) * envelope * 0.3
		val += (randf() * 2.0 - 1.0) * 0.1 * envelope  # add whoosh noise
		var sample_int := clampi(int(val * 32767.0), -32768, 32767)
		data[i * 2] = sample_int & 0xFF
		data[i * 2 + 1] = (sample_int >> 8) & 0xFF
	var wav := AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = sample_rate
	wav.stereo = false
	wav.data = data
	return wav
