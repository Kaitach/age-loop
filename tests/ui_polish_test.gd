extends SceneTree

const MENU_SCENE := "res://scenes/menu/main_menu.tscn"
const INVENTORY_SCENE := "res://scenes/inventory/inventory_screen.tscn"
const EQUIPMENT_SCENE := "res://scenes/equipment/equipment_screen.tscn"

var _phase := "menu"
var _frames := 0
var _current: Node
var _started := false

func _initialize() -> void:
	return

func _start_test() -> void:
	var gs := root.get_node("/root/GameState")
	gs.pending_notifications = [{"type": "research_complete", "title": "Ciencia lista", "body": "Prueba de notificacion"}]
	gs.inventory = []
	gs.pending_items = []
	gs.equipped_items = {}
	_current = load(MENU_SCENE).instantiate()
	root.add_child(_current)

func _process(_delta: float) -> bool:
	if not _started:
		if root.get_node_or_null("/root/GameState") == null:
			return false
		_started = true
		_start_test()
		return false
	_frames += 1
	if _frames < 3:
		return false
	match _phase:
		"menu":
			if not bool(_current.get_node("NotificationOverlay").visible):
				return _fail("la notificacion personalizada no aparece")
			if OS.is_debug_build() and _current.get_node_or_null("DebugOverlay") == null:
				return _fail("el menu debug no se instancia en build de desarrollo")
			if not _current.find_children("*", "AcceptDialog", true, false).is_empty():
				return _fail("el menu todavia usa el dialogo gris por defecto")
			_pass("notificacion del menu usa overlay propio sin boton X")
			_current.queue_free()
			var gs := root.get_node("/root/GameState")
			gs.pending_notifications = []
			gs.inventory = [_sample_item()]
			_current = load(INVENTORY_SCENE).instantiate()
			root.add_child(_current)
			_phase = "inventory"
			_frames = 0
		"inventory":
			var icons := _current.find_children("*", "ItemIcon", true, false)
			if icons.is_empty():
				return _fail("el inventario no renderiza el icono del objeto (nodos=%d)" % _current.find_children("*", "", true, false).size())
			if _current.get_node_or_null("MainVBox/FilterBar") == null:
				return _fail("el inventario no tiene filtros por categoria")
			_pass("inventario renderiza icono y filtros por tipo")
			_current.queue_free()
			_current = load(EQUIPMENT_SCENE).instantiate()
			root.add_child(_current)
			_phase = "equipment"
			_frames = 0
		"equipment":
			var grid := _current.get_node_or_null("MainVBox/SlotsGrid")
			if grid == null or grid.get_child_count() != 6:
				return _fail("la pantalla de equipo no muestra los seis slots")
			_pass("pantalla de equipo muestra los seis slots")
			quit(0)
			return true
	return false

func _sample_item() -> Dictionary:
	return {
		"id": "test_sword",
		"template_id": "iron_sword",
		"slot": "weapon",
		"level": 2,
		"rarity": "rare",
		"attack_type": "melee",
		"stats": {"damage": 12, "attack_range": 20},
		"modifiers": [],
	}

func _fail(message: String) -> bool:
	printerr("[TEST] FAIL: " + message)
	quit(1)
	return true

func _pass(message: String) -> void:
	print("[TEST] PASS: " + message)
