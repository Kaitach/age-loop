class_name EffectProcessor
extends RefCounted

static func apply(effects: Array) -> void:
	var gs := _game_state()
	var signal_bus := _signal_bus()
	for effect in effects:
		var type := String(effect.get("type", ""))
		match type:
			"unlock_era":
				var era_id := String(effect.get("value", ""))
				if not gs.current_era == era_id:
					gs.current_era = era_id
					signal_bus.era_changed.emit(era_id)
			"unlock_item":
				gs.unlocked_items[String(effect.get("value", ""))] = true
			"unlock_building":
				gs.unlocked_buildings[String(effect.get("value", ""))] = true
			"unlock_unit":
				gs.unlocked_units[String(effect.get("value", ""))] = true
			"stat_multiplier":
				var target := String(effect.get("target", ""))
				if not target.is_empty():
					gs.effect_modifiers[target] = gs.get_effect_modifier(target) + float(effect.get("value", 0.0))
			"stat_add":
				var add_target := String(effect.get("target", ""))
				if not add_target.is_empty():
					gs.effect_additions[add_target] = gs.get_effect_addition(add_target) + float(effect.get("value", 0.0))
			"set_future_era":
				gs.future_era_preview = String(effect.get("value", "medieval"))
			_:
				push_warning("[EFFECT] Tipo desconocido: %s" % type)

static func describe_effect(effect: Dictionary) -> String:
	var type := String(effect.get("type", ""))
	var target := String(effect.get("target", ""))
	var value := float(effect.get("value", 0.0))
	match type:
		"unlock_item":
			return "Desbloquea objeto: %s" % _content_name("item", String(effect.get("value", "?")))
		"unlock_building":
			return "Desbloquea edificio: %s" % _content_name("building", String(effect.get("value", "?")))
		"unlock_unit":
			return "Desbloquea unidad: %s" % _content_name("unit", String(effect.get("value", "?")))
		"unlock_era":
			return "Desbloquea era: %s" % String(effect.get("value", "?"))
		"set_future_era":
			return "Prepara la próxima era: %s" % String(effect.get("value", "?"))
		"stat_multiplier":
			return "%s %+.0f%%" % [_target_name(target), value * 100.0]
		"stat_add":
			return "%s +%s" % [_target_name(target), _format_number(value)]
	return "Efecto especial"

static func _target_name(target: String) -> String:
	return {
		"gold_reward": "Oro de oleadas",
		"science_reward": "Ciencia de oleadas",
		"materials_reward": "Materiales de oleadas",
		"loot_bonus": "Probabilidad de loot",
		"loot_level_bonus": "Nivel del loot",
		"regen_between_waves": "Regeneración entre oleadas",
		"building_cost": "Coste de edificios",
		"gold_per_second": "Producción de oro",
		"materials_per_minute": "Producción de materiales",
		"offline_time_cap": "Límite offline",
		"damage": "Daño del jugador",
		"armor": "Armadura del jugador",
		"max_units": "Límite de unidades",
	}.get(target, target.replace("_", " ").capitalize())

static func _format_number(value: float) -> String:
	if is_equal_approx(value, round(value)):
		return str(int(round(value)))
	return "%.2f" % value

static func _content_name(kind: String, content_id: String) -> String:
	var data: Dictionary = {}
	match kind:
		"item":
			data = DataLoader.load_json("items/items.json").get("templates", {}).get(content_id, {})
		"building":
			data = DataLoader.load_json("buildings/buildings.json").get(content_id, {})
		"unit":
			data = DataLoader.load_json("units/units.json").get(content_id, {})
	var fallback := content_id.replace("_", " ").capitalize()
	return String(data.get("name", fallback))

static func _game_state() -> Node:
	return (Engine.get_main_loop() as SceneTree).root.get_node("/root/GameState")

static func _signal_bus() -> Node:
	return (Engine.get_main_loop() as SceneTree).root.get_node("/root/SignalBus")
