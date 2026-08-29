extends SceneTree

const SCENES := [
	"res://scenes/bootstrap/bootstrap.tscn",
	"res://scenes/menu/main_menu.tscn",
	"res://scenes/battle/battle.tscn",
	"res://scenes/inventory/inventory_screen.tscn",
	"res://scenes/equipment/equipment_screen.tscn",
	"res://scenes/research/research_screen.tscn",
	"res://scenes/base/base_screen.tscn",
	"res://scenes/settings/settings_screen.tscn",
]

var _index := 0
var _current: Node
var _wait_frame := false

func _initialize() -> void:
	_load_next()

func _process(_delta: float) -> bool:
	if _current == null:
		return false
	if not _wait_frame:
		_wait_frame = true
		return false
	_current.queue_free()
	_current = null
	_wait_frame = false
	_index += 1
	if _index >= SCENES.size():
		print("[TEST] PASS: todas las escenas instancian correctamente")
		quit(0)
		return true
	_load_next()
	return false

func _load_next() -> void:
	var packed := load(SCENES[_index]) as PackedScene
	if packed == null:
		printerr("[TEST] FAIL: no se pudo cargar " + SCENES[_index])
		quit(1)
		return
	_current = packed.instantiate()
	root.add_child(_current)
	print("[TEST] OK: " + SCENES[_index])
