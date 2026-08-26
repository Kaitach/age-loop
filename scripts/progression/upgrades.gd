class_name Upgrades
extends RefCounted

const DATA_PATH := "upgrades/upgrades.json"

static func defs() -> Dictionary:
	return DataLoader.load_json(DATA_PATH)

static func _game_state() -> Node:
	var tree := Engine.get_main_loop() as SceneTree
	return tree.root.get_node("/root/GameState")

static func get_level(upgrade_id: String) -> int:
	return int(_game_state().upgrades.get(upgrade_id, 0))

static func is_maxed(upgrade_id: String) -> bool:
	var def: Dictionary = defs().get(upgrade_id, {})
	return get_level(upgrade_id) >= int(def.get("max_level", 99))

static func cost_for(upgrade_id: String) -> int:
	var def: Dictionary = defs().get(upgrade_id, {})
	var level := get_level(upgrade_id)
	return int(round(float(def.get("base_cost", 0)) * pow(float(def.get("cost_growth", 1.5)), level)))

static func bonus_value(upgrade_id: String) -> int:
	var def: Dictionary = defs().get(upgrade_id, {})
	return get_level(upgrade_id) * int(def.get("per_level", 0))

static func try_buy(upgrade_id: String) -> bool:
	if is_maxed(upgrade_id):
		return false
	var tree := Engine.get_main_loop() as SceneTree
	var economy := tree.root.get_node("/root/Economy")
	if not economy.spend({ "gold": cost_for(upgrade_id) }):
		return false
	var game_state := _game_state()
	game_state.upgrades[upgrade_id] = get_level(upgrade_id) + 1
	return true
