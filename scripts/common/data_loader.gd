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

static func get_units_data() -> Dictionary:
	return load_json("units/units.json")

static func get_unit_data(unit_id: String) -> Dictionary:
	return get_units_data().get(unit_id, {})

static func get_pets_data() -> Dictionary:
	return load_json("pets/pets.json")

static func get_pet_data(pet_id: String) -> Dictionary:
	return get_pets_data().get(pet_id, {})

static func get_wave_def(world: int, wave: int) -> Dictionary:
	var world_data := load_json("waves/world_%d.json" % world)
	for wave_def in world_data.get("waves", []):
		if int(wave_def.get("wave", -1)) == wave:
			return wave_def
	push_error("[DATA] Oleada inexistente: %d-%d" % [world, wave])
	return {}

static func get_balance() -> Dictionary:
	return load_json("balance/game_balance.json")

static func get_era_profiles() -> Dictionary:
	return load_json("eras/era_profiles.json")

static func get_era_profile(era_id: String) -> Dictionary:
	return get_era_profiles().get(era_id, {})

static func color_from_array(arr: Array, fallback: Color) -> Color:
	if arr.size() >= 3:
		return Color(float(arr[0]), float(arr[1]), float(arr[2]))
	return fallback
