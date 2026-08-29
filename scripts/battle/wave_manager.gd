class_name WaveManager
extends Node

signal spawn_enemy(enemy_id: String, position: Vector2)

const ENEMY_SPAWN_Y := -80.0
const SPAWN_X_MIN := 140.0
const SPAWN_X_MAX := 940.0
const FIRST_SPAWN_DELAY := 0.6
const IN_GROUP_DELAY := 0.9
const BETWEEN_GROUPS_DELAY := 1.2
const BOSS_EXTRA_DELAY := 2.0

var current_world: int = 1
var current_wave: int = 1

var _queue: Array = []
var _elapsed: float = 0.0
var _running: bool = false

static func global_wave_number(world: int, wave: int) -> int:
	return (world - 1) * 10 + wave

static func hp_scale_for(world: int, wave: int) -> float:
	var growth := float(DataLoader.get_balance().get("enemy_hp_growth", 1.12))
	return pow(growth, global_wave_number(world, wave) - 1)

static func dmg_scale_for(world: int, wave: int) -> float:
	var growth := float(DataLoader.get_balance().get("enemy_damage_growth", 1.09))
	return pow(growth, global_wave_number(world, wave) - 1)

static func reward_scale_for(world: int, wave: int, key: String, fallback: float) -> float:
	var balance := DataLoader.get_balance()
	var growth := float(balance.get(key, fallback))
	return pow(growth, global_wave_number(world, wave) - 1)

static func get_enemy_data(enemy_id: String) -> Dictionary:
	return DataLoader.get_enemies_data().get(enemy_id, {})

static func build_spawn_queue(world: int, wave: int) -> Array:
	var queue: Array = []
	var t := FIRST_SPAWN_DELAY
	var first_group := true
	for group in DataLoader.get_wave_def(world, wave).get("groups", []):
		if not first_group:
			t += BETWEEN_GROUPS_DELAY
		first_group = false
		for i in range(int(group.get("count", 0))):
			if i > 0:
				t += IN_GROUP_DELAY
			queue.append({ "id": String(group.get("enemy", "")), "time": t })
	var boss_id := String(DataLoader.get_wave_def(world, wave).get("boss", ""))
	if boss_id != "":
		t += BOSS_EXTRA_DELAY
		queue.append({ "id": boss_id, "time": t })
	return queue

static func calculate_rewards(world: int, wave: int) -> Dictionary:
	var totals := { "gold": 0, "science": 0, "materials": 0 }
	var gold_mult := reward_scale_for(world, wave, "gold_growth", 1.10)
	var sci_mult := reward_scale_for(world, wave, "science_growth", 1.07)
	var mat_mult := reward_scale_for(world, wave, "materials_growth", 1.08)
	var gs := _game_state()
	gold_mult *= 1.0 + gs.get_effect_modifier("gold_reward")
	sci_mult *= 1.0 + gs.get_effect_modifier("science_reward")
	mat_mult *= 1.0 + gs.get_effect_modifier("materials_reward")
	var mults := { "gold": gold_mult, "science": sci_mult, "materials": mat_mult }
	var wave_def := DataLoader.get_wave_def(world, wave)
	for group in wave_def.get("groups", []):
		var data := get_enemy_data(String(group.get("enemy", "")))
		var rewards: Dictionary = data.get("rewards", {})
		for key in totals.keys():
			totals[key] += int(round(float(rewards.get(key, 0)) * float(group.get("count", 0)) * mults[key]))
	var boss_id := String(wave_def.get("boss", ""))
	if boss_id != "":
		var boss_rewards: Dictionary = get_enemy_data(boss_id).get("rewards", {})
		for key in totals.keys():
			totals[key] += int(round(float(boss_rewards.get(key, 0)) * mults[key]))
	return totals

static func recommended_power(world: int, wave: int) -> int:
	var balance := DataLoader.get_balance()
	var base := float(balance.get("recommended_power_base", 180.0))
	var growth := float(balance.get("recommended_power_growth", 1.14))
	return int(round(base * pow(growth, global_wave_number(world, wave) - 1)))

static func _game_state() -> Node:
	return (Engine.get_main_loop() as SceneTree).root.get_node("/root/GameState")

func start(world: int, wave: int) -> void:
	current_world = world
	current_wave = wave
	_queue = build_spawn_queue(world, wave)
	_elapsed = 0.0
	_running = true

func tick(delta: float) -> void:
	if not _running or _queue.is_empty():
		return
	_elapsed += delta
	while not _queue.is_empty() and _elapsed >= float(_queue[0]["time"]):
		var entry: Dictionary = _queue.pop_front()
		spawn_enemy.emit(String(entry["id"]), _random_spawn_position())

func finished_spawning() -> bool:
	return _running and _queue.is_empty()

func _random_spawn_position() -> Vector2:
	return Vector2(GameRng.randf_range(SPAWN_X_MIN, SPAWN_X_MAX), ENEMY_SPAWN_Y)
