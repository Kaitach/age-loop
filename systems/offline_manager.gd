extends Node

signal offline_rewards_claimed(rewards: Dictionary)

func get_max_offline_seconds() -> int:
	return int(DataLoader.get_balance().get("max_offline_hours", 8)) * 3600

func get_offline_rewards() -> Dictionary:
	var now := int(Time.get_unix_time_from_system())
	var last := int(GameState.last_played_at)
	if last == 0:
		return { "elapsed": 0, "gold": 0, "materials": 0, "science": 0 }
	var elapsed := clampi(now - last, 0, get_max_offline_seconds())
	if elapsed < 60:
		return { "elapsed": elapsed, "gold": 0, "materials": 0, "science": 0 }
	var income := BuildingManager.calculate_passive_income()
	return {
		"elapsed": elapsed,
		"gold": int(floor(float(income.get("gold_per_sec", 0.0)) * elapsed)),
		"materials": int(floor(float(income.get("materials_per_sec", 0.0)) * elapsed)),
		"science": 0,
	}

func claim(rewards: Dictionary) -> void:
	if int(rewards.get("gold", 0)) > 0:
		Economy.add_gold(int(rewards["gold"]))
	if int(rewards.get("materials", 0)) > 0:
		Economy.add_materials(int(rewards["materials"]))
	if int(rewards.get("science", 0)) > 0:
		Economy.add_science(int(rewards["science"]))
	GameState.last_played_at = int(Time.get_unix_time_from_system())
	SignalBus.save_requested.emit()
	offline_rewards_claimed.emit(rewards)

func format_elapsed(seconds: int) -> String:
	var h := seconds / 3600
	var m := (seconds % 3600) / 60
	if h > 0:
		return "%dh %dm" % [h, m]
	return "%dm" % m
