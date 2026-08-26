extends SceneTree

func _initialize() -> void:
	print("[TEST] Test de progreso offline iniciando...")

func _process(_delta: float) -> bool:
	_run_checks()
	quit(0)
	return true

func _run_checks() -> void:
	var gs := root.get_node("/root/GameState")
	var bm := root.get_node("/root/BuildingManager")
	var off := root.get_node("/root/OfflineManager")

	gs.buildings = {}
	gs.gold = 0
	gs.materials = 0
	gs.last_played_at = int(Time.get_unix_time_from_system()) - 3600
	var r0: Dictionary = off.get_offline_rewards()
	_check(int(r0["gold"]) == 0 and int(r0["materials"]) == 0, "sin edificios no hay recompensa offline")

	gs.buildings = { "market": 1, "mine": 1 }
	gs.last_played_at = int(Time.get_unix_time_from_system()) - 3600
	var r1: Dictionary = off.get_offline_rewards()
	_check(int(r1["elapsed"]) == 3600, "elapsed 1h")
	_check(int(r1["gold"]) == 2880, "gold correcto para 1h con market nv1 (48/min)")
	_check(int(r1["materials"]) == 360, "materials correcto para 1h con mine nv1 (6/min)")

	var max_sec: int = off.get_max_offline_seconds()
	gs.last_played_at = int(Time.get_unix_time_from_system()) - (max_sec + 3600)
	var r_cap: Dictionary = off.get_offline_rewards()
	_check(int(r_cap["elapsed"]) == max_sec, "cap a 8h")

	gs.last_played_at = int(Time.get_unix_time_from_system()) - 30
	var r_short: Dictionary = off.get_offline_rewards()
	_check(int(r_short["gold"]) == 0 and int(r_short["elapsed"]) == 30, "menos de 60s da 0 gold pero elapsed correcto")

	gs.last_played_at = 0
	var r_never: Dictionary = off.get_offline_rewards()
	_check(int(r_never["elapsed"]) == 0, "sin last_played_at no hay offline")

	_check(off.format_elapsed(3720) == "1h 2m", "formato 3720s = 1h 2m")
	_check(off.format_elapsed(45) == "0m", "formato <60s = 0m")

	gs.buildings = { "market": 1 }
	gs.gold = 100
	gs.last_played_at = int(Time.get_unix_time_from_system()) - 7200
	var rewards: Dictionary = off.get_offline_rewards()
	var gold_before := int(gs.gold)
	off.claim(rewards)
	_check(int(gs.gold) > gold_before, "claim suma oro")
	_check(int(gs.last_played_at) > 0, "claim actualiza timestamp")
	var r_after: Dictionary = off.get_offline_rewards()
	_check(int(r_after["elapsed"]) < 5, "tras claim no hay recompensa inmediata")

	gs.buildings = {}
	gs.last_played_at = 0
	print("[TEST] PASS: todas las verificaciones offline ok")

func _check(cond: bool, msg: String) -> void:
	if not cond:
		printerr("[TEST] FAIL: " + msg)
		quit(1)
