extends SceneTree

const BATTLE_SCENE := "res://scenes/battle/battle.tscn"

var _frames := 0
var _phase := "fight"
var _battle: Node

func _initialize() -> void:
	print("[TEST] Smoke test de batalla iniciando...")
	var packed: PackedScene = load(BATTLE_SCENE)
	_battle = packed.instantiate()
	root.add_child(_battle)
	_battle.spawn_interval = 0.05

func _process(_delta: float) -> bool:
	_frames += 1
	match _phase:
		"fight":
			for node in get_nodes_in_group("enemies"):
				node.take_damage(9999)
			if _battle.did_win():
				_pass("victoria detectada tras eliminar enemigos")
				_battle.queue_free()
				_phase = "defeat_setup"
				_frames = 0
			elif _frames > 3600:
				return _fail("no se detecto victoria en tiempo limite")
		"defeat_setup":
			if _frames >= 5:
				var packed: PackedScene = load(BATTLE_SCENE)
				_battle = packed.instantiate()
				root.add_child(_battle)
				var base_fort := _battle.get_node("World/Base") as Combatant
				base_fort.take_damage(999999)
				_frames = 0
				_phase = "defeat_check"
		"defeat_check":
			if _frames >= 5:
				if _battle.is_over() and not _battle.did_win():
					_pass("derrota detectada al destruir la base")
					quit(0)
					return true
				return _fail("la derrota no fue detectada")
	return false

func _pass(msg: String) -> void:
	print("[TEST] PASS: " + msg)

func _fail(msg: String) -> bool:
	printerr("[TEST] FAIL: " + msg)
	quit(1)
	return true
