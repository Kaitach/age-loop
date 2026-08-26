extends SceneTree

func _initialize() -> void:
	print("[TEST] Test de loot iniciando...")

func _process(_delta: float) -> bool:
	_run_checks()
	quit(0)
	return true

func _run_checks() -> void:
	var gs := root.get_node("/root/GameState")
	var inv := root.get_node("/root/InventoryManager")
	var loot := root.get_node("/root/LootManager")
	var eco := root.get_node("/root/Economy")

	gs.gold = 0
	gs.inventory = []
	gs.equipped_items = {}
	gs.upgrades = {}

	var counts := {}
	var samples := 3000
	for i in range(samples):
		var rarity: String = loot.roll_rarity()
		counts[rarity] = int(counts.get(rarity, 0)) + 1
	_check(int(counts.get("common", 0)) > samples * 0.5, "common es la rareza mas frecuente")
	_check(int(counts.get("legendary", 0)) >= 1, "legendary aparece en la distribucion")

	var templates: Dictionary = DataLoader.load_json("items/items.json")["templates"]
	for i in range(200):
		var drop: Dictionary = loot.roll_drop(1.0, 1, 4, false)
		_check(not drop.is_empty(), "con chance 1.0 siempre hay drop")
		_check(templates.has(String(drop["template_id"])), "template del drop existe")
		_check(inv.EQUIPMENT_SLOTS.has(String(drop["slot"])), "slot del drop valido")
		_check(int(drop["level"]) >= 2 and int(drop["level"]) <= 6, "nivel dentro de rango gw±2 (obtuve %d)" % int(drop["level"]))
		var expected_mods := int(DataLoader.load_json("rarities/rarities.json")[String(drop["rarity"])]["modifiers"])
		_check((drop["modifiers"] as Array).size() == expected_mods, "cantidad de modificadores segun rareza")
		for stat_value in (drop["stats"] as Dictionary).values():
			_check(float(stat_value) > 0.0, "stats base positivos")

	var boss_drops := 0
	for i in range(10):
		if not loot.roll_drop(1.0, 1, 10, true).is_empty():
			boss_drops += 1
	_check(boss_drops == 10, "boss con loot_chance 1.0 siempre dropea")
	var boss_drop: Dictionary = loot.roll_drop(1.0, 1, 10, true)
	_check(int(boss_drop["level"]) >= 10, "nivel de drop de boss nunca baja del gw")

	var fake: Dictionary = {
		"id": "test_1", "template_id": "stone_club", "name": "Garrote test",
		"slot": "weapon", "level": 5, "rarity": "rare",
		"stats": { "damage": 30 }, "modifiers": [{ "stat": "critical_chance", "value": 0.02 }],
		"sell_value": 23,
	}
	gs.inventory = [fake]
	_check(inv.equip_item("test_1"), "equip_item funciona")
	_check(gs.equipped_items["weapon"]["id"] == "test_1", "item queda equipado en su slot")

	var player := Player.new()
	player.base_damage = 14
	player.base_max_health = 100
	player.attack_speed = 1.2
	var final_stats: Dictionary = StatsCalculator.player_final_stats(player)
	_check(float(final_stats["damage"]) == 44.0, "daño final suma base + item (obtuve %s)" % str(final_stats["damage"]))
	_check(absf(float(final_stats["critical_chance"]) - 0.07) < 0.0001, "critico base + modificador del item")
	player.free()

	var gold_before: int = int(gs.gold)
	_check(inv.sell_item("inexistente") == 0, "vender id inexistente no da oro")
	_check(inv.equip_item("inexistente") == false, "equipar id inexistente falla sin romper")

	_check(inv.unequip_item("weapon"), "unequip devuelve el item al inventario")
	_check(gs.equipped_items["weapon"] == null and gs.inventory.size() == 1, "slot queda vacio y item en inventario")
	_check(int(inv.sell_item("test_1")) == 23, "venta paga el valor correcto")
	_check(int(gs.gold) == gold_before + 23, "oro incrementa al vender")

	gs.inventory = []
	for i in range(inv.CAPACITY):
		inv.add_item({ "id": "filler_%d" % i, "sell_value": 1, "rarity": "common" })
	var overflow: String = inv.add_item({ "id": "extra", "sell_value": 9, "rarity": "rare" })
	_check(overflow == "sold_full", "inventario lleno auto-vende y avisa estado")
	_check(gs.inventory.size() == inv.CAPACITY, "capacidad respetada")
	_check(int(gs.gold) == gold_before + 23 + 9, "el item vendido por overflow pago oro")

	gs.inventory = []
	print("[TEST] PASS: todas las verificaciones de loot ok")

func _check(cond: bool, msg: String) -> void:
	if not cond:
		printerr("[TEST] FAIL: " + msg)
		quit(1)
