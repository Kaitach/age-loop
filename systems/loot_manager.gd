extends Node

const LEVEL_VARIANCE := 2
const BOSS_LEVEL_BONUS := 3
const LEVEL_MULT_PER_LEVEL := 0.08
const BASE_SELL_VALUE := 8
const SELL_PER_LEVEL := 3

func roll_drop(loot_chance: float, world: int, wave: int, is_boss: bool = false) -> Dictionary:
	if randf() > loot_chance:
		return {}
	var template_id := _pick_template()
	if template_id == "":
		return {}
	var rarity_id := roll_rarity()
	var items_data := DataLoader.load_json("items/items.json")
	var template: Dictionary = items_data["templates"][template_id]
	var rarity: Dictionary = DataLoader.load_json("rarities/rarities.json")[rarity_id]
	var gw := WaveManager.global_wave_number(world, wave)
	var level := _roll_level(gw, is_boss)
	var level_mult := 1.0 + LEVEL_MULT_PER_LEVEL * (level - 1)
	return {
		"id": "%s_%d" % [template_id, randi()],
		"template_id": template_id,
		"name": String(template.get("name", template_id)),
		"slot": String(template.get("slot", "weapon")),
		"level": level,
		"rarity": rarity_id,
		"stats": _roll_base_stats(template, level_mult, float(rarity.get("mult", 1.0))),
		"modifiers": _roll_modifiers(items_data, template, rarity, level_mult),
		"sell_value": int(round((BASE_SELL_VALUE + SELL_PER_LEVEL * level) * float(rarity.get("mult", 1.0)))),
	}

func roll_rarity() -> String:
	var rarities := DataLoader.load_json("rarities/rarities.json")
	var total_weight := 0.0
	for rarity_id in rarities.keys():
		total_weight += float(rarities[rarity_id].get("weight", 0.0))
	var roll := randf() * total_weight
	for rarity_id in rarities.keys():
		roll -= float(rarities[rarity_id].get("weight", 0.0))
		if roll <= 0.0:
			return rarity_id
	return "common"

func get_rarity_color(rarity_id: String) -> Color:
	var rarity: Dictionary = DataLoader.load_json("rarities/rarities.json").get(rarity_id, {})
	return DataLoader.color_from_array(rarity.get("color", []), Color.WHITE)

func get_rarity_name(rarity_id: String) -> String:
	var rarity: Dictionary = DataLoader.load_json("rarities/rarities.json").get(rarity_id, {})
	return String(rarity.get("name", rarity_id))

func item_power(instance: Dictionary) -> float:
	var power := float(instance.get("sell_value", 0))
	for value in instance.get("stats", {}).values():
		power += absf(float(value)) * 3.0
	for modifier in instance.get("modifiers", []):
		power += absf(float(modifier.get("value", 0.0))) * 40.0
	return power

func _pick_template() -> String:
	var items_data := DataLoader.load_json("items/items.json")
	var templates: Dictionary = items_data.get("templates", {})
	var pool: Array = []
	for template_id in templates.keys():
		if String(templates[template_id].get("era", "")) == GameState.current_era:
			pool.append(template_id)
	if pool.is_empty():
		pool = templates.keys()
	if pool.is_empty():
		return ""
	return pool.pick_random()

func _roll_level(global_wave: int, is_boss: bool) -> int:
	if is_boss:
		return clampi(global_wave + randi_range(0, BOSS_LEVEL_BONUS), 1, 99)
	return clampi(global_wave + randi_range(-LEVEL_VARIANCE, LEVEL_VARIANCE), 1, 99)

func _roll_base_stats(template: Dictionary, level_mult: float, rarity_mult: float) -> Dictionary:
	var stats := {}
	for stat_key in template.get("base_stats", {}).keys():
		var raw := float(template["base_stats"][stat_key]) * level_mult * rarity_mult
		stats[stat_key] = _format_stat(stat_key, raw)
	return stats

func _roll_modifiers(items_data: Dictionary, template: Dictionary, rarity: Dictionary, level_mult: float) -> Array:
	var count := int(rarity.get("modifiers", 0))
	var allowed: Array = template.get("allowed_modifiers", [])
	var ranges: Dictionary = items_data.get("modifier_ranges", {})
	var modifiers := []
	for i in range(count):
		if allowed.is_empty():
			break
		var stat_key: String = allowed[randi() % allowed.size()]
		var value_range: Array = ranges.get(stat_key, [1, 1])
		var raw := randf_range(float(value_range[0]), float(value_range[1])) * level_mult
		modifiers.append({ "stat": stat_key, "value": _format_stat(stat_key, raw) })
	return modifiers

func _format_stat(stat_key: String, value: float) -> Variant:
	if stat_key == "damage" or stat_key == "max_health":
		return int(round(value))
	return snappedf(value, 0.001)
