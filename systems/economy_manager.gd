extends Node

func add_gold(amount: int) -> void:
	GameState.gold += maxi(amount, 0)
	SignalBus.currency_changed.emit()

func add_science(amount: int) -> void:
	GameState.science += maxi(amount, 0)
	SignalBus.currency_changed.emit()

func add_materials(amount: int) -> void:
	GameState.materials += maxi(amount, 0)
	SignalBus.currency_changed.emit()

func add_crystals(amount: int) -> void:
	GameState.crystals += maxi(amount, 0)
	SignalBus.currency_changed.emit()

func can_afford(costs: Dictionary) -> bool:
	for currency in costs.keys():
		if GameState.get(currency) < int(costs[currency]):
			return false
	return true

func spend(costs: Dictionary) -> bool:
	if not can_afford(costs):
		return false
	for currency in costs.keys():
		GameState.set(currency, GameState.get(currency) - int(costs[currency]))
	SignalBus.currency_changed.emit()
	return true
