extends SceneTree

func _initialize() -> void:
	print("[TEST] Test de economia iniciando...")

func _process(_delta: float) -> bool:
	_run_checks()
	quit(0)
	return true

func _run_checks() -> void:
	var gs := root.get_node("/root/GameState")
	var eco := root.get_node("/root/Economy")

	gs.gold = 100
	gs.science = 10
	gs.materials = 5
	gs.crystals = 0
	gs.upgrades = {}

	_check(not eco.can_afford({ "gold": 150 }), "no permite gastar saldo insuficiente")
	_check(not eco.spend({ "gold": 150 }), "spend falla con saldo insuficiente")
	_check(int(gs.gold) == 100, "el oro no cambia ante compra fallida")

	_check(eco.spend({ "gold": 30, "science": 5 }), "compra multi-moneda aceptada")
	_check(int(gs.gold) == 70 and int(gs.science) == 5, "descuento exacto de cada moneda")

	eco.add_materials(10)
	_check(int(gs.materials) == 15, "add_materials suma correctamente")

	eco.add_gold(-999)
	_check(int(gs.gold) == 70, "montos negativos se ignoran")

	var cost0 := Upgrades.cost_for("player_damage")
	_check(cost0 > 0, "costo inicial de mejora positivo")

	gs.gold = cost0
	_check(Upgrades.try_buy("player_damage"), "compra de mejora con oro justo")
	_check(int(Upgrades.get_level("player_damage")) == 1, "nivel de mejora incrementa")
	_check(int(Upgrades.bonus_value("player_damage")) == 4, "bonus por nivel correcto (+4)")
	_check(int(gs.gold) == 0, "el pago descuenta todo el oro usado")

	var cost1 := Upgrades.cost_for("player_damage")
	_check(cost1 > cost0, "el costo escala con el nivel")

	gs.upgrades = { "player_damage": 50 }
	_check(Upgrades.is_maxed("player_damage"), "respeta max_level")
	_check(not Upgrades.try_buy("player_damage"), "no permite comprar en maximo")

	print("[TEST] PASS: todas las verificaciones de economia ok")

func _check(cond: bool, msg: String) -> void:
	if not cond:
		printerr("[TEST] FAIL: " + msg)
		quit(1)
