extends Node

signal research_completed(technology_id: String)

var _check_timer: Timer

func _ready() -> void:
	_check_timer = Timer.new()
	_check_timer.wait_time = 1.0
	_check_timer.autostart = true
	_check_timer.timeout.connect(check_completion)
	add_child(_check_timer)

func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_RESUMED:
		check_completion()

func is_researching() -> bool:
	return GameState.current_research != null

func get_remaining_seconds() -> int:
	if GameState.current_research == null:
		return 0
	var started: int = int(GameState.current_research.get("started_at", 0))
	var duration: int = int(GameState.current_research.get("duration_seconds", 0))
	var elapsed := int(Time.get_unix_time_from_system()) - started
	return maxi(duration - elapsed, 0)

func get_accelerate_cost() -> int:
	if not is_researching():
		return 0
	return maxi(1, int(ceil(float(get_remaining_seconds()) / 300.0)))

func accelerate_current() -> bool:
	if not is_researching():
		return false
	var crystals := get_accelerate_cost()
	if not Economy.spend({"crystals": crystals}):
		return false
	GameState.current_research["started_at"] = int(GameState.current_research.get("started_at", 0)) - crystals * 300
	check_completion()
	SignalBus.save_requested.emit()
	return true

func is_completed(technology_id: String) -> bool:
	return String(technology_id) in GameState.technologies

func is_researching_era() -> bool:
	return is_researching() and String(GameState.current_research.get("research_type", "technology")) == "era"

func can_start(technology_id: String) -> Dictionary:
	var tech := _get_tech(technology_id)
	if tech.is_empty():
		return { "ok": false, "reason": "Tecnología inexistente" }
	if is_completed(technology_id):
		return { "ok": false, "reason": "Ya investigada" }
	if is_researching():
		return { "ok": false, "reason": "Ya hay una investigación en curso" }
	for req_id in tech.get("requirements", []):
		if not is_completed(String(req_id)):
			return { "ok": false, "reason": "Falta requisito: %s" % req_id }
	var tech_era := String(tech.get("era", "prehistoric"))
	var current_order := _era_order(GameState.current_era)
	var tech_order := _era_order(tech_era)
	if tech_order > current_order:
		var era_name := String(DataLoader.load_json("eras/eras.json").get(tech_era, {}).get("name", tech_era))
		return { "ok": false, "reason": "Requiere era: %s" % era_name }
	var cost: Dictionary = tech.get("cost", {})
	if not Economy.can_afford(cost):
		return { "ok": false, "reason": "Recursos insuficientes" }
	return { "ok": true, "reason": "" }

func start_research(technology_id: String) -> bool:
	var check := can_start(technology_id)
	if not bool(check["ok"]):
		return false
	var tech := _get_tech(technology_id)
	var cost: Dictionary = tech.get("cost", {})
	if not Economy.spend(cost):
		return false
	GameState.current_research = {
		"research_type": "technology",
		"technology_id": technology_id,
		"started_at": int(Time.get_unix_time_from_system()),
		"duration_seconds": int(tech.get("duration_seconds", 0)),
	}
	SignalBus.save_requested.emit()
	return true

func can_start_era(era_id: String) -> Dictionary:
	var eras: Dictionary = DataLoader.load_json("eras/eras.json")
	var era: Dictionary = eras.get(era_id, {})
	if era.is_empty():
		return { "ok": false, "reason": "Era inexistente" }
	if is_researching():
		return { "ok": false, "reason": "Ya hay una investigación en curso" }
	var current_order := _era_order(GameState.current_era)
	var requested_order := int(era.get("order", 99))
	if requested_order != current_order + 1:
		var current_name := String(eras.get(GameState.current_era, {}).get("name", GameState.current_era))
		return { "ok": false, "reason": "Primero completa la investigacion de %s" % current_name }
	var missing_technologies: PackedStringArray = []
	for req_id in era.get("requirements", []):
		if not is_completed(String(req_id)):
			missing_technologies.append(_technology_name(String(req_id)))
	if not missing_technologies.is_empty():
		return { "ok": false, "reason": "Falta tecnologia: " + ", ".join(missing_technologies) }
	var cost: Dictionary = era.get("unlock_cost", {})
	var missing_resources: PackedStringArray = []
	for resource_id in cost.keys():
		var required := int(cost[resource_id])
		var available := int(GameState.get(String(resource_id)))
		if available < required:
			missing_resources.append("%s %s (tienes %s)" % [_format_amount(required), _resource_name(String(resource_id)), _format_amount(available)])
	if not missing_resources.is_empty():
		return { "ok": false, "reason": "Necesitas: " + " · ".join(missing_resources) }
	return { "ok": true, "reason": "" }

