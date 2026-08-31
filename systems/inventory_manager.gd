extends Node

signal inventory_changed

const CAPACITY := 50
const EQUIPMENT_SLOTS := ["weapon", "helmet", "armor", "gloves", "boots", "amulet"]
const RARITY_ORDER := {"common": 0, "uncommon": 1, "rare": 2, "epic": 3, "legendary": 4}

# ── core storage ──────────────────────────────────────────────────────────
func add_item(instance: Dictionary) -> String:
	if not instance.has("favorite"):
		instance["favorite"] = false
	if not instance.has("trash"):
		instance["trash"] = false
	if not instance.has("acquired_at"):
		instance["acquired_at"] = int(Time.get_unix_time_from_system())
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
	var check := can_sell_item(instance)
	if not check["allowed"]:
		return 0
	var value := int(instance.get("sell_value", 0))
	remove_item(item_id)
	Economy.add_gold(value)
	SignalBus.save_requested.emit()
	return value

func sell_all_by_rarity(rarity_id: String) -> int:
	var filter := {"rarities": [rarity_id], "only_unequipped": true}
	var preview := preview_sell(filter)
	if preview["count"] == 0:
		return 0
	return sell_filtered(filter, true)

# ── favorites / trash ─────────────────────────────────────────────────────
func is_favorite(item: Dictionary) -> bool:
	return bool(item.get("favorite", false))

func is_trash(item: Dictionary) -> bool:
	return bool(item.get("trash", false))

func set_favorite(item_id: String, value: bool) -> bool:
	var it := find_item(item_id)
	if it.is_empty():
		it = find_pending_item(item_id)
		if it.is_empty():
			return false
	it["favorite"] = value
	if value:
		it["trash"] = false
	inventory_changed.emit()
	SignalBus.inventory_changed.emit()
	SignalBus.save_requested.emit()
	return true

func toggle_favorite(item_id: String) -> bool:
	var it := find_item(item_id)
	if it.is_empty():
		it = find_pending_item(item_id)
		if it.is_empty():
			return false
	return set_favorite(item_id, not bool(it.get("favorite", false)))

func set_trash(item_id: String, value: bool) -> bool:
	var it := find_item(item_id)
	if it.is_empty():
		it = find_pending_item(item_id)
		if it.is_empty():
			return false
	if bool(it.get("favorite", false)) and value:
		return false
	it["trash"] = value
	inventory_changed.emit()
	SignalBus.inventory_changed.emit()
	SignalBus.save_requested.emit()
	return true

func toggle_trash(item_id: String) -> bool:
	var it := find_item(item_id)
	if it.is_empty():
		it = find_pending_item(item_id)
		if it.is_empty():
			return false
	return set_trash(item_id, not bool(it.get("trash", false)))

# ── capacity / info ───────────────────────────────────────────────────────
func get_capacity_info() -> Dictionary:
	var used := GameState.inventory.size()
	var total := CAPACITY
	return {"used": used, "total": total, "free": total - used, "pct": float(used) / float(total) if total > 0 else 0.0, "pending": GameState.pending_items.size()}

func get_equipped_count() -> int:
	var c := 0
	for slot in EQUIPMENT_SLOTS:
		var v = GameState.equipped_items.get(slot, null)
		if v != null and v is Dictionary and not v.is_empty():
			c += 1
	return c

# ── power / comparison ────────────────────────────────────────────────────
func get_item_power(item: Dictionary) -> float:
	return LootManager.item_power(item)

func is_better_than_equipped(item: Dictionary) -> bool:
	var slot := String(item.get("slot", ""))
	var equipped = GameState.equipped_items.get(slot, null)
	if equipped == null or not (equipped is Dictionary) or equipped.is_empty():
		return true
	return get_item_power(item) > get_item_power(equipped)

func get_upgrade_candidates(slot: String) -> Array:
	var equipped = GameState.equipped_items.get(slot, null)
	var base_power := -1.0
	if equipped != null and equipped is Dictionary and not equipped.is_empty():
		base_power = get_item_power(equipped)
	var candidates: Array = []
	for it in GameState.inventory:
		if String(it.get("slot", "")) != slot:
			continue
		if get_item_power(it) > base_power:
			candidates.append(it)
	candidates.sort_custom(func(a, b): return get_item_power(a) > get_item_power(b))
	return candidates

func recommend_for_slot(slot: String) -> Dictionary:
	var cands := get_upgrade_candidates(slot)
	if cands.is_empty():
		return {}
	return cands[0]

