class_name Enemy
extends Combatant

const ERA_PROFILE = preload("res://scripts/progression/era_profile.gd")
const ERA_COMBAT_RULES = preload("res://scripts/progression/era_combat_rules.gd")

const ENGAGE_RANGE := 400.0
const BOSS_BAR_WIDTH := 260.0

@export var damage: int = 7
@export var movement_speed: float = 110.0
@export var attack_speed: float = 1.0
@export var attack_range: float = 95.0
@export var body_size: float = 72.0
@export var body_color: Color = Color(0.86, 0.28, 0.25)
@export var is_boss: bool = false

var enemy_id := ""
var behavior := "normal"
var reward_gold := 0
var reward_science := 0
var reward_materials := 0

var _target: Combatant
var _attack_cooldown: float = 0.0
var _dying: bool = false
var _summon_cd: float = 7.0
var _enraged: bool = false
var _walk_phase: float = 0.0
var _base_y: float = 0.0
var _sprite: Sprite2D
var _shadow: GroundShadow
var _era_id := "prehistoric"

func setup_from_data(enemy_id_p: String, data: Dictionary, hp_scale: float, dmg_scale: float) -> void:
	enemy_id = enemy_id_p
	max_health = maxi(1, int(round(float(data.get("base_health", 40)) * hp_scale)))
	damage = maxi(1, int(ceil(float(data.get("damage", 6)) * dmg_scale)))
	movement_speed = float(data.get("movement_speed", 110))
	attack_speed = float(data.get("attack_speed", 1.0))
	attack_range = float(data.get("attack_range", 95))
	body_size = float(data.get("body_size", 72))
	body_color = DataLoader.color_from_array(data.get("body_color", []), body_color)
	is_boss = bool(data.get("is_boss", false))
	behavior = String(data.get("behavior", "normal"))
	var rewards: Dictionary = data.get("rewards", {})
	reward_gold = int(rewards.get("gold", 0))
	reward_science = int(rewards.get("science", 0))
	reward_materials = int(rewards.get("materials", 0))

func _ready() -> void:
	super()
	add_to_group("enemies")
	_base_y = position.y
	_walk_phase = GameRng.randf() * TAU
	_era_id = _current_era()
	_add_sprite()

func set_era_visual(era_id: String) -> void:
	_era_id = era_id
	if _sprite == null:
		return
	var texture := load(ERA_PROFILE.get_asset(_era_id, "enemy", enemy_id)) as Texture2D
	if texture != null:
		_sprite.texture = texture
		_sprite.scale = Vector2(-1.18, 1.18)
	queue_redraw()

func _process(delta: float) -> void:
	var battle_state := get_tree().root.get_node_or_null("/root/GameState")
	if battle_state != null:
		delta *= float(battle_state.battle_speed)
	super(delta)
	if _dying:
		return
	ERA_COMBAT_RULES.tick_enemy(self, _era_id, delta)
	if not can_act():
		return
	delta *= status_speed_multiplier()
	if behavior == "summoner" and is_boss:
		_summon_cd -= delta
		if _summon_cd <= 0.0:
			_summon_cd = 8.0
			_spawn_minions()
	if behavior == "enrage" and health < max_health * 0.4 and not _enraged:
		_enraged = true
		movement_speed *= 1.7
		attack_speed *= 1.3
		modulate = Color(1.2, 0.5, 0.5)
	if behavior == "phase_enrage" and health < max_health * 0.5 and not _enraged:
		_enraged = true
		attack_speed *= 1.6
		body_color = body_color.darkened(0.15)
		queue_redraw()
	_acquire_target()
	if _target == null or not is_instance_valid(_target) or not _target.is_alive():
		return
	var dist := global_position.distance_to(_target.global_position)
	var eff_speed := movement_speed * ERA_COMBAT_RULES.enemy_speed_multiplier(self, _era_id)
	position.y = _base_y
	var walking := dist > attack_range
	_animate_actor(delta, walking)
	if dist > attack_range:
		global_position += (_target.global_position - global_position).normalized() * eff_speed * delta
		_base_y = global_position.y
	else:
		_attack_cooldown -= delta
		if _attack_cooldown <= 0.0:
			_attack_cooldown = 1.0 / maxf(attack_speed * ERA_COMBAT_RULES.enemy_attack_multiplier(self, _era_id), 0.1)
			if behavior == "area_attack":
				for target_node in get_tree().get_nodes_in_group("player") + get_tree().get_nodes_in_group("base_fort"):
					var area_target := target_node as Combatant
					if area_target != null and area_target.is_alive() and global_position.distance_to(area_target.global_position) <= attack_range + 160.0:
						area_target.take_damage(damage)
			else:
				_target.take_damage(damage)
			ERA_COMBAT_RULES.on_enemy_attack(self, _target, _era_id)
			queue_redraw()
			# lunge forward on attack
			var tw := create_tween()
			var start_pos := position
			var dir := (_target.global_position - global_position).normalized()
			tw.tween_property(self, "position", start_pos + dir * 12.0, 0.08)
			tw.tween_property(self, "position", start_pos, 0.12)

