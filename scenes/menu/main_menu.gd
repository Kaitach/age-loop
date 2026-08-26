extends Control

const BATTLE_SCENE := "res://scenes/battle/battle.tscn"
const INVENTORY_SCENE := "res://scenes/inventory/inventory_screen.tscn"
const RESEARCH_SCENE := "res://scenes/research/research_screen.tscn"

@onready var play_button: Button = %PlayButton
@onready var inventory_button: Button = %InventoryButton
@onready var research_button: Button = %ResearchButton

func _ready() -> void:
	play_button.pressed.connect(_on_play_pressed)
	inventory_button.pressed.connect(_on_inventory_pressed)
	research_button.pressed.connect(_on_research_pressed)

func _on_play_pressed() -> void:
	get_tree().change_scene_to_file(BATTLE_SCENE)

func _on_inventory_pressed() -> void:
	get_tree().change_scene_to_file(INVENTORY_SCENE)

func _on_research_pressed() -> void:
	get_tree().change_scene_to_file(RESEARCH_SCENE)
