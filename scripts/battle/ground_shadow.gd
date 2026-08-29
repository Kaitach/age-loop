class_name GroundShadow
extends Node2D

@export var radius := 34.0
@export var shadow_color := Color(0.01, 0.015, 0.025, 0.34)

func _ready() -> void:
	z_index = -10
	queue_redraw()

func _draw() -> void:
	draw_set_transform(Vector2.ZERO, 0.0, Vector2(1.0, 0.34))
	draw_circle(Vector2.ZERO, radius, shadow_color)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
