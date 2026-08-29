extends SceneTree

var _errors: Array[String] = []

func _initialize() -> void:
	_validate_json_files()
	_validate_references()
	_validate_era_profiles()
	_validate_scenes()
	if _errors.is_empty():
		print("[DATA] PASS: datos y escenas validos")
		quit(0)
	else:
		for error in _errors:
			printerr("[DATA] ERROR: " + error)
		quit(1)

func _load(path: String) -> Dictionary:
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		_errors.append("No se pudo abrir " + path)
		return {}
	var parsed = JSON.parse_string(file.get_as_text())
	file.close()
	if not (parsed is Dictionary):
		_errors.append("JSON invalido " + path)
		return {}
	return parsed

func _validate_json_files() -> void:
	for path in ["res://data/eras/eras.json", "res://data/technologies/technologies.json", "res://data/items/items.json", "res://data/buildings/buildings.json", "res://data/enemies/enemies.json", "res://data/units/units.json", "res://data/pets/pets.json", "res://data/rarities/rarities.json", "res://data/balance/game_balance.json"]:
		_load(path)
	for world in range(1, 4):
		_load("res://data/waves/world_%d.json" % world)

func _validate_references() -> void:
	var eras := _load("res://data/eras/eras.json")
	var techs := _load("res://data/technologies/technologies.json")
	var items_data := _load("res://data/items/items.json")
	var items: Dictionary = items_data.get("templates", {})
	var buildings := _load("res://data/buildings/buildings.json")
	var enemies := _load("res://data/enemies/enemies.json")
	var units := _load("res://data/units/units.json")
	var pets := _load("res://data/pets/pets.json")
	var rarities := _load("res://data/rarities/rarities.json")
	if eras.size() < 13:
		_errors.append("se esperan al menos 13 eras disponibles y solo hay %d" % eras.size())
	var era_orders: Array[int] = []
	for era_id in eras.keys():
		var era: Dictionary = eras[era_id]
		era_orders.append(int(era.get("order", 0)))
		var visual: Dictionary = era.get("visual", {})
		for visual_key in ["sky_dark", "sky_light", "sun", "hill", "ground", "horizon", "dirt", "accent", "motif"]:
			if not visual.has(visual_key):
				_errors.append("era %s no tiene configuración visual %s" % [era_id, visual_key])
		for req in era.get("requirements", []):
			if not techs.has(String(req)):
				_errors.append("era %s requiere tecnologia inexistente %s" % [era_id, req])
			elif int(era.get("order", 0)) > 1:
				var req_era := String(techs[String(req)].get("era", ""))
				var req_order := int(eras.get(req_era, {}).get("order", 99))
				if req_order >= int(era.get("order", 0)):
					_errors.append("era %s depende de tecnologia %s de una era posterior o igual" % [era_id, req])
	era_orders.sort()
	for i in range(era_orders.size()):
		if era_orders[i] != i + 1:
			_errors.append("el orden de eras no es continuo en la posicion %d" % i)
	for tech_id in techs.keys():
		var tech: Dictionary = techs[tech_id]
		if not eras.has(String(tech.get("era", ""))):
			_errors.append("tecnologia %s referencia era inexistente" % tech_id)
		for req in tech.get("requirements", []):
			if not techs.has(String(req)):
				_errors.append("tecnologia %s requiere tecnologia inexistente %s" % [tech_id, req])
		for effect in tech.get("effects", []):
			var effect_type := String(effect.get("type", ""))
			var effect_id := str(effect.get("value", ""))
			if effect_type == "unlock_item" and not items.has(effect_id):
				_errors.append("tecnologia %s desbloquea item inexistente %s" % [tech_id, effect_id])
			if effect_type == "unlock_building" and not buildings.has(effect_id):
				_errors.append("tecnologia %s desbloquea edificio inexistente %s" % [tech_id, effect_id])
			if effect_type == "unlock_unit" and not units.has(effect_id):
				_errors.append("tecnologia %s desbloquea unidad inexistente %s" % [tech_id, effect_id])
	for tech_id in techs.keys():
		_check_tech_cycle(String(tech_id), techs, [], {})
	for item_id in items.keys():
		var item: Dictionary = items[item_id]
		if not eras.has(String(item.get("era", ""))):
			_errors.append("item %s referencia era inexistente" % item_id)
		var required := String(item.get("required_technology", ""))
		if not required.is_empty() and not techs.has(required):
			_errors.append("item %s requiere tecnologia inexistente %s" % [item_id, required])
	for building_id in buildings.keys():
		var required_building := String(buildings[building_id].get("required_technology", ""))
		if not required_building.is_empty() and not techs.has(required_building):
			_errors.append("edificio %s requiere tecnologia inexistente %s" % [building_id, required_building])
	for unit_id in units.keys():
		var unit: Dictionary = units[unit_id]
		if not eras.has(String(unit.get("era", ""))):
			_errors.append("unidad %s referencia era inexistente" % unit_id)
		var required_unit := String(unit.get("required_technology", ""))
		if not required_unit.is_empty() and not techs.has(required_unit):
			_errors.append("unidad %s requiere tecnologia inexistente %s" % [unit_id, required_unit])
	for pet_id in pets.keys():
		var pet: Dictionary = pets[pet_id]
		if not pet.has("base_health") or not pet.has("base_damage"):
			_errors.append("mascota %s no tiene estadisticas base" % pet_id)
		for era_id in eras.keys():
			if not FileAccess.file_exists("res://assets/pets/%s/%s.png" % [pet_id, era_id]):
				_errors.append("mascota %s no tiene sprite para era %s" % [pet_id, era_id])
	var total_weight := 0.0
	for rarity_id in rarities.keys():
		total_weight += float(rarities[rarity_id].get("weight", 0.0))
	if absf(total_weight - 100.0) > 0.01:
		_errors.append("las probabilidades de rareza suman %.2f y deberían sumar 100" % total_weight)
	for world in range(1, 4):
		var wave_data := _load("res://data/waves/world_%d.json" % world)
		if wave_data.get("waves", []).size() != 10:
			_errors.append("world_%d no tiene 10 oleadas" % world)
		for wave in wave_data.get("waves", []):
			for group in wave.get("groups", []):
				if not enemies.has(String(group.get("enemy", ""))):
					_errors.append("world_%d wave %s referencia enemigo inexistente" % [world, wave.get("wave", "?")])
			var boss_id := String(wave.get("boss", ""))
			if not boss_id.is_empty() and (not enemies.has(boss_id) or not bool(enemies[boss_id].get("is_boss", false))):
				_errors.append("world_%d wave %s tiene boss invalido" % [world, wave.get("wave", "?")])

