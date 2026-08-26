extends Control

const MAIN_MENU_SCENE := "res://scenes/menu/main_menu.tscn"
const SPLASH_DURATION := 1.5

func _ready() -> void:
	await get_tree().create_timer(SPLASH_DURATION).timeout
	get_tree().change_scene_to_file(MAIN_MENU_SCENE)
