extends Control

const BATTLE_SCENE := "res://scenes/battle/battle.tscn"

@onready var play_button: Button = %PlayButton

func _ready() -> void:
	play_button.pressed.connect(_on_play_pressed)

func _on_play_pressed() -> void:
	get_tree().change_scene_to_file(BATTLE_SCENE)
