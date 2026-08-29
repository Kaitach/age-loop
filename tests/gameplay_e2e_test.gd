extends SceneTree

const BATTLE_SCENE := "res://scenes/battle/battle.tscn"

var _battle: Node
var _frames := 0
var _started := false
var _failed := false
var _gold_before_battle := 0

func _initialize() -> void:
	print("[TEST] Flujo E2E de progreso iniciando...")

func _process(_delta: float) -> bool:
	if not _started:
		if root.get_node_or_null("/root/GameState") == null:
			return false
		_started = true
		_run_pre_battle_checks()
		if _failed:
			quit(1)
			return true
		_start_battle()
		return false
	_frames += 1
	if _battle == null or not is_instance_valid(_battle):
		return _fail("la escena de batalla se destruyó antes de terminar")
	if _battle.did_win():
		var gs := root.get_node("/root/GameState")
		_check(int(gs.stats.get("waves_completed", 0)) == 1, "la victoria incrementa oleadas completadas")
		_check(int(gs.gold) > _gold_before_battle, "la victoria entrega oro y respeta el bonus de tecnología")
		_pass("batalla real completada con equipo y tecnología activos")
		quit(0)
		return true
	if _battle.is_over() and not _battle.did_win():
		return _fail("el jugador perdió la batalla E2E")
	if _frames > 900:
		return _fail("la batalla E2E no terminó dentro del límite")
	return false

func _run_pre_battle_checks() -> void:
	var gs := root.get_node("/root/GameState")
	var rm := root.get_node("/root/ResearchManager")
	var inv := root.get_node("/root/InventoryManager")
	var audio := root.get_node("/root/AudioManager")
	gs.settings["music_enabled"] = false
	gs.settings["sfx_enabled"] = false
	audio.refresh_from_state()
	gs.gold = 100000
	gs.science = 100000
	gs.materials = 100000
	gs.crystals = 10
	gs.world = 1
	gs.wave = 1
	gs.current_era = "prehistoric"
	gs.future_era_preview = "medieval"
	gs.inventory = []
	gs.pending_items = []
	gs.equipped_items = {}
	gs.buildings = {}
	gs.technologies = {}
	gs.upgrades = {}
	gs.effect_modifiers = {}
	gs.effect_additions = {}
	gs.unlocked_items = {}
	gs.unlocked_buildings = {}
	gs.unlocked_units = {}
	gs.current_research = null
	gs.pending_notifications = []
	gs.stats = {"enemies_killed": 0, "bosses_killed": 0, "waves_completed": 0}

	var rewards_before: Dictionary = WaveManager.calculate_rewards(1, 1)
	_check(_complete_research(rm, "gathering"), "se completa la primera tecnología por timestamp")
	_check(absf(gs.get_effect_modifier("gold_reward") - 0.1) < 0.0001, "la tecnología de recolección aplica su efecto")
	var rewards_after: Dictionary = WaveManager.calculate_rewards(1, 1)
	_check(int(rewards_after["gold"]) > int(rewards_before["gold"]), "el efecto de recolección cambia las recompensas reales")

	var campfire: Dictionary = DataLoader.load_json("technologies/technologies.json").get("campfire", {})
	EffectProcessor.apply(campfire.get("effects", []))
	_check(gs.get_effect_modifier("regen_between_waves") > 0.0, "Fogata activa regeneración entre oleadas")
	var forging: Dictionary = DataLoader.load_json("technologies/technologies.json").get("iron_forging", {})
	var forging_effects: Array = forging.get("effects", [])
	EffectProcessor.apply(forging_effects)
	_check(gs.get_effect_addition("loot_level_bonus") == 1.0, "Forja de hierro mejora el nivel del loot")

	var ranged_item := {
		"id": "e2e_ranged_weapon",
		"template_id": "hunting_bow",
		"name": "Arco de prueba",
		"slot": "weapon",
		"level": 8,
		"rarity": "epic",
		"attack_type": "ranged",
		"stats": {"damage": 500, "attack_range": 800},
		"modifiers": [{"stat": "attack_speed", "value": 0.2}],
		"sell_value": 1,
	}
	var bare_player := Player.new()
	var bare_stats: Dictionary = StatsCalculator.player_final_stats(bare_player)
	bare_player.free()
	gs.inventory = [ranged_item]
	_check(inv.equip_item("e2e_ranged_weapon"), "el flujo E2E equipa el arma")
	var geared_player := Player.new()
	var geared_stats: Dictionary = StatsCalculator.player_final_stats(geared_player)
	_check(float(geared_stats["damage"]) > float(bare_stats["damage"]), "el equipo aumenta el daño efectivo")
	_check(String(geared_stats["attack_type"]) == "ranged", "el arma equipada cambia el tipo de ataque")
	_check(float(geared_stats["attack_range"]) >= 800.0, "el arma equipada cambia el alcance")
	geared_player.refresh_combat_stats(false)
	var speed_after_first_refresh := geared_player.attack_speed
	geared_player.refresh_combat_stats(false)
	_check(is_equal_approx(speed_after_first_refresh, geared_player.attack_speed), "refrescar estadísticas no acumula velocidad de ataque")
	geared_player.free()

	var units: Dictionary = DataLoader.get_units_data()
	_check(String(units.get("archer", {}).get("required_technology", "")) == "archery", "Arquería es requisito real del arquero")
	_check(not rm.is_completed("archery"), "el arquero permanece bloqueado antes de investigar Arquería")
	gs.technologies["archery"] = true
	EffectProcessor.apply([{"type": "unlock_unit", "value": "archer"}])
	_check(gs.has_unlocked_content("units", "archer"), "Arquería registra el desbloqueo de la unidad")

func _start_battle() -> void:
	var gs := root.get_node("/root/GameState")
	gs.battle_speed = 2.0
	_gold_before_battle = int(gs.gold)
	_battle = (load(BATTLE_SCENE) as PackedScene).instantiate()
	root.add_child(_battle)
	var player: Player = _battle.get_node("World/Player")
	var base: BaseBuilding = _battle.get_node("World/Base")
	player.health = maxi(1, player.max_health / 2)
	base.health = maxi(1, base.max_health / 2)
	var player_before := player.health
	var base_before := base.health
	_battle._restore_between_waves()
	_check(player.health > player_before, "la regeneración de Fogata restaura vida del jugador")
	_check(base.health > base_before, "la regeneración de Fogata restaura vida de la base")

func _complete_research(rm: Node, technology_id: String) -> bool:
	if not rm.start_research(technology_id):
		return false
	var gs := root.get_node("/root/GameState")
	gs.current_research["started_at"] = int(Time.get_unix_time_from_system()) - 9999
	return rm.check_completion()

func _pass(message: String) -> void:
	print("[TEST] PASS: " + message)

func _check(condition: bool, message: String) -> void:
	if not condition:
		_failed = true
		printerr("[TEST] FAIL: " + message)

func _fail(message: String) -> bool:
	_failed = true
	printerr("[TEST] FAIL: " + message)
	quit(1)
	return true
