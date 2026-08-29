class_name PlayerGearOverlay
extends Node2D

const ERA_PROFILE = preload("res://scripts/progression/era_profile.gd")

var _era_id := "prehistoric"
var _equipment: Dictionary = {}
var _accent := Color(0.35, 0.82, 0.45)

func setup(era_id: String, equipment: Dictionary) -> void:
	_era_id = era_id
	_accent = ERA_PROFILE.get_transition_color(era_id)
	_equipment = equipment.duplicate(true)
	queue_redraw()

func set_era(era_id: String) -> void:
	_era_id = era_id
	_accent = ERA_PROFILE.get_transition_color(era_id)
	queue_redraw()

func set_equipment(equipment: Dictionary) -> void:
	_equipment = equipment.duplicate(true)
	queue_redraw()

func _draw() -> void:
	var armor: Dictionary = _equipment.get("armor", {})
	var helmet: Dictionary = _equipment.get("helmet", {})
	var weapon: Dictionary = _equipment.get("weapon", {})
	var gloves: Dictionary = _equipment.get("gloves", {})
	var boots: Dictionary = _equipment.get("boots", {})
	var amulet: Dictionary = _equipment.get("amulet", {})
	if armor is Dictionary and not armor.is_empty():
		var color := _rarity_color(armor)
		draw_colored_polygon(PackedVector2Array([Vector2(-26, -17), Vector2(26, -17), Vector2(31, 28), Vector2(0, 36), Vector2(-31, 28)]), Color(color, 0.42))
		draw_polyline(PackedVector2Array([Vector2(-26, -17), Vector2(26, -17), Vector2(31, 28), Vector2(0, 36), Vector2(-31, 28), Vector2(-26, -17)]), color, 3.0, true)
	if helmet is Dictionary and not helmet.is_empty():
		var color := _rarity_color(helmet)
		draw_arc(Vector2(0, -25), 27.0, PI, TAU, 20, color, 5.0, true)
		draw_line(Vector2(-27, -22), Vector2(27, -22), color, 4.0)
	if weapon is Dictionary and not weapon.is_empty():
		var color := _rarity_color(weapon)
		var attack_type := String(weapon.get("attack_type", ""))
		var weapon_stats: Dictionary = weapon.get("stats", {})
		if attack_type == "ranged" or float(weapon_stats.get("attack_range", 0.0)) >= 160.0:
			draw_arc(Vector2(42, 3), 19.0, -1.25, 1.25, 18, color, 4.0, true)
			draw_line(Vector2(42, -16), Vector2(42, 22), color, 2.0)
		else:
			draw_line(Vector2(19, 21), Vector2(47, -19), color, 6.0)
			draw_line(Vector2(13, 17), Vector2(25, 27), _accent, 4.0)
	if gloves is Dictionary and not gloves.is_empty():
		var color := _rarity_color(gloves)
		draw_circle(Vector2(-31, 5), 7.0, color)
		draw_circle(Vector2(31, 5), 7.0, color)
	if boots is Dictionary and not boots.is_empty():
		var color := _rarity_color(boots)
		draw_line(Vector2(-16, 30), Vector2(-20, 47), color, 7.0)
		draw_line(Vector2(16, 30), Vector2(20, 47), color, 7.0)
	if amulet is Dictionary and not amulet.is_empty():
		var color := _rarity_color(amulet)
		draw_arc(Vector2(0, 23), 9.0, PI + 0.2, TAU - 0.2, 14, color, 3.0, true)
		draw_colored_polygon(PackedVector2Array([Vector2(0, 29), Vector2(7, 36), Vector2(0, 43), Vector2(-7, 36)]), color)

func _rarity_color(instance: Dictionary) -> Color:
	var rarity := String(instance.get("rarity", "common"))
	var tree := Engine.get_main_loop() as SceneTree
	var loot_manager := tree.root.get_node_or_null("/root/LootManager") if tree != null else null
	if loot_manager != null:
		return loot_manager.get_rarity_color(rarity).lightened(0.12)
	return Color(0.75, 0.78, 0.86)
