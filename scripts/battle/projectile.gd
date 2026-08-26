class_name Projectile
extends Node2D

const RADIUS := 11.0

var damage: int = 0
var speed: float = 700.0
var target: Combatant
var _direction: Vector2 = Vector2.UP
var _life: float = 1.2

func setup(from: Vector2, p_target: Combatant, p_damage: int, p_speed: float) -> void:
	position = from
	target = p_target
	damage = p_damage
	speed = p_speed

func _ready() -> void:
	add_to_group("projectiles")

func _process(delta: float) -> void:
	if is_instance_valid(target) and target.is_alive():
		_direction = (target.global_position - global_position).normalized()
	global_position += _direction * speed * delta
	_life -= delta
	if is_instance_valid(target) and global_position.distance_to(target.global_position) <= 22.0:
		if target.is_alive():
			target.take_damage(damage)
		queue_free()
	elif _life <= 0.0:
		queue_free()

func _draw() -> void:
	draw_line(Vector2.ZERO, -_direction * 26.0, Color(0.5, 0.85, 1.0, 0.4), 5.0)
	draw_circle(Vector2.ZERO, RADIUS, Color(0.5, 0.85, 1.0))
	draw_circle(Vector2.ZERO, RADIUS * 0.45, Color(0.9, 0.98, 1.0))
