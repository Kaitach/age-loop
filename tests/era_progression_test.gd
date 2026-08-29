extends SceneTree

const EXPECTED_ERAS := [
	"prehistoric", "bronze", "iron", "medieval", "renaissance", "industrial",
	"electrical", "atomic", "digital", "cybernetic", "space", "interstellar", "quantum"
]

func _initialize() -> void:
	var eras: Dictionary = DataLoader.load_json("eras/eras.json")
	var techs: Dictionary = DataLoader.load_json("technologies/technologies.json")
	var profiles: Dictionary = DataLoader.get_era_profiles()
	var enemy_ids: Array = DataLoader.get_enemies_data().keys()
	var unit_ids: Array = DataLoader.get_units_data().keys()
	_check(eras.size() == EXPECTED_ERAS.size(), "hay 13 eras en total")
	for i in range(EXPECTED_ERAS.size()):
		var era_id: String = EXPECTED_ERAS[i]
		_check(eras.has(era_id), "existe la era %s" % era_id)
		if not eras.has(era_id):
			continue
		var era: Dictionary = eras[era_id]
		var profile: Dictionary = profiles.get(era_id, {})
		_check(int(era.get("order", 0)) == i + 1, "%s conserva su orden" % era_id)
		_check(not String(era.get("visual", {}).get("motif", "")).is_empty(), "%s tiene motivo visual" % era_id)
		_check(not profile.is_empty(), "%s tiene perfil de experiencia" % era_id)
		_check(not String(profile.get("mechanic_id", "")).is_empty(), "%s tiene mecanica distintiva" % era_id)
		_check(not String(profile.get("mechanic_description", "")).is_empty(), "%s explica su mecanica" % era_id)
		var asset_root := "res://assets/eras/%s/" % era_id
		for asset_name in ["background.png", "player.png", "base.png", "projectile.png"]:
			_check(FileAccess.file_exists(asset_root + asset_name), "%s tiene asset %s" % [era_id, asset_name])
		for enemy_id in enemy_ids:
			_check(FileAccess.file_exists(asset_root + "enemies/%s.png" % enemy_id), "%s tiene enemigo %s tematizado" % [era_id, enemy_id])
		for unit_id in unit_ids:
			_check(FileAccess.file_exists(asset_root + "units/%s.png" % unit_id), "%s tiene unidad %s tematizada" % [era_id, unit_id])
		if i == 0:
			continue
		var requirements: Array = era.get("requirements", [])
		_check(not requirements.is_empty(), "%s tiene tecnologia puente" % era_id)
		for req in requirements:
			_check(techs.has(String(req)), "%s referencia una tecnologia puente existente" % era_id)
			if techs.has(String(req)):
				var tech_era := String(techs[String(req)].get("era", ""))
				_check(int(eras.get(tech_era, {}).get("order", 99)) < int(era.get("order", 0)), "%s se desbloquea desde una era anterior" % era_id)
	print("[TEST] PASS: progresion de 13 eras y paletas visuales validada")
	quit(0)

func _check(condition: bool, message: String) -> void:
	if not condition:
		printerr("[TEST] FAIL: " + message)
		quit(1)
