class_name Projectile
extends Node2D

const ERA_PROFILE = preload("res://scripts/progression/era_profile.gd")

const RADIUS := 11.0

var damage: int = 0
var speed: float = 700.0
var target: Combatant
var _direction: Vector2 = Vector2.UP
var _life: float = 1.2
var _era_id := "prehistoric"

func setup(from: Vector2, p_target: Combatant, p_damage: int, p_speed: float, p_era_id: String = "") -> void:
	position = from
	target = p_target
	damage = p_damage
	speed = p_speed
	_era_id = p_era_id
	if _era_id.is_empty():
		var state := get_tree().root.get_node_or_null("/root/GameState")
		_era_id = String(state.current_era) if state != null else "prehistoric"

func _ready() -> void:
	add_to_group("projectiles")
	var spr := Sprite2D.new()
	spr.texture = load(ERA_PROFILE.get_asset(_era_id, "projectile")) as Texture2D
	spr.centered = true
	add_child(spr)

func _process(delta: float) -> void:
	var battle_state := get_tree().root.get_node_or_null("/root/GameState")
	if battle_state != null:
		delta *= float(battle_state.battle_speed)
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
