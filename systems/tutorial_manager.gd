extends Node

func should_show(key: String) -> bool:
	return not GameState.tutorial_flags.has(key)

func mark_seen(key: String) -> void:
	GameState.tutorial_flags[key] = true
	SignalBus.save_requested.emit()

func show_once(key: String) -> bool:
	if should_show(key):
		mark_seen(key)
		return true
	return false
