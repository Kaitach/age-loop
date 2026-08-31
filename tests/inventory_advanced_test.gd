extends SceneTree

func _initialize() -> void:
	print("[TEST] Inventory avanzado iniciando...")

func _process(_delta: float) -> bool:
	_run()
	quit(0)
	return true

func _run() -> void:
	var gs := root.get_node("/root/GameState") as Node
	var inv = root.get_node("/root/InventoryManager")
	var loot = root.get_node("/root/LootManager")
	gs.inventory = []
	gs.pending_items = []
	gs.equipped_items = {}
	gs.gold = 0
	# crear items variados
	for i in range(5):
		gs.inventory.append({"id":"c%d"%i,"template_id":"stone_club","name":"Garrote","slot":"weapon","level":2,"rarity":"common","stats":{"damage":10},"modifiers":[],"sell_value":10,"favorite":false,"trash":false,"acquired_at":100+i})
	gs.inventory.append({"id":"r1","template_id":"iron_sword","name":"Espada rara","slot":"weapon","level":8,"rarity":"rare","stats":{"damage":50},"modifiers":[],"sell_value":80,"favorite":false,"trash":false,"acquired_at":200})
	gs.inventory.append({"id":"fav1","template_id":"iron_sword","name":"Espada fav","slot":"weapon","level":10,"rarity":"epic","stats":{"damage":70},"modifiers":[],"sell_value":150,"favorite":true,"trash":false,"acquired_at":300})
	gs.inventory.append({"id":"trash1","template_id":"hide_armor","name":"Armadura basura","slot":"armor","level":1,"rarity":"common","stats":{"max_health":20},"modifiers":[],"sell_value":8,"favorite":false,"trash":true,"acquired_at":50})
	# favoritos no se venden con comunes
	var preview: Dictionary = inv.preview_sell({"rarities":["common"]})
	_check(preview["count"] == 6, "preview comunes no incluye favorito (esperaba 6, obtuvo %d)" % preview["count"])
	# vender comunes debe respetar favorito
	var gold_before: int = int(gs.gold)
	var sold: int = int(inv.sell_filtered({"rarities":["common"]}, true))
	_check(sold == 5*10 + 8, "venta comunes suma correcta")
	_check(gs.inventory.size() == 2, "quedan 2 items (rare+epic fav)")
	# trash toggle
	_check(inv.is_trash(inv.find_item("r1")) == false, "r1 no es basura")
	inv.set_trash("r1", true)
	_check(inv.is_trash(inv.find_item("r1")) == true, "r1 marcado basura")
	# favorite protege de trash
	_check(inv.set_trash("fav1", true) == false, "no se puede marcar favorito como basura")
	# bulk mass con filtro nivel
	gs.inventory.append({"id":"low1","template_id":"stone_club","name":"Low","slot":"weapon","level":1,"rarity":"common","stats":{"damage":5},"modifiers":[],"sell_value":5,"favorite":false,"trash":false,"acquired_at":10})
	var preview2: Dictionary = inv.preview_sell({"max_level":2})
	_check(preview2["count"] >= 1, "filtro nivel <2 encuentra al menos low1")
	# duplicados
	gs.inventory.append({"id":"dup1","template_id":"stone_club","name":"Garrote","slot":"weapon","level":3,"rarity":"common","stats":{"damage":12},"modifiers":[],"sell_value":12,"favorite":false,"trash":false,"acquired_at":400})
	gs.inventory.append({"id":"dup2","template_id":"stone_club","name":"Garrote","slot":"weapon","level":5,"rarity":"common","stats":{"damage":15},"modifiers":[],"sell_value":15,"favorite":false,"trash":false,"acquired_at":401})
	var dups: Dictionary = inv.get_duplicates()
	_check(dups.has("stone_club"), "detecta duplicados stone_club")
	# smart cleanup
	var smart: Dictionary = inv.get_smart_cleanup_preview()
	_check(int(smart["total_unique"]) >= 1, "smart cleanup encuentra candidatos")
	# capacity
	var cap: Dictionary = inv.get_capacity_info()
	_check(cap["total"] == 50, "capacidad 50")
	# ordering
	var sorted: Array = inv.sort_items(gs.inventory.duplicate(), "level")
	_check(int(sorted[0].get("level",0)) >= int(sorted[1].get("level",0)), "orden por nivel descendente")
	# quick equip preview
	var q: Dictionary = inv.quick_equip_best_preview()
	_check(q.has("before") and q.has("after"), "quick equip preview tiene before/after")
	print("[TEST] PASS: inventario avanzado ok")

func _check(cond: bool, msg: String) -> void:
	if not cond:
		printerr("[TEST] FAIL: " + msg)
		quit(1)
