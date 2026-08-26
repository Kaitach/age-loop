extends Node

const SAVE_PATH := "user://savegame.json"
const BACKUP_PATH := "user://savegame.backup.json"
const SAVE_VERSION := 1
const AUTOSAVE_INTERVAL := 60.0

func _ready() -> void:
	SignalBus.save_requested.connect(save_game)
	var timer := Timer.new()
	timer.wait_time = AUTOSAVE_INTERVAL
	timer.autostart = true
	timer.timeout.connect(save_game)
	add_child(timer)

func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_PAUSED or what == NOTIFICATION_WM_CLOSE_REQUEST:
		save_game()

func has_save() -> bool:
	return FileAccess.file_exists(SAVE_PATH)

func save_game() -> void:
	GameState.last_played_at = int(Time.get_unix_time_from_system())
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file == null:
		push_error("[SAVE] No se pudo escribir el save")
		return
	file.store_string(JSON.stringify(build_save_data(), "\t"))
	file.close()

func build_save_data() -> Dictionary:
	return {
		"version": SAVE_VERSION,
		"currencies": {
			"gold": GameState.gold,
			"science": GameState.science,
			"materials": GameState.materials,
			"crystals": GameState.crystals,
		},
		"progression": {
			"world": GameState.world,
			"wave": GameState.wave,
			"current_era": GameState.current_era,
		},
		"buildings": GameState.buildings,
		"technologies": GameState.technologies,
		"upgrades": GameState.upgrades,
		"inventory": GameState.inventory,
		"equipment": GameState.equipped_items,
		"research": { "current": GameState.current_research, "completed": [] },
		"stats": {
			"enemies_killed": GameState.stats.get("enemies_killed", 0),
			"bosses_killed": GameState.stats.get("bosses_killed", 0),
			"waves_completed": GameState.stats.get("waves_completed", 0),
		},
		"tutorial_flags": GameState.tutorial_flags,
		"timestamps": { "last_played_at": GameState.last_played_at },
	}

func load_game() -> bool:
	if not has_save():
		print("[SAVE] Sin save previo, usando valores por defecto")
		return false
	var parsed = _read_json(SAVE_PATH)
	if parsed == null or not (parsed is Dictionary):
		_handle_corrupted_save()
		return false
	var data := migrate_save(parsed)
	_apply_to_game_state(data)
	print("[SAVE] Partida cargada (version %d)" % int(data.get("version", 0)))
	return true

func migrate_save(data: Dictionary) -> Dictionary:
	var version := int(data.get("version", 0))
	if version > SAVE_VERSION:
		push_warning("[SAVE] Save de version futura (%d)" % version)
	return data

func delete_save() -> void:
	for path in [SAVE_PATH, BACKUP_PATH]:
		if FileAccess.file_exists(path):
			DirAccess.remove_absolute(path)

func _read_json(path: String):
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return null
	var parsed = JSON.parse_string(file.get_as_text())
	file.close()
	return parsed

func _handle_corrupted_save() -> void:
	push_warning("[SAVE] Save corrupto, generando backup y empezando de nuevo")
	if FileAccess.file_exists(SAVE_PATH):
		var backup := FileAccess.open(BACKUP_PATH, FileAccess.WRITE)
		var original := FileAccess.open(SAVE_PATH, FileAccess.READ)
		backup.store_string(original.get_as_text())
		backup.close()
		original.close()
		DirAccess.remove_absolute(SAVE_PATH)

func _apply_to_game_state(data: Dictionary) -> void:
	var currencies: Dictionary = data.get("currencies", {})
	GameState.gold = int(currencies.get("gold", 0))
	GameState.science = int(currencies.get("science", 0))
	GameState.materials = int(currencies.get("materials", 0))
	GameState.crystals = int(currencies.get("crystals", 0))

	var progression: Dictionary = data.get("progression", {})
	GameState.world = int(progression.get("world", 1))
	GameState.wave = int(progression.get("wave", 1))
	GameState.current_era = String(progression.get("current_era", "prehistoric"))

	GameState.buildings = data.get("buildings", {})
	GameState.technologies = data.get("technologies", {})
	GameState.upgrades = data.get("upgrades", {})
	GameState.inventory = data.get("inventory", [])
	GameState.equipped_items = data.get("equipment", {})

	var research: Dictionary = data.get("research", {})
	GameState.current_research = research.get("current", null)

	var stats: Dictionary = data.get("stats", {})
	GameState.stats["enemies_killed"] = int(stats.get("enemies_killed", 0))
	GameState.stats["bosses_killed"] = int(stats.get("bosses_killed", 0))
	GameState.stats["waves_completed"] = int(stats.get("waves_completed", 0))

	var timestamps: Dictionary = data.get("timestamps", {})
	GameState.last_played_at = int(timestamps.get("last_played_at", 0))
	GameState.tutorial_flags = data.get("tutorial_flags", {})
