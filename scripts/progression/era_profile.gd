class_name EraProfile
extends RefCounted

const DEFAULT_ERA := "prehistoric"
static var _profiles: Dictionary = {}
static var _ordered_eras: Array[String] = []

static func get_profile(era_id: String) -> Dictionary:
	_ensure_loaded()
	var profile: Dictionary = _profiles.get(era_id, {})
	if profile.is_empty():
		profile = _profiles.get(DEFAULT_ERA, {})
	return profile

static func get_mechanic_id(era_id: String) -> String:
	return String(get_profile(era_id).get("mechanic_id", "pack_hunt"))

static func era_for_level(level: int) -> String:
	_ensure_ordered_eras()
	if _ordered_eras.is_empty():
		return DEFAULT_ERA
	return _ordered_eras[clampi(level - 1, 0, _ordered_eras.size() - 1)]

static func era_for_wave(world: int, wave: int) -> String:
	# La era del enemigo nace del progreso de la oleada, no de la investigacion
	# del jugador. Las oleadas posteriores a la ultima era quedan en la ultima.
	return era_for_level(maxi(1, (world - 1) * 10 + wave))

static func era_name(era_id: String) -> String:
	return String(DataLoader.load_json("eras/eras.json").get(era_id, {}).get("name", era_id))

static func get_transition_color(era_id: String) -> Color:
	var arr: Array = get_profile(era_id).get("transition_color", [0.35, 0.82, 0.45, 1.0])
	return DataLoader.color_from_array(arr, Color(0.35, 0.82, 0.45))

static func get_asset(era_id: String, asset_type: String, variant: String = "") -> String:
	var safe_era := era_id if not era_id.is_empty() else DEFAULT_ERA
	var path := "res://assets/eras/%s/" % safe_era
	match asset_type:
		"background":
			path += "background.png"
		"player":
			path += "player.png"
		"base":
			path += "base.png"
		"projectile":
			path += "projectile.png"
		"enemy":
			path += "enemies/%s.png" % variant
		"unit":
			path += "units/%s.png" % variant
		"pet":
			return "res://assets/pets/%s/%s.png" % [variant if not variant.is_empty() else "wolf", safe_era]
		_:
			return ""
	# FileAccess tambien detecta assets recien generados antes de que el editor
	# haya escrito su cache de importacion; load() se encarga de resolverlos.
	if FileAccess.file_exists(path):
		return path
	return _fallback_asset(asset_type, variant)

static func has_asset(era_id: String, asset_type: String, variant: String = "") -> bool:
	var path := get_asset(era_id, asset_type, variant)
	return not path.is_empty() and FileAccess.file_exists(path)

static func _fallback_asset(asset_type: String, variant: String) -> String:
	match asset_type:
		"background":
			return "res://assets/ui/battle_background.png"
		"player":
			return "res://assets/characters/player.png"
		"base":
			return "res://assets/buildings/base.png"
		"projectile":
			return "res://assets/projectiles/projectile.png"
		"enemy":
			var enemy_path := "res://assets/enemies/%s.png" % variant
			return enemy_path if FileAccess.file_exists(enemy_path) else "res://assets/enemies/normal.png"
		"unit":
			var unit_path := "res://assets/units/%s.png" % variant
			if FileAccess.file_exists(unit_path):
				return unit_path
			return "res://assets/units/militia.png"
		"pet":
			return "res://assets/characters/player.png"
	return ""

static func _ensure_loaded() -> void:
	if not _profiles.is_empty():
		return
	_profiles = DataLoader.load_json("eras/era_profiles.json")

static func _ensure_ordered_eras() -> void:
	if not _ordered_eras.is_empty():
		return
	var eras: Dictionary = DataLoader.load_json("eras/eras.json")
	var sortable: Array = []
	for era_id in eras.keys():
		sortable.append({"id": String(era_id), "order": int(eras[era_id].get("order", 999))})
	sortable.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return int(a["order"]) < int(b["order"]))
	for row in sortable:
		_ordered_eras.append(String(row["id"]))