func _validate_era_profiles() -> void:
	var eras := _load("res://data/eras/eras.json")
	var profiles := _load("res://data/eras/era_profiles.json")
	var enemies := _load("res://data/enemies/enemies.json")
	var units := _load("res://data/units/units.json")
	for era_id in eras.keys():
		var profile: Dictionary = profiles.get(String(era_id), {})
		if profile.is_empty():
			_errors.append("era %s no tiene perfil de transicion/mecanica" % era_id)
			continue
		for required_key in ["mechanic_id", "mechanic_name", "mechanic_description", "mechanic_values", "transition_color", "transition_duration"]:
			if not profile.has(required_key):
				_errors.append("perfil de era %s no tiene %s" % [era_id, required_key])
		var era_root := "res://assets/eras/%s/" % era_id
		for asset_path in ["background.png", "player.png", "base.png", "projectile.png"]:
			if not FileAccess.file_exists(era_root + asset_path):
				_errors.append("era %s no tiene asset %s" % [era_id, asset_path])
		for enemy_id in enemies.keys():
			if not FileAccess.file_exists(era_root + "enemies/%s.png" % enemy_id):
				_errors.append("era %s no tiene sprite de enemigo %s" % [era_id, enemy_id])
		for unit_id in units.keys():
			if not FileAccess.file_exists(era_root + "units/%s.png" % unit_id):
				_errors.append("era %s no tiene sprite de unidad %s" % [era_id, unit_id])
	for profile_id in profiles.keys():
		if not eras.has(String(profile_id)):
			_errors.append("perfil de era %s no referencia una era existente" % profile_id)

func _validate_scenes() -> void:
	for path in ["res://scenes/bootstrap/bootstrap.tscn", "res://scenes/menu/main_menu.tscn", "res://scenes/battle/battle.tscn", "res://scenes/inventory/inventory_screen.tscn", "res://scenes/equipment/equipment_screen.tscn", "res://scenes/research/research_screen.tscn", "res://scenes/base/base_screen.tscn", "res://scenes/settings/settings_screen.tscn"]:
		if ResourceLoader.load(path) == null:
			_errors.append("escena invalida " + path)

func _check_tech_cycle(tech_id: String, techs: Dictionary, path: Array[String], visited: Dictionary) -> void:
	if tech_id in path:
		_errors.append("loop de prerequisitos de tecnologia: " + " -> ".join(path + [tech_id]))
		return
	if visited.has(tech_id):
		return
	var next_path := path.duplicate()
	next_path.append(tech_id)
	for req in techs[tech_id].get("requirements", []):
		_check_tech_cycle(String(req), techs, next_path, visited)
	visited[tech_id] = true
