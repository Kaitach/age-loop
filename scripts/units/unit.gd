class_name AllyUnit
extends Combatant

const ERA_PROFILE = preload("res://scripts/progression/era_profile.gd")

var damage: int = 10
var attack_speed: float = 1.0
var attack_range: float = 360.0
var attack_type: String = "ranged"
var movement_speed: float = 170.0

var _attack_cd: float = 0.0
var _type: String = "archer"
var _walk_phase: float = 0.0
var _base_y: float = 0.0
var _dying: bool = false
var _sprite: Sprite2D
var _shadow: GroundShadow
var _era_id := "prehistoric"

func setup(unit_id: String) -> void:
	_type = unit_id
	var data: Dictionary = DataLoader.get_unit_data(unit_id)
	damage = int(data.get("damage", 10))
	attack_speed = float(data.get("attack_speed", 1.0))
	attack_range = float(data.get("attack_range", 360.0))
	attack_type = String(data.get("attack_type", "ranged"))
	movement_speed = float(data.get("movement_speed", 170.0))
	max_health = int(data.get("max_health", 70))
	body_size = float(data.get("body_size", 58.0))
	body_color = DataLoader.color_from_array(data.get("body_color", []), body_color)

var body_color: Color = Color(0.3, 0.6, 0.85)
var body_size: float = 58.0

func _ready() -> void:
	super()
	add_to_group("allies")
	_base_y = position.y
	_walk_phase = GameRng.randf() * TAU
	_era_id = _current_era()
	_shadow = GroundShadow.new()
	_shadow.radius = body_size * 0.52
	add_child(_shadow)
	_sprite = Sprite2D.new()
	var path: String = ERA_PROFILE.get_asset(_era_id, "unit", _type)
	_sprite.texture = load(path) as Texture2D
	_sprite.centered = true
	_sprite.scale = Vector2.ONE * 1.16
	_sprite.position = Vector2(0, -body_size * 0.5)
	_sprite.name = "Sprite"
	add_child(_sprite)

func set_era_visual(era_id: String) -> void:
	_era_id = era_id
	if _sprite == null:
		return
	var texture := load(ERA_PROFILE.get_asset(_era_id, "unit", _type)) as Texture2D
	if texture != null:
		_sprite.texture = texture
	queue_redraw()

func _current_era() -> String:
	var state := get_tree().root.get_node_or_null("/root/GameState")
	return String(state.current_era) if state != null else "prehistoric"

func _process(delta: float) -> void:
	var battle_state := get_tree().root.get_node_or_null("/root/GameState")
	if battle_state != null:
		delta *= float(battle_state.battle_speed)
	super(delta)
	if _dying:
		return
	if not can_act():
		return
	delta *= status_speed_multiplier()
	position.y = _base_y
	_attack_cd -= delta
	var target := _nearest_enemy_any()
	var walking := false
	if target != null:
		var engage_distance := maxf(58.0, attack_range + body_size * 0.5 + target.body_size * 0.5)
		var distance := global_position.distance_to(target.global_position)
		if attack_type == "melee" and distance > engage_distance:
			position.x = move_toward(position.x, clampf(target.global_position.x - engage_distance, 300.0, 900.0), movement_speed * delta)
			walking = true
		elif _attack_cd <= 0.0 and distance <= engage_distance + 8.0:
			_attack_cd = 1.0 / maxf(attack_speed, 0.1)
			_shoot(target)
	_animate_actor(delta, walking)
func _on_death() -> void:
	_dying = true
	remove_from_group("allies")
	super()

func _nearest_enemy() -> Enemy:
	var best: Enemy = null
	var best_d := INF
	for node in get_tree().get_nodes_in_group("enemies"):
		var e := node as Enemy
		if e == null or not e.is_alive():
			continue
		var d := global_position.distance_squared_to(e.global_position)
		if d < best_d and d <= attack_range * attack_range:
			best_d = d
			best = e
	return best

func _nearest_enemy_any() -> Enemy:
	var best: Enemy = null
	var best_d := INF
	for node in get_tree().get_nodes_in_group("enemies"):
		var e := node as Enemy
		if e == null or not e.is_alive():
			continue
		var d := global_position.distance_squared_to(e.global_position)
		if d < best_d and (attack_type == "melee" or d <= attack_range * attack_range):
			best_d = d
			best = e
	return best

func _shoot(target: Enemy) -> void:
	var p := Projectile.new()
	p.setup(global_position + Vector2(0, -20), target, damage, 700.0, _era_id)
	get_parent().add_child(p)

func _draw() -> void:
	var half := body_size * 0.5
	_draw_hp_bar(body_size + 16, -half - 22)

func _animate_actor(delta: float, walking: bool) -> void:
	if _sprite == null:
		return
	_walk_phase += delta * (10.0 if walking else 2.8)
	var stride := sin(_walk_phase)
	_sprite.position.y = -body_size * 0.5 + (absf(stride) * 3.0 if walking else sin(_walk_phase) * 1.2)
	_sprite.position.x = stride * (2.0 if walking else 0.5)
	_sprite.rotation = stride * (0.04 if walking else 0.012)
	if _shadow != null:
		_shadow.scale = Vector2(1.0 + absf(stride) * 0.08, 1.0 - absf(stride) * 0.05)
