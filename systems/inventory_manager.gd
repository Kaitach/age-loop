extends Node

signal inventory_changed

const CAPACITY := 50
const EQUIPMENT_SLOTS := ["weapon", "helmet", "armor", "gloves", "boots", "amulet"]

func add_item(instance: Dictionary) -> String:
	if GameState.inventory.size() >= CAPACITY:
		GameState.pending_items.append(instance)
		inventory_changed.emit()
		SignalBus.inventory_changed.emit()
		SignalBus.save_requested.emit()
		return "pending_full"
	GameState.inventory.append(instance)
	inventory_changed.emit()
	SignalBus.inventory_changed.emit()
	SignalBus.save_requested.emit()
	return "stored"

func remove_item(item_id: String) -> void:
	for i in range(GameState.inventory.size()):
		if String(GameState.inventory[i].get("id", "")) == item_id:
			GameState.inventory.remove_at(i)
			_claim_pending_items()
			inventory_changed.emit()
			SignalBus.inventory_changed.emit()
			return

func find_item(item_id: String) -> Dictionary:
	for instance in GameState.inventory:
		if String(instance.get("id", "")) == item_id:
			return instance
	return {}

func find_pending_item(item_id: String) -> Dictionary:
	for instance in GameState.pending_items:
		if String(instance.get("id", "")) == item_id:
			return instance
	return {}

func claim_pending_items() -> int:
	var claimed := 0
	while not GameState.pending_items.is_empty() and GameState.inventory.size() < CAPACITY:
		GameState.inventory.append(GameState.pending_items.pop_front())
		claimed += 1
	if claimed > 0:
		inventory_changed.emit()
		SignalBus.inventory_changed.emit()
		SignalBus.save_requested.emit()
	return claimed

func sell_pending_item(item_id: String) -> int:
	for i in range(GameState.pending_items.size()):
		var instance: Dictionary = GameState.pending_items[i]
		if String(instance.get("id", "")) != item_id:
			continue
		var value := int(instance.get("sell_value", 0))
		GameState.pending_items.remove_at(i)
		Economy.add_gold(value)
		inventory_changed.emit()
		SignalBus.inventory_changed.emit()
		SignalBus.save_requested.emit()
		return value
	return 0

func equip_item(item_id: String) -> bool:
	var instance := find_item(item_id)
	if instance.is_empty():
		return false
	var slot := String(instance.get("slot", ""))
	if not EQUIPMENT_SLOTS.has(slot):
		return false
	for i in range(GameState.inventory.size()):
		if String(GameState.inventory[i].get("id", "")) == item_id:
			GameState.inventory.remove_at(i)
			break
	var previous = GameState.equipped_items.get(slot, null)
	if previous != null and not (previous is Dictionary and previous.is_empty()):
		GameState.inventory.append(previous)
	else:
		_claim_pending_items()
	GameState.equipped_items[slot] = instance
	inventory_changed.emit()
	SignalBus.inventory_changed.emit()
	SignalBus.equipment_changed.emit()
	SignalBus.save_requested.emit()
	return true

func unequip_item(slot: String) -> bool:
	if not EQUIPMENT_SLOTS.has(slot):
		return false
	var current = GameState.equipped_items.get(slot, null)
	if current == null:
		return false
	if GameState.inventory.size() >= CAPACITY:
		return false
	GameState.equipped_items[slot] = null
	GameState.inventory.append(current)
	inventory_changed.emit()
	SignalBus.inventory_changed.emit()
	SignalBus.equipment_changed.emit()
	SignalBus.save_requested.emit()
	return true

func sell_item(item_id: String) -> int:
	var instance := find_item(item_id)
	if instance.is_empty():
		return 0
	var value := int(instance.get("sell_value", 0))
	remove_item(item_id)
	Economy.add_gold(value)
	SignalBus.save_requested.emit()
	return value

func sell_all_by_rarity(rarity_id: String) -> int:
	var total := 0
	var kept: Array = []
	for instance in GameState.inventory:
		if String(instance.get("rarity", "")) == rarity_id:
			total += int(instance.get("sell_value", 0))
		else:
			kept.append(instance)
	if total > 0:
		GameState.inventory = kept
		_claim_pending_items()
		Economy.add_gold(total)
		inventory_changed.emit()
		SignalBus.save_requested.emit()
	return total

func _claim_pending_items() -> void:
	claim_pending_items()
