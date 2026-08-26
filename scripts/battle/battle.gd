extends Node2D

enum State { FIGHTING, WON, LOST }

const MENU_SCENE := "res://scenes/menu/main_menu.tscn"
const WAVE_LABEL_TEXT := "OLEADA 1-1"
const TOTAL_ENEMIES := 8
const SPAWN_Y := -80.0
const SPAWN_X_MIN := 140.0
const SPAWN_X_MAX := 940.0
const FIRST_SPAWN_DELAY := 0.6

@export var spawn_interval: float = 1.3

var state: State = State.FIGHTING
var _enemies_to_spawn: int = TOTAL_ENEMIES
var _spawn_cooldown: float = FIRST_SPAWN_DELAY

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

func _ready() -> void:
	wave_label.text = WAVE_LABEL_TEXT
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
	_spawn_tick(delta)
	if _enemies_to_spawn == 0 and get_tree().get_nodes_in_group("enemies").is_empty():
		_end_battle(true)

func _spawn_tick(delta: float) -> void:
	if _enemies_to_spawn <= 0:
		return
	_spawn_cooldown -= delta
	if _spawn_cooldown > 0.0:
		return
	_spawn_cooldown = spawn_interval
	_enemies_to_spawn -= 1
	var enemy := Enemy.new()
	enemy.position = Vector2(randf_range(SPAWN_X_MIN, SPAWN_X_MAX), SPAWN_Y)
	enemies_container.add_child(enemy)

func is_over() -> bool:
	return state != State.FIGHTING

func did_win() -> bool:
	return state == State.WON

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
	result_sub.text = "La oleada fue repelida." if victory else "La base ha caido."
	result_panel.visible = true

func _on_retry_pressed() -> void:
	get_tree().reload_current_scene()

func _on_menu_pressed() -> void:
	get_tree().change_scene_to_file(MENU_SCENE)
