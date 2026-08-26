extends Node

signal inventory_changed

const CAPACITY := 50
const EQUIPMENT_SLOTS := ["weapon", "helmet", "armor", "gloves", "boots", "amulet"]

func add_item(instance: Dictionary) -> String:
	if GameState.inventory.size() >= CAPACITY:
		Economy.add_gold(int(instance.get("sell_value", 0)))
		inventory_changed.emit()
		return "sold_full"
	GameState.inventory.append(instance)
	inventory_changed.emit()
	return "stored"

func remove_item(item_id: String) -> void:
	for i in range(GameState.inventory.size()):
		if String(GameState.inventory[i].get("id", "")) == item_id:
			GameState.inventory.remove_at(i)
			inventory_changed.emit()
			return

func find_item(item_id: String) -> Dictionary:
	for instance in GameState.inventory:
		if String(instance.get("id", "")) == item_id:
			return instance
	return {}

func equip_item(item_id: String) -> bool:
	var instance := find_item(item_id)
	if instance.is_empty():
		return false
	var slot := String(instance.get("slot", ""))
	if not EQUIPMENT_SLOTS.has(slot):
		return false
	remove_item(item_id)
	var previous = GameState.equipped_items.get(slot, null)
	if previous != null and not (previous is Dictionary and previous.is_empty()):
		GameState.inventory.append(previous)
	GameState.equipped_items[slot] = instance
	inventory_changed.emit()
	SignalBus.equipment_changed.emit()
	SignalBus.save_requested.emit()
	return true

func unequip_item(slot: String) -> bool:
	if not EQUIPMENT_SLOTS.has(slot):
		return false
	var current = GameState.equipped_items.get(slot, null)
	if current == null:
		return false
	GameState.equipped_items[slot] = null
	GameState.inventory.append(current)
	inventory_changed.emit()
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
		Economy.add_gold(total)
		inventory_changed.emit()
		SignalBus.save_requested.emit()
	return total
