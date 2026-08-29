extends SceneTree

const BATTLE_SCENE := "res://scenes/battle/battle.tscn"

var _battle: Node
var _frames := 0
var _started := false
var _wave_before := 0
var _player_health_before := 0
var _base_health_before := 0
var _player_position_before := Vector2.ZERO
var _failed := false

func _process(_delta: float) -> bool:
	if not _started:
		if root.get_node_or_null("/root/GameState") == null:
			return false
		_started = true
		_start_check()
		return false
	_frames += 1
	if _frames < 8:
		return false
	if _frames == 8:
		_capture_state_and_start_transition()
		return false
	if _frames < 500:
		return false
	_validate_transition()
	return true

func _start_check() -> void:
	var gs := root.get_node("/root/GameState")
	gs.settings["music_enabled"] = false
	gs.settings["sfx_enabled"] = false
	root.get_node("/root/AudioManager").refresh_from_state()
	gs.current_era = "prehistoric"
	gs.world = 1
	gs.wave = 2
	gs.battle_speed = 0.0
	gs.equipped_items = {
		"weapon": {
			"id": "test_wooden_stick",
			"name": "Palo de madera",
			"slot": "weapon",
			"era": "prehistoric",
			"attack_type": "melee",
			"stats": {"damage": 10, "attack_range": 0}
		}
	}
	_battle = load(BATTLE_SCENE).instantiate()
	root.add_child(_battle)

func _capture_state_and_start_transition() -> void:
	var gs := root.get_node("/root/GameState")
	_wave_before = int(gs.wave)
	_player_health_before = int(_battle.get_node("World/Player").health)
	_base_health_before = int(_battle.get_node("World/Base").health)
	_player_position_before = _battle.get_node("World/Player").global_position
	_check(String(_battle.get("_player_era")) == "prehistoric", "el jugador comienza en su era investigada")
	_check(String(_battle.get("_enemy_era")) == "bronze", "la oleada 1-2 resuelve enemigos de bronce")
	_check(get_nodes_in_group("allies").is_empty(), "no se crean aliados de unidades")
	_check(get_nodes_in_group("pets").size() == 1, "se crea una sola mascota")
	var initial_player: Texture2D = _battle.get_node("World/Player/Sprite").texture
	_check(initial_player != null and "/assets/eras/prehistoric/player.png" in initial_player.resource_path, "el jugador conserva sprite prehistorico")
	var initial_base: Texture2D = _battle.get_node("World/Base/BaseSprite").texture
	_check(initial_base != null and "/assets/eras/prehistoric/base.png" in initial_base.resource_path, "la ciudad conserva sprite prehistorico")
	var initial_background: Texture2D = _battle.get_node("BattleArt").texture
	_check(initial_background != null and "/assets/eras/bronze/background.png" in initial_background.resource_path, "el escenario usa la era del enemigo")
	var enemies: Array[Node] = get_nodes_in_group("enemies")
	if not enemies.is_empty():
		var enemy_texture: Texture2D = enemies[0].get_node("Sprite").texture
		_check(enemy_texture != null and "/assets/eras/bronze/enemies/normal.png" in enemy_texture.resource_path, "el enemigo usa sprite de bronce")
		_check(enemies[0].has_status("guard"), "la mecanica de bronce se aplica al enemigo")
	gs.current_era = "bronze"
	_battle.call("_on_era_changed", "bronze")
	_check(bool(_battle.get("_transition_active")), "la transicion cinematica se activa")

func _validate_transition() -> void:
	var gs := root.get_node("/root/GameState")
	_check(not bool(_battle.get("_transition_active")), "la transicion cinematica termina")
	_check(String(_battle.get("_player_era")) == "bronze", "la era investigada del jugador cambia")
	_check(String(_battle.get("_enemy_era")) == "bronze", "la era del enemigo no depende del jugador")
	_check(int(gs.wave) == _wave_before, "la oleada se conserva durante el cambio")
	_check(int(_battle.get_node("World/Player").health) == _player_health_before, "la vida del jugador se conserva")
	_check(int(_battle.get_node("World/Base").health) == _base_health_before, "la vida de la base se conserva")
	_check(_battle.get_node("World/Player").global_position == _player_position_before, "la posicion del jugador se conserva")
	var background: Texture2D = _battle.get_node("BattleArt").texture
	_check(background != null and "/assets/eras/bronze/background.png" in background.resource_path, "el fondo sigue la era enemiga")
	var player_texture: Texture2D = _battle.get_node("World/Player/Sprite").texture
	_check(player_texture != null and "/assets/eras/bronze/player.png" in player_texture.resource_path, "el jugador cambia de apariencia al investigar")
	var base_texture: Texture2D = _battle.get_node("World/Base/BaseSprite").texture
	_check(base_texture != null and "/assets/eras/bronze/base.png" in base_texture.resource_path, "la ciudad cambia con la era investigada")
	_check(get_nodes_in_group("allies").is_empty(), "la batalla sigue sin escuadron aliado")
	_check(get_nodes_in_group("pets").size() == 1, "la batalla conserva una unica mascota")
	var enemies: Array[Node] = get_nodes_in_group("enemies")
	if not enemies.is_empty():
		_check(enemies[0].has_status("guard"), "el enemigo conserva la mecanica de su propia era")
		var enemy_texture: Texture2D = enemies[0].get_node("Sprite").texture
		_check(enemy_texture != null and "/assets/eras/bronze/enemies/normal.png" in enemy_texture.resource_path, "el enemigo no cambia por la era del jugador")
	# El arma prehistorica sigue funcionando aunque el jugador ya haya avanzado.
	gs.current_era = "cybernetic"
	_battle.get_node("World/Player").set_era_visual("cybernetic")
	_battle.get_node("World/Player").refresh_combat_stats()
	var stats := StatsCalculator.player_final_stats(_battle.get_node("World/Player"))
	_check(String(stats["attack_type"]) == "melee" and float(stats["damage"]) >= 24.0, "un arma vieja sigue siendo util en una era futura")
	if _failed:
		gs_reset()
		_battle.queue_free()
		quit(1)
		return
	_pass("eras de jugador, enemigos, mascota y equipo quedan desacopladas")
	gs_reset()
	_battle.queue_free()
	quit(0)

func gs_reset() -> void:
	var gs := root.get_node_or_null("/root/GameState")
	if gs != null:
		gs.battle_speed = 1.0
		gs.current_era = "prehistoric"
		gs.equipped_items = {}

func _check(condition: bool, message: String) -> void:
	if not condition:
		printerr("[TEST] FAIL: " + message)
		_failed = true

func _pass(message: String) -> void:
	print("[TEST] PASS: " + message)