# ── filtering / sorting ───────────────────────────────────────────────────
func get_filtered_items(filters: Dictionary) -> Array:
	var result: Array = []
	var rarities: Array = filters.get("rarities", [])
	var slots: Array = filters.get("slots", [])
	var only_unequipped: bool = bool(filters.get("only_unequipped", false))
	var only_trash: bool = bool(filters.get("only_trash", false))
	var only_favorite: bool = bool(filters.get("only_favorite", false))
	var only_better: bool = bool(filters.get("only_better", false))
	var min_level: int = int(filters.get("min_level", -1))
	var max_level: int = int(filters.get("max_level", 999))
	var query_trash_any: bool = filters.has("trash")
	for it in GameState.inventory:
		if not rarities.is_empty() and not rarities.has(String(it.get("rarity", ""))):
			continue
		if not slots.is_empty() and not slots.has(String(it.get("slot", ""))):
			continue
		if only_trash and not bool(it.get("trash", false)):
			continue
		if only_favorite and not bool(it.get("favorite", false)):
			continue
		if only_better and not is_better_than_equipped(it):
			continue
		var lvl := int(it.get("level", 0))
		if lvl < min_level or lvl > max_level:
			continue
		if filters.has("trash") and bool(filters["trash"]) != bool(it.get("trash", false)) and not only_trash:
			# allow explicit trash filter
			if bool(filters["trash"]) != bool(it.get("trash", false)):
				continue
		result.append(it)
	return result

func sort_items(items: Array, sort_key: String) -> Array:
	var sorted := items.duplicate()
	match sort_key:
		"level":
			sorted.sort_custom(func(a,b): return int(a.get("level",0)) > int(b.get("level",0)))
		"rarity":
			sorted.sort_custom(func(a,b): return int(RARITY_ORDER.get(String(a.get("rarity","common")),0)) > int(RARITY_ORDER.get(String(b.get("rarity","common")),0)))
		"power":
			sorted.sort_custom(func(a,b): return get_item_power(a) > get_item_power(b))
		"damage":
			sorted.sort_custom(func(a,b): return float(a.get("stats",{}).get("damage",0)) > float(b.get("stats",{}).get("damage",0)))
		"health":
			sorted.sort_custom(func(a,b): return float(a.get("stats",{}).get("max_health",0)) > float(b.get("stats",{}).get("max_health",0)))
		"value":
			sorted.sort_custom(func(a,b): return int(a.get("sell_value",0)) > int(b.get("sell_value",0)))
		"recent":
			sorted.sort_custom(func(a,b): return int(a.get("acquired_at",0)) > int(b.get("acquired_at",0)))
		_:
			sorted.sort_custom(func(a,b): return get_item_power(a) > get_item_power(b))
	return sorted

# ── protection ────────────────────────────────────────────────────────────
func can_sell_item(item: Dictionary) -> Dictionary:
	var slot := String(item.get("slot", ""))
	var rarity := String(item.get("rarity", "common"))
	if bool(item.get("favorite", false)):
		return {"allowed": false, "reason": "Favorito protegido", "level": "blocked"}
	if is_equipped(item):
		return {"allowed": false, "reason": "Está equipado", "level": "blocked"}
	if rarity == "legendary" or rarity == "epic":
		return {"allowed": true, "reason": "Requiere confirmación épica/legendaria", "level": "epic_confirm"}
	if _is_last_of_category(item):
		return {"allowed": true, "reason": "Último de tipo %s" % slot, "level": "warning"}
	return {"allowed": true, "reason": "", "level": "ok"}

func is_equipped(item: Dictionary) -> bool:
	var id := String(item.get("id",""))
	for slot in EQUIPMENT_SLOTS:
		var eq = GameState.equipped_items.get(slot, null)
		if eq is Dictionary and String(eq.get("id","")) == id:
			return true
	return false

func _is_last_of_category(item: Dictionary) -> bool:
	var slot := String(item.get("slot",""))
	var count := 0
	for it in GameState.inventory:
		if String(it.get("slot","")) == slot:
			count += 1
	var eq = GameState.equipped_items.get(slot, null)
	if eq is Dictionary and not eq.is_empty():
		count += 1
	return count <= 1

# ── bulk sell ─────────────────────────────────────────────────────────────
func preview_sell(filters: Dictionary) -> Dictionary:
	var items := get_filtered_items(filters)
	var blocked := 0
	var sellable: Array = []
	var gold := 0
	for it in items:
		var check := can_sell_item(it)
		if not check["allowed"]:
			if check["level"] == "blocked":
				blocked += 1
				continue
		# epic/legendary still sellable but flagged
		sellable.append(it)
		gold += int(it.get("sell_value",0))
	return {"count": sellable.size(), "gold": gold, "items": sellable, "blocked": blocked, "total_matched": items.size()}

func sell_filtered(filters: Dictionary, force: bool = false) -> int:
	var preview := preview_sell(filters)
	var to_sell: Array = preview["items"]
	if to_sell.is_empty():
		return 0
	# if any epic/legendary and not force, caller should confirm
	if not force:
		for it in to_sell:
			var r := String(it.get("rarity",""))
			if r == "epic" or r == "legendary":
				return 0
	var ids := {}
	for it in to_sell:
		ids[String(it.get("id",""))] = true
	var kept: Array = []
	var gold := 0
	for it in GameState.inventory:
		if ids.has(String(it.get("id",""))):
			gold += int(it.get("sell_value",0))
		else:
			kept.append(it)
	GameState.inventory = kept
	_claim_pending_items()
	if gold > 0:
		Economy.add_gold(gold)
	inventory_changed.emit()
	SignalBus.inventory_changed.emit()
	SignalBus.save_requested.emit()
	return gold

