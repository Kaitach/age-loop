extends SceneTree

var _phase := "melee"
var _frames := 0
var _arena: Node2D
var _actor
var _start_x := 0.0
var _started := false

func _initialize() -> void:
	# Los autoloads terminan de entrar al SceneTree despues de initialize().
	# Esperamos al primer frame para reproducir el arranque normal del juego.
	return

func _start_test() -> void:
	var gs := root.get_node("/root/GameState")
	gs.settings["music_enabled"] = false
	gs.settings["sfx_enabled"] = false
	root.get_node("/root/AudioManager").refresh_from_state()
	_setup_actor("melee")

func _process(_delta: float) -> bool:
	if not _started:
		if root.get_node_or_null("/root/GameState") == null:
			return false
		_started = true
		_start_test()
		return false
	_frames += 1
	if _phase == "melee" and _frames >= 30:
		if _actor == null or _actor.attack_type != "melee":
			return _fail("el arma cuerpo a cuerpo no configura el tipo melee")
		if _actor.position.x <= _start_x + 10.0:
			return _fail("el jugador melee no avanza hacia el enemigo")
		_pass("el jugador melee se acerca al enemigo")
		_arena.queue_free()
		_phase = "ranged"
		_frames = 0
		call_deferred("_setup_actor", "ranged")
	elif _phase == "ranged" and _actor != null and _frames >= 30:
		if _actor.attack_type != "ranged":
			return _fail("el arco no configura el tipo ranged")
		if absf(_actor.position.x - _start_x) > 3.0:
			return _fail("el jugador ranged se mueve como melee")
		_pass("el jugador ranged conserva su posicion de ataque")
		quit(0)
		return true
	return false

func _setup_actor(attack_type: String) -> void:
	var gs := root.get_node("/root/GameState")
	gs.equipped_items = {"weapon": _weapon(attack_type)}
	_arena = Node2D.new()
	_arena.name = "CombatBehaviorArena"
	root.add_child(_arena)
	var player_script := load("res://scripts/battle/player.gd") as Script
	_actor = player_script.new()
	_actor.position = Vector2(180.0, 900.0)
	_arena.add_child(_actor)
	var enemy_script := load("res://scripts/enemies/enemy.gd") as Script
	var enemy = enemy_script.new()
	var data: Dictionary = WaveManager.get_enemy_data("normal")
	enemy.setup_from_data("normal", data, 1.0, 1.0)
	enemy.position = Vector2(820.0 if attack_type == "melee" else 480.0, 900.0)
	_arena.add_child(enemy)
	_start_x = _actor.position.x

func _weapon(attack_type: String) -> Dictionary:
	return {
		"id": "test_%s_weapon" % attack_type,
		"slot": "weapon",
		"level": 1,
		"attack_type": attack_type,
		"stats": {"damage": 1, "attack_range": 0 if attack_type == "melee" else 325},
		"modifiers": [],
	}

func _pass(message: String) -> void:
	print("[TEST] PASS: " + message)

func _fail(message: String) -> bool:
	printerr("[TEST] FAIL: " + message)
	quit(1)
	return true
