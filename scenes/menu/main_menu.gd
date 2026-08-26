extends Control

const BATTLE_SCENE := "res://scenes/battle/battle.tscn"
const INVENTORY_SCENE := "res://scenes/inventory/inventory_screen.tscn"

@onready var play_button: Button = %PlayButton
@onready var inventory_button: Button = %InventoryButton

func _ready() -> void:
	play_button.pressed.connect(_on_play_pressed)
	inventory_button.pressed.connect(_on_inventory_pressed)

func _on_play_pressed() -> void:
	get_tree().change_scene_to_file(BATTLE_SCENE)

func _on_inventory_pressed() -> void:
	get_tree().change_scene_to_file(INVENTORY_SCENE)
