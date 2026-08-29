extends SceneTree

func _initialize() -> void:
	print("[TEST] Test de investigacion iniciando...")

func _process(_delta: float) -> bool:
	_run_checks()
	quit(0)
	return true

func _run_checks() -> void:
	var gs := root.get_node("/root/GameState")
	var rm := root.get_node("/root/ResearchManager")
	var eco := root.get_node("/root/Economy")

	gs.gold = 10000
	gs.science = 1000
	gs.materials = 1000
	gs.crystals = 1
	gs.technologies = {}
	gs.current_research = null
	gs.effect_modifiers = {}
	gs.effect_additions = {}
	gs.current_era = "prehistoric"

	_check(rm.can_start("gathering")["ok"] == true, "gathering disponible sin requisitos")
	_check(rm.start_research("gathering") == true, "inicia gathering")
	_check(rm.is_researching() == true, "estado investigando")
	_check(rm.start_research("hunting") == false, "no permite segunda investigacion simultanea")
	_check(int(gs.gold) < 10000, "costo descontado al iniciar")

	_check(rm.can_start("primitive_smelting")["ok"] == false, "fundicion primitiva bloqueada sin prereqs")
	rm.cancel_current()
	_check(rm.is_researching() == false and gs.current_research == null, "cancelar limpia investigacion")

	gs.gold = 5
	gs.science = 0
	_check(rm.start_research("gathering") == false, "sin recursos no inicia")

	gs.gold = 10000
	gs.science = 1000
	_check(rm.start_research("gathering") == true, "reinicia gathering con recursos")
	var rid: String = String(gs.current_research["technology_id"])
	_check(rid == "gathering", "id de investigacion correcta")
	gs.current_research["started_at"] = int(Time.get_unix_time_from_system()) - 9999
	_check(rm.check_completion() == true, "completa por tiempo con timestamp")
	_check(rm.is_completed("gathering") == true, "gathering marcada como completada")
	_check(absf(float(gs.effect_modifiers.get("gold_reward", 0.0)) - 0.1) < 0.0001, "el efecto de gathering se aplica al balance")
	_check(rm.is_researching() == false, "sin investigacion activa tras completar")

	_check(rm.start_research("primitive_smelting") == false, "aun bloqueada pese a gathering")
	var bronze_locked_reason := String(rm.can_start_era("bronze")["reason"])
	_check("Fundicion primitiva" in bronze_locked_reason, "bronce explica la tecnologia que falta")
	gs.technologies["hunting"] = true
	gs.technologies["club_crafting"] = true
	gs.technologies["campfire"] = true
	gs.technologies["hut"] = true
	gs.technologies["stone_tools"] = true
	_check(rm.can_start("primitive_smelting")["ok"] == true, "fundicion primitiva desbloqueada tras prereqs")
	_check(rm.start_research("primitive_smelting") == true, "inicia fundicion primitiva")

	var bronze_before: String = gs.current_era
	gs.current_research["started_at"] = int(Time.get_unix_time_from_system()) - 9999
	rm.check_completion()
	_check(rm.is_completed("primitive_smelting") == true, "fundicion completada")
	_check(bool(gs.unlocked_items.get("bronze_armor", false)), "fundicion desbloquea la coraza de bronce")
	_check(EffectProcessor.describe_effect({"type": "unlock_item", "value": "bronze_armor"}) == "Desbloquea objeto: Coraza de bronce", "describe desbloqueos con nombre visible")
	_check(gs.current_era == bronze_before, "la tecnologia no salta la era sin pagar su avance")
	gs.gold = 100
	gs.science = 100
	var bronze_resources_reason := String(rm.can_start_era("bronze")["reason"])
	_check("8.000 oro" in bronze_resources_reason, "bronce explica el oro exacto que falta")
	gs.gold = 10000
	gs.science = 1000
	_check(rm.can_start_era("bronze")["ok"] == true, "avance a bronce disponible tras tecnologia")
	_check(rm.start_era_research("bronze") == true, "inicia avance de era con costo")
	gs.current_research["started_at"] = int(Time.get_unix_time_from_system()) - 9999
	rm.check_completion()
	_check(gs.current_era == "bronze", "era cambia a bronce al terminar su investigacion")

	_check(rm.can_start("bronze_smelting")["ok"] == true, "tecnologia de bronce disponible tras era")
	gs.gold = 0
	_check(rm.start_research("bronze_smelting") == false, "sin oro no inicia bronce")

	gs.gold = 10000
	gs.science = 1000
	_check(rm.start_research("bronze_smelting") == true, "inicia bronce con recursos")
	gs.current_research["started_at"] = int(Time.get_unix_time_from_system()) - 9999
	rm.check_completion()
	_check(rm.is_completed("bronze_smelting") == true, "bronce completada")

	_check(rm.start_research("bronze_sword") == true, "inicia tecnologia para probar aceleracion")
	_check(rm.get_accelerate_cost() == 1, "calcula costo de acelerar en cristales")
	_check(rm.accelerate_current() == true, "acelera investigacion con cristales")
	_check(rm.is_completed("bronze_sword") == true, "acelerar puede completar investigacion")

	print("[TEST] PASS: todas las verificaciones de investigacion ok")

func _check(cond: bool, msg: String) -> void:
	if not cond:
		printerr("[TEST] FAIL: " + msg)
		quit(1)