func _spawn_minions() -> void:
	var parent_node := get_parent()
	if parent_node == null:
		return
	for i in range(2):
		var m := Enemy.new()
		m.setup_from_data("fast", WaveManager.get_enemy_data("fast"), 1.0, 1.0)
		m.position = position + Vector2(GameRng.randf_range(-80, 80), GameRng.randf_range(-40, 40))
		parent_node.add_child(m)

func _acquire_target() -> void:
	var player := get_tree().get_first_node_in_group("player") as Combatant
	if player != null and player.is_alive() and global_position.distance_to(player.global_position) <= ENGAGE_RANGE:
		_target = player
	else:
		_target = get_tree().get_first_node_in_group("base_fort") as Combatant

func _on_death() -> void:
	_dying = true
	remove_from_group("enemies")
	super()

func _add_sprite() -> void:
	var path: String = ERA_PROFILE.get_asset(_era_id, "enemy", enemy_id)
	var tex = load(path) as Texture2D
	if tex == null:
		return
	_shadow = GroundShadow.new()
	_shadow.radius = body_size * 0.52
	add_child(_shadow)
	_sprite = Sprite2D.new()
	_sprite.texture = tex
	_sprite.centered = true
	_sprite.position = Vector2(0, -body_size * 0.5)
	_sprite.scale = Vector2(-1.18, 1.18)
	_sprite.name = "Sprite"
	add_child(_sprite)

func era_dash(distance: float) -> void:
	if not is_alive():
		return
	var target := _target
	if target == null or not is_instance_valid(target):
		return
	var direction := (target.global_position - global_position).normalized()
	var destination := global_position + direction * distance
	destination.x = clampf(destination.x, 720.0, 1120.0)
	apply_status("invulnerable", 0.4)
	var tw := create_tween()
	tw.tween_property(self, "global_position", destination, 0.22).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)

func era_teleport(distance: float) -> void:
	if not is_alive():
		return
	var destination := global_position + Vector2(-distance, GameRng.randf_range(-60.0, 60.0))
	destination.x = clampf(destination.x, 640.0, 1120.0)
	modulate.a = 0.25
	global_position = destination
	var tw := create_tween()
	tw.tween_property(self, "modulate:a", 1.0, 0.2)

func _current_era() -> String:
	var state := get_tree().root.get_node_or_null("/root/GameState")
	return String(state.current_era) if state != null else "prehistoric"

func _draw() -> void:
	var half := body_size * 0.5
	var bar_width := maxf(body_size + 24.0, BOSS_BAR_WIDTH if is_boss else 0.0)
	_draw_hp_bar(bar_width, -half - 30.0)

func _animate_actor(delta: float, walking: bool) -> void:
	if _sprite == null:
		return
	_walk_phase += delta * (9.0 if walking else 2.5)
	var stride := sin(_walk_phase)
	_sprite.position.y = -body_size * 0.5 + (absf(stride) * 3.5 if walking else sin(_walk_phase) * 1.0)
	_sprite.position.x = stride * (2.0 if walking else 0.4)
	_sprite.rotation = stride * (0.035 if walking else 0.01)
	if _shadow != null:
		_shadow.scale = Vector2(1.0 + absf(stride) * 0.07, 1.0 - absf(stride) * 0.05)
