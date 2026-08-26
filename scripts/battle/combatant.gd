class_name Combatant
extends Node2D

signal damaged(amount: int)
signal died

@export var max_health: int = 100

var health: int = 0
var _flash_left: float = 0.0
var _dead: bool = false

func _ready() -> void:
	health = max_health

func is_alive() -> bool:
	return not _dead and health > 0

func take_damage(amount: int) -> void:
	if _dead or amount <= 0:
		return
	health = maxi(health - amount, 0)
	_flash_left = 0.15
	queue_redraw()
	damaged.emit(amount)
	if health == 0:
		_dead = true
		died.emit()
		_on_death()

func _process(delta: float) -> void:
	if _flash_left > 0.0:
		_flash_left -= delta
		modulate = Color(1.0, 0.4, 0.4) if _flash_left > 0.0 else Color.WHITE

func _on_death() -> void:
	var tween := create_tween()
	tween.tween_property(self, "modulate:a", 0.0, 0.25)
	tween.parallel().tween_property(self, "scale", Vector2(0.6, 0.6), 0.25)
	tween.tween_callback(queue_free)

func _draw_hp_bar(width: float, y_offset: float) -> void:
	if _dead or health >= max_health or health <= 0:
		return
	var ratio := float(health) / float(max_health)
	draw_rect(Rect2(-width * 0.5 - 2.0, y_offset - 2.0, width + 4.0, 12.0), Color(0, 0, 0, 0.6))
	var fill_color := Color(0.35, 0.85, 0.3).lerp(Color(0.9, 0.25, 0.2), 1.0 - ratio)
	draw_rect(Rect2(-width * 0.5, y_offset, width * ratio, 8.0), fill_color)
