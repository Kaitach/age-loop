extends SceneTree

const BATTLE_SCENE := "res://scenes/battle/battle.tscn"
const OUTPUT_DIR := "res://builds/visual"

var _battle: Node
var _frame := 0
var _started := false

func _process(_delta: float) -> bool:
	if not _started:
		_started = true
		_start_showcase()
		return false
	_frame += 1
	if _frame == 35:
		_battle.get_node("UI/EraBanner").visible = false
		_capture("era_split_prehistoria_jugador_bronce_enemigos.png")
	if _frame == 55:
		var gs := root.get_node("/root/GameState")
		gs.current_era = "bronze"
		_battle.call("_on_era_changed", "bronze")
	if _frame == 92:
		_capture("era_transition_cinematica.png")
	if _frame == 205:
		_capture("era_split_bronce_jugador_bronce_enemigos.png")
	if _frame > 220:
		quit(0)
	return false

func _start_showcase() -> void:
	var gs := root.get_node("/root/GameState")
	gs.settings["music_enabled"] = false
	gs.settings["sfx_enabled"] = false
	root.get_node("/root/AudioManager").refresh_from_state()
	gs.current_era = "prehistoric"
	gs.world = 1
	gs.wave = 2
	gs.battle_speed = 0.0
	gs.gold = 986
	gs.science = 351
	gs.materials = 3762
	gs.crystals = 0
	gs.equipped_items = {
		"weapon": {
			"id": "showcase_stick",
			"name": "Palo de madera",
			"slot": "weapon",
			"era": "prehistoric",
			"attack_type": "melee",
			"stats": {"damage": 10, "attack_range": 0}
		}
	}
	_battle = load(BATTLE_SCENE).instantiate()
	root.add_child(_battle)
	_battle.call("_on_spawn_enemy", "normal", Vector2.ZERO)
	var enemies: Array[Node] = get_nodes_in_group("enemies")
	if not enemies.is_empty():
		enemies[0].position = Vector2(820, 1380)
		enemies[0].set_process(false)

func _capture(file_name: String) -> void:
	var directory := ProjectSettings.globalize_path(OUTPUT_DIR)
	DirAccess.make_dir_recursive_absolute(directory)
	var image := get_root().get_texture().get_image()
	image.save_png(directory.path_join(file_name))
	print("[CAPTURE] " + directory.path_join(file_name))
