class_name StatsCalculator
extends RefCounted

static func player_final_stats(player: Player) -> Dictionary:
	var balance := DataLoader.get_balance()
	var gs := (Engine.get_main_loop() as SceneTree).root.get_node("/root/GameState")
	var out := {
		"damage": float(player.base_damage) + float(Upgrades.bonus_value("player_damage")),
		"max_health": float(player.base_max_health) + float(Upgrades.bonus_value("player_health")),
		"attack_speed": player.attack_speed,
		"critical_chance": float(balance.get("critical_chance_base", 0.05)),
		"critical_damage": float(balance.get("critical_damage_base", 1.5)),
	}
	for slot in gs.equipped_items.keys():
		var instance = gs.equipped_items[slot]
		if instance == null or not (instance is Dictionary):
			continue
		_apply_item(out, instance)
	out["damage"] = maxf(1.0, out["damage"])
	out["max_health"] = maxf(1.0, out["max_health"])
	return out

static func item_total_stats(instance: Dictionary) -> Dictionary:
	var totals := {}
	_apply_item(totals, instance)
	return totals

static func _apply_item(target: Dictionary, instance: Dictionary) -> void:
	for stat_key in instance.get("stats", {}).keys():
		target[stat_key] = float(target.get(stat_key, 0.0)) + float(instance["stats"][stat_key])
	for modifier in instance.get("modifiers", []):
		var stat_key := String(modifier.get("stat", ""))
		target[stat_key] = float(target.get(stat_key, 0.0)) + float(modifier.get("value", 0.0))

static func format_stat_line(stat_key: String, value: float) -> String:
	match stat_key:
		"damage":
			return "Daño +%d" % int(round(value))
		"max_health":
			return "Vida +%d" % int(round(value))
		"attack_speed":
			return "Velocidad %+.0f%%" % (value * 100.0)
		"critical_chance":
			return "Critico %+.1f%%" % (value * 100.0)
		"critical_damage":
			return "Daño critico %+.0f%%" % (value * 100.0)
	return "%s %.2f" % [stat_key, value]