func start_era_research(era_id: String) -> bool:
	var check := can_start_era(era_id)
	if not bool(check["ok"]):
		return false
	var era: Dictionary = DataLoader.load_json("eras/eras.json").get(era_id, {})
	if not Economy.spend(era.get("unlock_cost", {})):
		return false
	GameState.current_research = {
		"research_type": "era",
		"era_id": era_id,
		"technology_id": "",
		"started_at": int(Time.get_unix_time_from_system()),
		"duration_seconds": int(era.get("research_time_seconds", 0)),
	}
	SignalBus.save_requested.emit()
	return true

func check_completion() -> bool:
	if GameState.current_research == null:
		return false
	var research_type := String(GameState.current_research.get("research_type", "technology"))
	var started: int = int(GameState.current_research.get("started_at", 0))
	var duration: int = int(GameState.current_research.get("duration_seconds", 0))
	if int(Time.get_unix_time_from_system()) - started < duration:
		return false
	if research_type == "era":
		_complete_era(String(GameState.current_research.get("era_id", "")))
	else:
		_complete(String(GameState.current_research.get("technology_id", "")))
	return true

func cancel_current() -> void:
	if GameState.current_research == null:
		return
	var cost: Dictionary = {}
	if String(GameState.current_research.get("research_type", "technology")) == "era":
		var era: Dictionary = DataLoader.load_json("eras/eras.json").get(String(GameState.current_research.get("era_id", "")), {})
		cost = era.get("unlock_cost", {})
	else:
		var tech := _get_tech(String(GameState.current_research.get("technology_id", "")))
		cost = tech.get("cost", {})
	for currency in cost.keys():
		GameState.set(currency, GameState.get(currency) + int(cost[currency]))
	GameState.current_research = null
	SignalBus.save_requested.emit()

func _complete(technology_id: String) -> void:
	var tech := _get_tech(technology_id)
	GameState.technologies[technology_id] = true
	GameState.current_research = null
	EffectProcessor.apply(tech.get("effects", []))
	GameState.pending_notifications.append({"type": "technology", "id": technology_id})
	AudioManager.play_sfx("technology")
	AudioManager.vibrate(45)
	SignalBus.technology_completed.emit(technology_id)
	research_completed.emit(technology_id)
	SignalBus.save_requested.emit()

func _complete_era(era_id: String) -> void:
	var era: Dictionary = DataLoader.load_json("eras/eras.json").get(era_id, {})
	if era.is_empty():
		GameState.current_research = null
		SignalBus.save_requested.emit()
		return
	GameState.current_era = era_id
	GameState.current_research = null
	GameState.pending_notifications.append({"type": "era", "id": era_id})
	AudioManager.play_sfx("technology")
	AudioManager.vibrate(80)
	SignalBus.era_changed.emit(era_id)
	SignalBus.save_requested.emit()

func _get_tech(technology_id: String) -> Dictionary:
	return DataLoader.load_json("technologies/technologies.json").get(technology_id, {})

func _era_order(era_id: String) -> int:
	return int(DataLoader.load_json("eras/eras.json").get(era_id, {}).get("order", 99))

func _technology_name(technology_id: String) -> String:
	var technology: Dictionary = DataLoader.load_json("technologies/technologies.json").get(technology_id, {})
	return String(technology.get("name", technology_id))

func _resource_name(resource_id: String) -> String:
	return {
		"gold": "oro",
		"science": "ciencia",
		"materials": "materiales",
		"crystals": "cristales",
	}.get(resource_id, resource_id)

func _format_amount(amount: int) -> String:
	var digits := str(abs(amount))
	var groups: Array[String] = []
	while digits.length() > 3:
		groups.push_front(digits.substr(digits.length() - 3, 3))
		digits = digits.substr(0, digits.length() - 3)
	groups.push_front(digits)
	return ("-" if amount < 0 else "") + ".".join(groups)
