extends Node2D

enum State { FIGHTING, WON, LOST }

const MENU_SCENE := "res://scenes/menu/main_menu.tscn"
const MAX_WAVE := 10

var state: State = State.FIGHTING

@onready var player: Player = $World/Player
@onready var base_building: BaseBuilding = $World/Base
@onready var enemies_container: Node2D = $World/Enemies
@onready var wave_label: Label = %WaveLabel
@onready var player_bar: ProgressBar = %PlayerBar
@onready var base_bar: ProgressBar = %BaseBar
@onready var result_panel: CenterContainer = %ResultPanel
@onready var result_title: Label = %ResultTitle
@onready var result_sub: Label = %ResultSub
@onready var retry_button: Button = %RetryButton
@onready var menu_button: Button = %MenuButton

var wave_manager := WaveManager.new()

func _ready() -> void:
	add_child(wave_manager)
	wave_manager.spawn_enemy.connect(_on_spawn_enemy)
	wave_manager.start(GameState.world, GameState.wave)
	wave_label.text = "OLEADA %d-%d" % [GameState.world, GameState.wave]
	player_bar.max_value = player.max_health
	player_bar.value = player.health
	base_bar.max_value = base_building.max_health
	base_bar.value = base_building.health
	player.damaged.connect(func(_amount: int) -> void: player_bar.value = player.health)
	base_building.damaged.connect(func(_amount: int) -> void: base_bar.value = base_building.health)
	player.died.connect(_end_battle.bind(false))
	base_building.died.connect(_end_battle.bind(false))
	retry_button.pressed.connect(_on_retry_pressed)
	menu_button.pressed.connect(_on_menu_pressed)

func _process(delta: float) -> void:
	if state != State.FIGHTING:
		return
	wave_manager.tick(delta)
	if wave_manager.finished_spawning() and get_tree().get_nodes_in_group("enemies").is_empty():
		_victory()

func _on_spawn_enemy(enemy_id: String, position_p: Vector2) -> void:
	var enemy := Enemy.new()
	enemy.setup_from_data(
		enemy_id,
		WaveManager.get_enemy_data(enemy_id),
		WaveManager.hp_scale_for(GameState.world, GameState.wave),
		WaveManager.dmg_scale_for(GameState.world, GameState.wave)
	)
	enemy.position = position_p
	enemies_container.add_child(enemy)

func is_over() -> bool:
	return state != State.FIGHTING

func did_win() -> bool:
	return state == State.WON

func _victory() -> void:
	var rewards := WaveManager.calculate_rewards(GameState.world, GameState.wave)
	result_sub.text = "+%d oro   +%d ciencia   +%d materiales" % [rewards["gold"], rewards["science"], rewards["materials"]]
	if GameState.wave >= MAX_WAVE:
		GameState.wave = MAX_WAVE
	else:
		GameState.wave += 1
	_end_battle(true)

func _end_battle(victory: bool) -> void:
	if state == State.WON or state == State.LOST:
		return
	state = State.WON if victory else State.LOST
	for node in get_tree().get_nodes_in_group("enemies"):
		node.set_process(false)
	for node in get_tree().get_nodes_in_group("projectiles"):
		node.set_process(false)
	player.set_process(false)
	base_building.set_process(false)
	result_title.text = "VICTORIA" if victory else "DERROTA"
	if not victory:
		result_sub.text = "La base ha caido."
	result_panel.visible = true

func _on_retry_pressed() -> void:
	get_tree().reload_current_scene()

func _on_menu_pressed() -> void:
	get_tree().change_scene_to_file(MENU_SCENE)
