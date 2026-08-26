extends Control

const BATTLE_SCENE := "res://scenes/battle/battle.tscn"
const INVENTORY_SCENE := "res://scenes/inventory/inventory_screen.tscn"
const RESEARCH_SCENE := "res://scenes/research/research_screen.tscn"
const BASE_SCENE := "res://scenes/base/base_screen.tscn"

@onready var play_button: Button = %PlayButton
@onready var inventory_button: Button = %InventoryButton
@onready var research_button: Button = %ResearchButton
@onready var base_button: Button = %BaseButton

func _ready() -> void:
	play_button.pressed.connect(_on_play_pressed)
	inventory_button.pressed.connect(_on_inventory_pressed)
	research_button.pressed.connect(_on_research_pressed)
	base_button.pressed.connect(_on_base_pressed)

func _on_play_pressed() -> void:
	get_tree().change_scene_to_file(BATTLE_SCENE)

func _on_inventory_pressed() -> void:
	get_tree().change_scene_to_file(INVENTORY_SCENE)

func _on_research_pressed() -> void:
	get_tree().change_scene_to_file(RESEARCH_SCENE)

func _on_base_pressed() -> void:
	get_tree().change_scene_to_file(BASE_SCENE)
