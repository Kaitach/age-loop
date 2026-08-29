class_name StatsCalculator
extends RefCounted

static func player_final_stats(player: Player) -> Dictionary:
	var balance := DataLoader.get_balance()
	var gs := _game_state()
	var attack_range := 0.0
	var attack_type := "melee"
	var out := {
		"damage": float(player.base_damage) + float(Upgrades.bonus_value("player_damage")),
		"max_health": float(player.base_max_health) + float(Upgrades.bonus_value("player_health")),
		"attack_speed": player.base_attack_speed,
		"attack_range": attack_range,
		"attack_type": attack_type,
		"critical_chance": float(balance.get("critical_chance_base", 0.05)),
		"critical_damage": float(balance.get("critical_damage_base", 1.5)),
		"armor": 0.0,
	}
	var weapon = gs.equipped_items.get("weapon", null)
	if weapon != null and weapon is Dictionary:
		var weapon_stats: Dictionary = item_total_stats(weapon)
		attack_range = float(weapon_stats.get("attack_range", 0.0))
		attack_type = _weapon_attack_type(weapon, attack_range)
		out["attack_range"] = attack_range
		out["attack_type"] = attack_type
	for slot in gs.equipped_items.keys():
		var instance = gs.equipped_items[slot]
		if instance == null or not (instance is Dictionary):
			continue
		# The weapon determines the combat reach. Its other stats still stack with
		# the rest of the equipment, but attack_range must not be counted twice.
		_apply_item(out, instance, String(slot) == "weapon")
	for stat_key in ["damage", "max_health", "attack_speed", "critical_chance", "critical_damage", "armor", "attack_range"]:
		var effect: float = gs.get_effect_modifier(stat_key)
		if absf(effect) > 0.000001:
			out[stat_key] = float(out.get(stat_key, 0.0)) * (1.0 + effect)
		var addition: float = gs.get_effect_addition(stat_key)
		if absf(addition) > 0.000001:
			out[stat_key] = float(out.get(stat_key, 0.0)) + addition
	out["damage"] = maxf(1.0, out["damage"])
	out["max_health"] = maxf(1.0, out["max_health"])
	out["attack_speed"] = maxf(0.1, out["attack_speed"])
	return out

static func _game_state() -> Node:
	return (Engine.get_main_loop() as SceneTree).root.get_node("/root/GameState")

static func item_total_stats(instance: Dictionary) -> Dictionary:
	var totals := {}
	_apply_item(totals, instance)
	return totals

static func combat_power(stats: Dictionary) -> int:
	var damage := float(stats.get("damage", 0.0))
	var health := float(stats.get("max_health", 0.0))
	var armor := float(stats.get("armor", 0.0))
	var crit := float(stats.get("critical_chance", 0.0))
	var attack_speed := float(stats.get("attack_speed", 0.0))
	return maxi(0, int(round(damage * 4.0 + health * 0.55 + armor * 3.0 + crit * 100.0 * 2.0 + attack_speed * 18.0)))

static func _apply_item(target: Dictionary, instance: Dictionary, skip_attack_range: bool = false) -> void:
	for stat_key in instance.get("stats", {}).keys():
		if skip_attack_range and String(stat_key) == "attack_range":
			continue
		target[stat_key] = float(target.get(stat_key, 0.0)) + float(instance["stats"][stat_key])
	for modifier in instance.get("modifiers", []):
		var stat_key := String(modifier.get("stat", ""))
		if skip_attack_range and stat_key == "attack_range":
			continue
		target[stat_key] = float(target.get(stat_key, 0.0)) + float(modifier.get("value", 0.0))

static func _weapon_attack_type(instance: Dictionary, attack_range: float) -> String:
	var explicit_type := String(instance.get("attack_type", ""))
	if explicit_type == "melee" or explicit_type == "ranged":
		return explicit_type
	return "ranged" if attack_range >= 160.0 else "melee"

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
		"attack_range":
			return "Alcance %d" % int(round(value))
	return "%s %.2f" % [stat_key, value]
