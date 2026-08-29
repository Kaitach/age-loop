class_name Player
extends Combatant

const BODY_RADIUS := 46.0
const MELEE_STEP_LIMIT := 860.0
const GEAR_OVERLAY_SCRIPT = preload("res://scripts/battle/player_gear_overlay.gd")
const ERA_PROFILE = preload("res://scripts/progression/era_profile.gd")

@export var base_damage: int = 14
@export var base_max_health: int = 100
@export var base_attack_speed: float = 1.2
var attack_speed: float = 1.2
@export var attack_range: float = 0.0
@export var projectile_speed: float = 720.0
@export var movement_speed: float = 220.0

signal critical_hit(target: Combatant, damage: int)

var damage: int = 14
var critical_chance: float = 0.05
var critical_damage: float = 1.5
var damage_multiplier: float = 1.0
var attack_speed_multiplier: float = 1.0
var attack_type := "melee"

var _attack_cooldown: float = 0.6
var _dying: bool = false
var _walk_phase: float = 0.0
var _base_y: float = 0.0
var _sprite: Sprite2D
var _shadow: GroundShadow
var _gear_overlay: Node2D
var _era_id := "prehistoric"

func _ready() -> void:
	refresh_combat_stats(false)
	super()
	add_to_group("player")
	_base_y = position.y
	_shadow = GroundShadow.new()
	_shadow.radius = 42.0
	_shadow.position = Vector2(0, 0)
	add_child(_shadow)
	_sprite = Sprite2D.new()
	_sprite.texture = load("res://assets/characters/player.png") as Texture2D
	_sprite.centered = true
	_sprite.scale = Vector2.ONE * 1.25
	_sprite.position = Vector2(0, -48)
	_sprite.name = "Sprite"
	add_child(_sprite)
	_gear_overlay = GEAR_OVERLAY_SCRIPT.new()
	_gear_overlay.position = Vector2(0, -48)
	_gear_overlay.scale = Vector2.ONE * 1.25
	_gear_overlay.z_index = 2
	add_child(_gear_overlay)
	_era_id = _current_era()
	refresh_visual()

func set_era_visual(era_id: String) -> void:
	_era_id = era_id
	refresh_visual()

func refresh_visual() -> void:
	if _sprite != null:
		var path: String = ERA_PROFILE.get_asset(_era_id, "player")
		var texture := load(path) as Texture2D
		if texture != null:
			_sprite.texture = texture
	if _gear_overlay != null:
		_gear_overlay.setup(_era_id, _equipment_state())

func _current_era() -> String:
	var state := get_tree().root.get_node_or_null("/root/GameState")
	return String(state.current_era) if state != null else "prehistoric"

func _equipment_state() -> Dictionary:
	var state := get_tree().root.get_node_or_null("/root/GameState")
	return state.equipped_items if state != null else {}

func refresh_combat_stats(preserve_health: bool = true) -> void:
	var old_max := max_health
	var old_health := health
	var final_stats := StatsCalculator.player_final_stats(self)
	damage = int(round(float(final_stats["damage"])))
	max_health = int(round(float(final_stats["max_health"])))
	attack_speed = float(final_stats["attack_speed"])
	attack_range = float(final_stats.get("attack_range", 95.0))
	attack_type = String(final_stats.get("attack_type", "melee"))
	critical_chance = float(final_stats["critical_chance"])
	critical_damage = float(final_stats["critical_damage"])
	armor = float(final_stats.get("armor", 0.0))
	if preserve_health and old_max > 0 and old_health > 0:
		health = clampi(int(round(float(old_health) / float(old_max) * max_health)), 1, max_health)

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
	_attack_cooldown -= delta
	var target := _nearest_enemy_any()
	var walking := false
	if target != null:
		var engage_distance := _engage_distance(target)
		var distance := global_position.distance_to(target.global_position)
		if attack_type == "melee" and distance > engage_distance:
			var desired_x := target.global_position.x - engage_distance
			position.x = move_toward(position.x, clampf(desired_x, 180.0, MELEE_STEP_LIMIT), movement_speed * delta)
			walking = true
		elif _attack_cooldown <= 0.0 and distance <= engage_distance + 8.0:
			_attack_cooldown = 1.0 / maxf(attack_speed * attack_speed_multiplier, 0.1)
			_shoot(target)
	_animate_actor(delta, walking)

