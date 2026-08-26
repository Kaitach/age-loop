extends SceneTree

const BATTLE_SCENE := "res://scenes/battle/battle.tscn"

func _initialize() -> void:
	print("[TEST] Test de datos de oleadas iniciando...")

func _process(_delta: float) -> bool:
	_run_checks()
	quit(0)
	return true

func _run_checks() -> void:
	var q1 := WaveManager.build_spawn_queue(1, 1)
	_check(q1.size() == 4, "oleada 1-1 genera 4 enemigos (obtuve %d)" % q1.size())

	var q5 := WaveManager.build_spawn_queue(1, 5)
	_check(q5.size() == 6, "oleada 1-5 genera 6 enemigos (obtuve %d)" % q5.size())

	var q9 := WaveManager.build_spawn_queue(1, 9)
	var ids := {}
	for entry in q9:
		ids[entry["id"]] = true
	_check(ids.has("tank") and ids.has("fast") and ids.has("normal"), "oleada 1-9 mezcla 3 tipos de enemigo")

	var q10 := WaveManager.build_spawn_queue(1, 10)
	var has_boss := false
	for entry in q10:
		if entry["id"] == "boss_mamut":
			has_boss = true
	_check(has_boss, "oleada 1-10 incluye al boss")

	var ordered := true
	for i in range(1, q10.size()):
		if float(q10[i]["time"]) < float(q10[i - 1]["time"]):
			ordered = false
	_check(ordered, "la cola de spawn esta ordenada por tiempo")

	var r1 := WaveManager.calculate_rewards(1, 1)
	_check(int(r1["gold"]) > 0 and int(r1["science"]) > 0 and int(r1["materials"]) > 0, "recompensas positivas en 1-1")

	var r10 := WaveManager.calculate_rewards(1, 10)
	_check(int(r10["gold"]) > int(r1["gold"]), "el boss paga mas oro que la oleada 1")

	var hp1 := WaveManager.hp_scale_for(1, 1)
	var hp4 := WaveManager.hp_scale_for(1, 4)
	_check(hp1 == 1.0 and hp4 > hp1, "escalado de HP crece con la oleada global")

	var boss_data := WaveManager.get_enemy_data("boss_mamut")
	_check(not boss_data.is_empty() and bool(boss_data.get("is_boss", false)), "template del boss existe y esta marcado como boss")

	print("[TEST] PASS: todas las verificaciones de oleadas ok")

func _check(cond: bool, msg: String) -> void:
	if not cond:
		printerr("[TEST] FAIL: " + msg)
		quit(1)
