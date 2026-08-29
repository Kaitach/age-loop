extends Node

var music_volume: float = 1.0
var sfx_volume: float = 1.0
var sfx_enabled: bool = true
var _music_player: AudioStreamPlayer
var _music_stream: AudioStreamGenerator
var _music_phase: float = 0.0

func _ready() -> void:
	refresh_from_state()

func refresh_from_state() -> void:
	sfx_enabled = bool(GameState.settings.get("sfx_enabled", true))
	sfx_volume = float(GameState.settings.get("sfx_volume", 1.0))
	music_volume = float(GameState.settings.get("music_volume", 1.0))
	if bool(GameState.settings.get("music_enabled", true)):
		play_music("main")
	else:
		_stop_music()

func _process(_delta: float) -> void:
	if _music_player == null or not _music_player.playing:
		return
	var playback := _music_player.get_stream_playback() as AudioStreamGeneratorPlayback
	if playback == null or playback.get_frames_available() < 1024:
		return
	var samples := PackedVector2Array()
	samples.resize(1024)
	for i in range(1024):
		var sample := sin(_music_phase) * 0.025
		_music_phase += TAU * 110.0 / _music_stream.mix_rate
		samples[i] = Vector2(sample, sample)
	playback.push_buffer(samples)

func play_sfx(id: String) -> void:
	if not sfx_enabled:
		return
	var stream := AudioStreamGenerator.new()
	stream.mix_rate = 22050.0
	var duration := _duration_for(id)
	stream.buffer_length = duration + 0.06
	var player := AudioStreamPlayer.new()
	player.stream = stream
	player.volume_db = linear_to_db(maxf(sfx_volume, 0.001))
	add_child(player)
	player.play()
	var playback := player.get_stream_playback() as AudioStreamGeneratorPlayback
	if playback == null:
		return
	var frequency := _frequency_for(id)
	var sample_count := int(stream.mix_rate * duration)
	var samples := PackedVector2Array()
	samples.resize(sample_count)
	for i in range(sample_count):
		var envelope := 1.0 - float(i) / float(sample_count)
		var pitch := frequency * (1.0 + 0.08 * float(i) / float(sample_count))
		var sample := (sin(TAU * pitch * float(i) / stream.mix_rate) + sin(TAU * pitch * 2.0 * float(i) / stream.mix_rate) * 0.18) * 0.12 * envelope
		samples[i] = Vector2(sample, sample)
	playback.push_buffer(samples)
	get_tree().create_timer(0.25).timeout.connect(player.queue_free, CONNECT_ONE_SHOT)

func _frequency_for(id: String) -> float:
	match id:
		"critical": return 880.0
		"victory": return 660.0
		"drop": return 990.0
		"coin": return 1040.0
		"combo": return 740.0
		"era": return 440.0
		"boss": return 180.0
		"hit": return 290.0
		"ability": return 520.0
		_: return 330.0

func _duration_for(id: String) -> float:
	match id:
		"boss": return 0.24
		"victory", "era": return 0.28
		"coin", "drop", "combo", "critical": return 0.16
		_: return 0.12

func play_music(id: String) -> void:
	if not bool(GameState.settings.get("music_enabled", true)):
		return
	_stop_music()
	_music_stream = AudioStreamGenerator.new()
	_music_stream.mix_rate = 22050.0
	_music_stream.buffer_length = 2.0
	_music_player = AudioStreamPlayer.new()
	_music_player.stream = _music_stream
	_music_player.volume_db = linear_to_db(maxf(music_volume, 0.001))
	add_child(_music_player)
	_music_player.play()

func _stop_music() -> void:
	if _music_player != null:
		_music_player.stop()
		_music_player.queue_free()
		_music_player = null

func set_music_volume(v: float) -> void:
	music_volume = clampf(v, 0.0, 1.0)
	GameState.settings["music_volume"] = music_volume
	if _music_player != null:
		_music_player.volume_db = linear_to_db(maxf(music_volume, 0.001))

func set_sfx_volume(v: float) -> void:
	sfx_volume = clampf(v, 0.0, 1.0)
	GameState.settings["sfx_volume"] = sfx_volume

func set_sfx_enabled(enabled: bool) -> void:
	sfx_enabled = enabled
	GameState.settings["sfx_enabled"] = enabled

func set_music_enabled(enabled: bool) -> void:
	GameState.settings["music_enabled"] = enabled
	if enabled:
		play_music("main")
	else:
		_stop_music()

func vibrate(duration_ms: int = 40) -> void:
	if not bool(GameState.settings.get("vibration_enabled", true)):
		return
	if OS.has_feature("mobile"):
		Input.vibrate_handheld(duration_ms)
