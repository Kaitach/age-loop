extends Control

@onready var play_button: Button = %PlayButton
@onready var hint_label: Label = %HintLabel

func _ready() -> void:
	hint_label.visible = false
	play_button.pressed.connect(_on_play_pressed)

func _on_play_pressed() -> void:
	hint_label.visible = true
