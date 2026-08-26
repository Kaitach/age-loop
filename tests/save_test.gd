extends SceneTree

func _initialize() -> void:
	print("[TEST] Test de guardado iniciando...")

func _process(_delta: float) -> bool:
	_run_checks()
	quit(0)
	return true

func _run_checks() -> void:
	var gs := root.get_node("/root/GameState")
	var saver := root.get_node("/root/SaveManager")

	saver.delete_save()
	_check(not saver.has_save(), "delete_save elimina el archivo")
	_check(not saver.load_game(), "load sin archivo devuelve false sin crashear")

	gs.gold = 7777
	gs.science = 33
	gs.materials = 222
	gs.crystals = 4
	gs.world = 1
	gs.wave = 7
	gs.current_era = "prehistoric"
	gs.upgrades = { "player_damage": 5, "base_health": 2 }
	gs.stats["enemies_killed"] = 120
	gs.stats["bosses_killed"] = 1
	gs.stats["waves_completed"] = 6

	saver.save_game()
	_check(saver.has_save(), "save_game crea el archivo")

	gs.gold = 0
	gs.wave = 1
	gs.upgrades = {}
	gs.stats["enemies_killed"] = 0

	var loaded: bool = saver.load_game()
	_check(loaded, "load_game carga el save existente")
	_check(int(gs.gold) == 7777 and int(gs.science) == 33 and int(gs.materials) == 222 and int(gs.crystals) == 4, "monedas restauradas")
	_check(int(gs.wave) == 7, "progresion de oleada restaurada")
	_check(int(gs.upgrades.get("player_damage", 0)) == 5 and int(gs.upgrades.get("base_health", 0)) == 2, "mejoras restauradas")
	_check(int(gs.stats["enemies_killed"]) == 120 and int(gs.stats["bosses_killed"]) == 1 and int(gs.stats["waves_completed"]) == 6, "estadisticas restauradas")

	var file := FileAccess.open("user://savegame.json", FileAccess.WRITE)
	file.store_string("{ esto no es json valido !!!")
	file.close()
	var result: bool = saver.load_game()
	_check(not result, "save corrupto no crashea y devuelve false")
	_check(not saver.has_save(), "el save corrupto se retira del path principal")
	_check(FileAccess.file_exists("user://savegame.backup.json"), "se genera backup del save corrupto")

	gs.upgrades = { "player_damage": 9 }
	var data := { "version": 1, "currencies": { "gold": 50 }, "progression": { "world": 2, "wave": 3 } }
	saver.migrate_save(data)
	saver._apply_to_game_state(data)
	_check(int(gs.gold) == 50 and int(gs.world) == 2 and int(gs.wave) == 3, "campos faltantes usan defaults sin romper nada")

	saver.delete_save()
	print("[TEST] PASS: todas las verificaciones de save ok")

func _check(cond: bool, msg: String) -> void:
	if not cond:
		printerr("[TEST] FAIL: " + msg)
		quit(1)