func sell_trash_marked() -> Dictionary:
	var marked: Array = []
	for it in GameState.inventory:
		if bool(it.get("trash", false)):
			marked.append(it)
	if marked.is_empty():
		return {"count":0,"gold":0}
	var filter := {"only_trash": true}
	return {"count": preview_sell(filter)["count"], "gold": sell_filtered(filter, true)}

# ── duplicates / smart cleanup ────────────────────────────────────────────
func get_duplicates() -> Dictionary:
	var groups := {}
	for it in GameState.inventory:
		var key := String(it.get("template_id",""))
		if not groups.has(key):
			groups[key] = []
		groups[key].append(it)
	var dups := {}
	for key in groups.keys():
		if groups[key].size() > 1:
			var arr: Array = groups[key]
			arr.sort_custom(func(a,b): return get_item_power(a) > get_item_power(b))
			dups[key] = arr
	return dups

func get_inferior_items() -> Array:
	var result: Array = []
	for slot in EQUIPMENT_SLOTS:
		var equipped = GameState.equipped_items.get(slot, null)
		if equipped == null or not (equipped is Dictionary) or equipped.is_empty():
			continue
		var base_power := get_item_power(equipped)
		for it in GameState.inventory:
			if String(it.get("slot","")) != slot:
				continue
			if bool(it.get("favorite", false)):
				continue
			if get_item_power(it) < base_power:
				result.append(it)
	return result

func get_smart_cleanup_preview() -> Dictionary:
	var commons: Array = []
	var inferior: Array = get_inferior_items()
	var dups_groups := get_duplicates()
	var dup_inferior: Array = []
	for key in dups_groups.keys():
		var arr: Array = dups_groups[key]
		for i in range(1, arr.size()):
			if not bool(arr[i].get("favorite", false)):
				dup_inferior.append(arr[i])
	var trash_marked: Array = []
	for it in GameState.inventory:
		if bool(it.get("trash", false)):
			trash_marked.append(it)
	for it in GameState.inventory:
		if String(it.get("rarity","common")) == "common" and not bool(it.get("favorite",false)) and not bool(it.get("trash",false)):
			# common not used and not better
			if not is_better_than_equipped(it):
				commons.append(it)
	var all_candidates := {}
	for arr in [commons, inferior, dup_inferior, trash_marked]:
		for it in arr:
			all_candidates[String(it.get("id",""))] = it
	var total_gold := 0
	for it in all_candidates.values():
		total_gold += int(it.get("sell_value",0))
	return {"commons": commons, "inferior": inferior, "duplicates": dup_inferior, "trash": trash_marked, "total_unique": all_candidates.size(), "gold": total_gold, "all": all_candidates.values()}

# ── quick equip / presets ─────────────────────────────────────────────────
func quick_equip_best_preview() -> Dictionary:
	var dummy := Player.new()
	dummy.base_damage = 14
	dummy.base_max_health = 100
	dummy.base_max_health = 100
	dummy.attack_speed = 1.2
	var before: Dictionary = StatsCalculator.player_final_stats(dummy)
	dummy.free()
	# find best per slot
	var best_per_slot := {}
	for slot in EQUIPMENT_SLOTS:
		var best := recommend_for_slot(slot)
		if not best.is_empty():
			best_per_slot[slot] = best
	# simulate after
	var bak := GameState.equipped_items.duplicate(true)
	for slot in best_per_slot.keys():
		GameState.equipped_items[slot] = best_per_slot[slot]
	var d2 := Player.new()
	d2.base_damage = 14
	d2.base_max_health = 100
	d2.attack_speed = 1.2
	var after: Dictionary = StatsCalculator.player_final_stats(d2)
	d2.free()
	for slot in bak.keys():
		GameState.equipped_items[slot] = bak[slot]
	return {"before": before, "after": after, "best": best_per_slot, "power_before": StatsCalculator.combat_power(before), "power_after": StatsCalculator.combat_power(after)}

func quick_equip_best_apply() -> bool:
	var preview := quick_equip_best_preview()
	var best: Dictionary = preview["best"]
	if best.is_empty():
		return false
	for slot in best.keys():
		var it: Dictionary = best[slot]
		equip_item(String(it.get("id","")))
	return true

func save_preset(preset_id: String) -> void:
	GameState.equipment_presets[preset_id] = GameState.equipped_items.duplicate(true)
	SignalBus.save_requested.emit()

func load_preset(preset_id: String) -> bool:
	var preset = GameState.equipment_presets.get(preset_id, null)
	if preset == null or not (preset is Dictionary):
		return false
	for slot in EQUIPMENT_SLOTS:
		var wanted = preset.get(slot, null)
		if wanted == null or not (wanted is Dictionary) or wanted.is_empty():
			continue
		var id := String(wanted.get("id",""))
		# find in inventory or already equipped
		var found := find_item(id)
		if found.is_empty():
			# maybe already equipped elsewhere, skip
			continue
		equip_item(id)
	return true

func _claim_pending_items() -> void:
	claim_pending_items()
