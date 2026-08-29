extends Node

signal building_upgraded(building_id: String, level: int)

var _passive_timer: Timer
var _gold_acc: float = 0.0
var _materials_acc: float = 0.0

func _ready() -> void:
	_passive_timer = Timer.new()
	_passive_timer.wait_time = 1.0
	_passive_timer.autostart = true
	_passive_timer.timeout.connect(_on_passive_tick)
	add_child(_passive_timer)

func get_level(building_id: String) -> int:
	return int(GameState.buildings.get(building_id, 0))

func get_max_level(building_id: String) -> int:
	return int(DataLoader.load_json("buildings/buildings.json").get(building_id, {}).get("max_level", 99))

func is_maxed(building_id: String) -> bool:
	return get_level(building_id) >= get_max_level(building_id)

func get_cost(building_id: String) -> Dictionary:
	var def: Dictionary = DataLoader.load_json("buildings/buildings.json").get(building_id, {})
	var base_cost: Dictionary = def.get("base_cost", {})
	var growth := float(def.get("cost_growth", 1.35))
	var level := get_level(building_id)
	var cost := {}
	for currency in base_cost.keys():
		var raw := float(base_cost[currency]) * pow(growth, level)
		if currency == "gold" or currency == "materials":
			raw *= maxf(0.0, 1.0 + GameState.get_effect_modifier("building_cost"))
		cost[currency] = int(round(raw))
	return cost

func can_upgrade(building_id: String) -> bool:
	if not is_unlocked(building_id):
		return false
	if is_maxed(building_id):
		return false
	return Economy.can_afford(get_cost(building_id))

func upgrade(building_id: String) -> bool:
	if not can_upgrade(building_id):
		return false
	if not Economy.spend(get_cost(building_id)):
		return false
	GameState.buildings[building_id] = get_level(building_id) + 1
	building_upgraded.emit(building_id, get_level(building_id))
	SignalBus.save_requested.emit()
	return true

func get_bonus(stat_key: String) -> float:
	var total := 0.0
	var buildings: Dictionary = DataLoader.load_json("buildings/buildings.json")
	for building_id in buildings.keys():
		var per_level: Dictionary = buildings[building_id].get("per_level", {})
		if per_level.has(stat_key):
			total += float(per_level[stat_key]) * get_level(building_id)
	return total

func calculate_passive_income() -> Dictionary:
	return {
		"gold_per_sec": get_bonus("gold_per_min") / 60.0 * (1.0 + GameState.get_effect_modifier("gold_per_second")),
		"materials_per_sec": get_bonus("materials_per_min") / 60.0 * (1.0 + GameState.get_effect_modifier("materials_per_minute")),
		"science_per_sec": get_bonus("science_per_sec") / 60.0 * (1.0 + GameState.get_effect_modifier("science_per_second")),
	}

func is_unlocked(building_id: String) -> bool:
	var def: Dictionary = DataLoader.load_json("buildings/buildings.json").get(building_id, {})
	var required := String(def.get("required_technology", ""))
	if required.is_empty():
		return true
	return ResearchManager.is_completed(required) or GameState.has_unlocked_content("buildings", building_id)

func unlock_requirement(building_id: String) -> String:
	var def: Dictionary = DataLoader.load_json("buildings/buildings.json").get(building_id, {})
	return String(def.get("required_technology", ""))

func _on_passive_tick() -> void:
	var income := calculate_passive_income()
	_gold_acc += float(income["gold_per_sec"])
	_materials_acc += float(income["materials_per_sec"])
	var gold_gain := int(floor(_gold_acc))
	var mat_gain := int(floor(_materials_acc))
	if gold_gain > 0:
		_gold_acc -= gold_gain
		Economy.add_gold(gold_gain)
	if mat_gain > 0:
		_materials_acc -= mat_gain
		Economy.add_materials(mat_gain)
