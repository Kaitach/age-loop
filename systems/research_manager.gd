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

func is_completed(technology_id: String) -> bool:
	return String(technology_id) in GameState.technologies

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
		"technology_id": technology_id,
		"started_at": int(Time.get_unix_time_from_system()),
		"duration_seconds": int(tech.get("duration_seconds", 0)),
	}
	SignalBus.save_requested.emit()
	return true

func check_completion() -> bool:
	if GameState.current_research == null:
		return false
	var technology_id := String(GameState.current_research.get("technology_id", ""))
	var started: int = int(GameState.current_research.get("started_at", 0))
	var duration: int = int(GameState.current_research.get("duration_seconds", 0))
	if int(Time.get_unix_time_from_system()) - started < duration:
		return false
	_complete(technology_id)
	return true

func cancel_current() -> void:
	if GameState.current_research == null:
		return
	var tech := _get_tech(String(GameState.current_research.get("technology_id", "")))
	var cost: Dictionary = tech.get("cost", {})
	for currency in cost.keys():
		GameState.set(currency, GameState.get(currency) + int(cost[currency]))
	GameState.current_research = null
	SignalBus.save_requested.emit()

func _complete(technology_id: String) -> void:
	var tech := _get_tech(technology_id)
	GameState.technologies[technology_id] = true
	GameState.current_research = null
	EffectProcessor.apply(tech.get("effects", []))
	SignalBus.technology_completed.emit(technology_id)
	research_completed.emit(technology_id)
	SignalBus.save_requested.emit()

func _get_tech(technology_id: String) -> Dictionary:
	return DataLoader.load_json("technologies/technologies.json").get(technology_id, {})
