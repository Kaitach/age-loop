class_name EraCombatRules
extends RefCounted

const ERA_PROFILE = preload("res://scripts/progression/era_profile.gd")

static func new_state() -> Dictionary:
	return {"elapsed": 0.0, "event_cooldown": 0.0}

static func on_enemy_spawn(enemy: Enemy, era_id: String) -> void:
	# Al cambiar de era en mitad de una oleada, los enemigos existentes tambien
	# reciben la regla nueva y no arrastran el escudo anterior.
	enemy.clear_status("guard")
	enemy.clear_status("shield")
	var profile: Dictionary = ERA_PROFILE.get_profile(era_id)
	var values: Dictionary = profile.get("mechanic_values", {})
	match ERA_PROFILE.get_mechanic_id(era_id):
		"shield_wall":
			enemy.apply_status("guard", 999.0, float(values.get("damage_reduction", 0.5)))
		"firewall":
			enemy.apply_status("shield", float(values.get("shield_duration", 2.5)), enemy.max_health * float(values.get("shield_ratio", 0.15)))

static func tick_enemy(enemy: Enemy, era_id: String, delta: float) -> void:
	if not enemy.is_alive():
		return
	if ERA_PROFILE.get_mechanic_id(era_id) != "dash":
		return
	if enemy.enemy_id not in ["elite", "boss_chief", "boss_iron_general"]:
		return
	var profile: Dictionary = ERA_PROFILE.get_profile(era_id)
	var values: Dictionary = profile.get("mechanic_values", {})
	var cooldown := float(enemy.get_meta("era_dash_cooldown", 1.5)) - delta
	if cooldown > 0.0:
		enemy.set_meta("era_dash_cooldown", cooldown)
		return
	enemy.set_meta("era_dash_cooldown", float(values.get("interval", 6.0)))
	enemy.era_dash(float(values.get("distance", 180.0)))

static func enemy_speed_multiplier(enemy: Enemy, era_id: String) -> float:
	var mechanic: String = ERA_PROFILE.get_mechanic_id(era_id)
	var values: Dictionary = ERA_PROFILE.get_profile(era_id).get("mechanic_values", {})
	match mechanic:
		"pack_hunt":
			var group_size := int(values.get("group_size", 2))
			return 1.0 + float(values.get("speed_bonus", 0.1)) if enemy.get_tree().get_nodes_in_group("enemies").size() >= group_size else 1.0
		"iron_enrage":
			return 1.0 + float(values.get("speed_bonus", 0.7)) if enemy.health <= enemy.max_health * float(values.get("health_threshold", 0.4)) else 1.0
	return 1.0

static func enemy_attack_multiplier(enemy: Enemy, era_id: String) -> float:
	var mechanic: String = ERA_PROFILE.get_mechanic_id(era_id)
	var values: Dictionary = ERA_PROFILE.get_profile(era_id).get("mechanic_values", {})
	if mechanic == "iron_enrage" and enemy.health <= enemy.max_health * float(values.get("health_threshold", 0.4)):
		return 1.0 + float(values.get("attack_bonus", 0.3))
	if mechanic == "overheat" and enemy.has_status("haste"):
		return 1.0 + float(values.get("attack_bonus", 0.2))
	return 1.0

static func on_enemy_attack(enemy: Enemy, target: Combatant, era_id: String) -> void:
	if target == null or not target.is_alive():
		return
	var mechanic: String = ERA_PROFILE.get_mechanic_id(era_id)
	var values: Dictionary = ERA_PROFILE.get_profile(era_id).get("mechanic_values", {})
	if mechanic == "shock" and GameRng.randf() <= float(values.get("chance", 0.35)):
		target.apply_status("slow", float(values.get("duration", 0.8)), float(values.get("slow", 0.45)))

static func on_enemy_killed(battle: Node, enemy: Enemy, era_id: String, death_position: Vector2) -> void:
	if ERA_PROFILE.get_mechanic_id(era_id) != "radiation":
		return
	if enemy.enemy_id in ["ranged", "elite", "berserker"] or enemy.is_boss:
		var values: Dictionary = ERA_PROFILE.get_profile(era_id).get("mechanic_values", {})
		battle.call("_start_era_zone", death_position, float(values.get("duration", 3.0)), float(values.get("damage_per_second", 2.0)))

static func tick_battle(battle: Node, era_id: String, state: Dictionary, delta: float) -> void:
	state["elapsed"] = float(state.get("elapsed", 0.0)) + delta
	state["event_cooldown"] = float(state.get("event_cooldown", 0.0)) - delta
	var mechanic: String = ERA_PROFILE.get_mechanic_id(era_id)
	var values: Dictionary = ERA_PROFILE.get_profile(era_id).get("mechanic_values", {})
	if mechanic == "overheat":
		if state["event_cooldown"] <= 0.0:
			state["event_cooldown"] = float(values.get("interval", 12.0))
			for node in battle.get_tree().get_nodes_in_group("enemies"):
				var enemy := node as Enemy
				if enemy != null:
					enemy.apply_status("haste", float(values.get("duration", 3.0)), 1.0 + float(values.get("speed_bonus", 0.2)))
			battle.call("_show_era_event", "SOBRECALENTAMIENTO", "Las máquinas aceleran", Color(1.0, 0.43, 0.14))
		return
	if mechanic in ["siege", "volley", "orbital"]:
		if state["event_cooldown"] > 0.0:
			return
		state["event_cooldown"] = float(values.get("interval", 9.0))
		var target: Combatant = battle.get_node("World/Base") as Combatant if mechanic == "siege" else battle.get_node("World/Player") as Combatant
		var target_position: Vector2 = target.global_position
		var delay := float(values.get("telegraph_time", 2.0))
		var damage_ratio := float(values.get("base_damage_ratio", values.get("damage_ratio", 0.08)))
		var damage := maxi(1, int(round(float(target.max_health) * damage_ratio)))
		battle.call("_start_era_hazard", mechanic, target_position, delay, damage)
		return
	if mechanic == "time_fracture" and state["event_cooldown"] <= 0.0:
		state["event_cooldown"] = float(values.get("interval", 10.0))
		battle.call("_start_time_fracture", float(values.get("duration", 2.0)), float(values.get("time_scale", 0.45)))
		return
	if mechanic == "teleport" and state["event_cooldown"] <= 0.0:
		state["event_cooldown"] = float(values.get("interval", 8.0))
		for node in battle.get_tree().get_nodes_in_group("enemies"):
			var enemy := node as Enemy
			if enemy != null and (enemy.is_boss or enemy.enemy_id == "elite"):
				enemy.era_teleport(float(values.get("distance", 220.0)))
		battle.call("_show_era_event", "SALTO INTERESTELAR", "El frente cambia de lugar", Color(0.86, 0.36, 1.0))
