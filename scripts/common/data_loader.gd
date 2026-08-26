class_name DataLoader
extends RefCounted

static var _cache: Dictionary = {}

static func load_json(rel_path: String) -> Dictionary:
	if _cache.has(rel_path):
		return _cache[rel_path]
	var path := "res://data/" + rel_path
	if not FileAccess.file_exists(path):
		push_error("[DATA] Archivo inexistente: " + path)
		return {}
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		push_error("[DATA] No se pudo abrir: " + path)
		return {}
	var parsed = JSON.parse_string(file.get_as_text())
	if parsed == null or not (parsed is Dictionary):
		push_error("[DATA] JSON invalido: " + path)
		return {}
	_cache[rel_path] = parsed
	return parsed

static func get_enemies_data() -> Dictionary:
	return load_json("enemies/enemies.json")

static func get_wave_def(world: int, wave: int) -> Dictionary:
	var world_data := load_json("waves/world_%d.json" % world)
	for wave_def in world_data.get("waves", []):
		if int(wave_def.get("wave", -1)) == wave:
			return wave_def
	push_error("[DATA] Oleada inexistente: %d-%d" % [world, wave])
	return {}

static func get_balance() -> Dictionary:
	return load_json("balance/game_balance.json")

static func color_from_array(arr: Array, fallback: Color) -> Color:
	if arr.size() >= 3:
		return Color(float(arr[0]), float(arr[1]), float(arr[2]))
	return fallback
