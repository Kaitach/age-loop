extends SceneTree

const BATTLE_SCENE := "res://scenes/battle/battle.tscn"
const OUTPUT_DIR := "res://builds/visual"

var _battle: Node
var _frame := 0
var _combo_shown := false

func _process(_delta: float) -> bool:
	_frame += 1
	if _frame == 2:
		_battle.get_node("UI/EraBanner").visible = false
	if _frame == 120:
		for child in _battle.get_node("UI").get_children():
			if child.z_index >= 24:
				child.visible = false
		_battle.call("_register_combo", Vector2(620, 1280))
		_combo_shown = true
	if _frame == 142 and _combo_shown:
		_capture("battle_prehistoria_referencia.png")
		quit(0)
	return false

func _init() -> void:
	call_deferred("_start")

func _start() -> void:
	var gs := root.get_node("/root/GameState")
	gs.settings["music_enabled"] = false
	gs.settings["sfx_enabled"] = false
	root.get_node("/root/AudioManager").refresh_from_state()
	gs.current_era = "prehistoric"
	gs.world = 1
	gs.wave = 1
	gs.battle_speed = 0.0
	gs.gold = 36212
	gs.science = 2110
	gs.materials = 7096
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
	# Keep one tank and two small creatures in-frame, matching the intended solo
	# player + single pet composition from the visual reference.
	_battle.call("_on_spawn_enemy", "tank", Vector2.ZERO)
	_battle.call("_on_spawn_enemy", "normal", Vector2.ZERO)
	_battle.call("_on_spawn_enemy", "fast", Vector2.ZERO)
	var enemies: Array[Node] = get_nodes_in_group("enemies")
	var positions := [Vector2(820, 1360), Vector2(930, 1400), Vector2(1010, 1440)]
	for index in mini(enemies.size(), positions.size()):
		enemies[index].position = positions[index]
		enemies[index].set_process(false)

func _capture(file_name: String) -> void:
	var directory := ProjectSettings.globalize_path(OUTPUT_DIR)
	DirAccess.make_dir_recursive_absolute(directory)
	var image := get_root().get_texture().get_image()
	if image != null:
		image.save_png(directory.path_join(file_name))
		print("[CAPTURE] " + directory.path_join(file_name))