func _nearest_enemy() -> Enemy:
	var best: Enemy = null
	var best_dist := INF
	for node in get_tree().get_nodes_in_group("enemies"):
		var enemy := node as Enemy
		if enemy == null or not enemy.is_alive():
			continue
		var dist := global_position.distance_squared_to(enemy.global_position)
		if dist < best_dist and dist <= attack_range * attack_range:
			best_dist = dist
			best = enemy
	return best

func _nearest_enemy_any() -> Enemy:
	var best: Enemy = null
	var best_dist := INF
	for node in get_tree().get_nodes_in_group("enemies"):
		var enemy := node as Enemy
		if enemy == null or not enemy.is_alive():
			continue
		var dist := global_position.distance_squared_to(enemy.global_position)
		if dist < best_dist and (attack_type == "melee" or dist <= attack_range * attack_range):
			best_dist = dist
			best = enemy
	return best

func _engage_distance(target: Enemy) -> float:
	return maxf(62.0, attack_range + BODY_RADIUS + target.body_size * 0.5)

func _shoot(target: Enemy) -> void:
	var hit_damage := int(round(float(damage) * damage_multiplier))
	var is_crit := GameRng.randf() < critical_chance
	if is_crit:
		hit_damage = int(round(float(damage) * damage_multiplier * critical_damage))
		critical_hit.emit(target, hit_damage)
		_play_sfx("critical")
	else:
		_play_sfx("hit")
	if attack_type == "melee":
		if is_instance_valid(target) and target.is_alive() and global_position.distance_to(target.global_position) <= _engage_distance(target) + 12.0:
			target.take_damage(hit_damage)
			_show_slash(target.global_position)
		return
	var projectile := Projectile.new()
	projectile.setup(global_position + Vector2(0, -34), target, hit_damage, projectile_speed, _era_id)
	get_parent().add_child(projectile)

func _show_slash(pos: Vector2) -> void:
	var slash := Line2D.new()
	slash.width = 7.0
	slash.default_color = Color(1, 0.9, 0.4, 0.9)
	slash.points = PackedVector2Array([pos + Vector2(-28, -18), pos + Vector2(28, 18)])
	slash.z_index = 10
	var slash_parent := get_tree().current_scene
	if slash_parent == null:
		slash_parent = get_tree().root
	slash_parent.add_child(slash)
	var tw := create_tween()
	tw.tween_property(slash, "modulate:a", 0.0, 0.22)
	tw.tween_callback(slash.queue_free)

func _animate_actor(delta: float, walking: bool) -> void:
	if _sprite == null:
		return
	_walk_phase += delta * (10.0 if walking else 2.8)
	var stride := sin(_walk_phase)
	_sprite.position.y = -48.0 + (absf(stride) * 4.0 if walking else sin(_walk_phase) * 1.5)
	_sprite.position.x = stride * (2.5 if walking else 0.6)
	_sprite.rotation = stride * (0.035 if walking else 0.012)
	if _shadow != null:
		_shadow.scale = Vector2(1.0 + absf(stride) * 0.07, 1.0 - absf(stride) * 0.05)

func _play_sfx(id: String) -> void:
	var tree := get_tree()
	if tree == null:
		return
	var am := tree.root.get_node_or_null("/root/AudioManager")
	if am != null:
		am.play_sfx(id)

func _on_death() -> void:
	_dying = true
	super()

func _draw() -> void:
	_draw_hp_bar(BODY_RADIUS + 44, -BODY_RADIUS - 36.0)
