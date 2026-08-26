extends SceneTree

func _initialize() -> void:
	print("[TEST] Test de edificios iniciando...")

func _process(_delta: float) -> bool:
	_run_checks()
	quit(0)
	return true

func _run_checks() -> void:
	var gs := root.get_node("/root/GameState")
	var bm := root.get_node("/root/BuildingManager")
	var eco := root.get_node("/root/Economy")

	gs.gold = 10000
	gs.materials = 5000
	gs.buildings = {}

	_check(bm.get_level("market") == 0, "nivel inicial 0")
	var cost0: Dictionary = bm.get_cost("market")
	_check(int(cost0["gold"]) > 0 and int(cost0["materials"]) > 0, "costo inicial positivo")
	_check(bm.can_upgrade("market") == true, "puede mejorar con recursos")
	_check(bm.upgrade("market") == true, "upgrade exitoso")
	_check(bm.get_level("market") == 1, "nivel incrementa")
	_check(int(gs.gold) < 10000, "oro descontado")

	var cost1: Dictionary = bm.get_cost("market")
	_check(int(cost1["gold"]) > int(cost0["gold"]), "costo escala con nivel")

	gs.gold = 0
	gs.materials = 0
	_check(bm.can_upgrade("market") == false, "sin recursos no puede mejorar")
	_check(bm.upgrade("market") == false, "upgrade falla sin recursos")

	gs.buildings = { "market": 20 }
	_check(bm.is_maxed("market") == true, "detecta nivel maximo")
	_check(bm.upgrade("market") == false, "no mejora en maximo")

	gs.buildings = { "market": 2, "mine": 3 }
	var income: Dictionary = bm.calculate_passive_income()
	_check(float(income["gold_per_sec"]) > 0.0 and float(income["materials_per_sec"]) > 0.0, "ingreso pasivo positivo con edificios")
	_check(absf(float(income["gold_per_sec"]) - 2.0 * 48.0 / 60.0) < 0.01, "oro por segundo correcto para market nv2")
	_check(absf(float(income["materials_per_sec"]) - 3.0 * 6.0 / 60.0) < 0.01, "materiales por segundo correcto para mine nv3")

	gs.buildings = { "wall": 4 }
	_check(absf(bm.get_bonus("base_health_bonus") - 120.0) < 0.01, "bonus de muralla 4*30=120")
	_check(absf(bm.get_bonus("gold_per_min") - 0.0) < 0.01, "bonus inexistente es 0")

	gs.buildings = {}
	print("[TEST] PASS: todas las verificaciones de edificios ok")

func _check(cond: bool, msg: String) -> void:
	if not cond:
		printerr("[TEST] FAIL: " + msg)
		quit(1)
