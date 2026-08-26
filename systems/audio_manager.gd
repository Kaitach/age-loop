extends Node

var music_volume: float = 1.0
var sfx_volume: float = 1.0
var sfx_enabled: bool = true

func play_sfx(id: String) -> void:
	if not sfx_enabled:
		return

func play_music(id: String) -> void:
	pass

func set_music_volume(v: float) -> void:
	music_volume = clampf(v, 0.0, 1.0)

func set_sfx_volume(v: float) -> void:
	sfx_volume = clampf(v, 0.0, 1.0)
