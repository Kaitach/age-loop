class_name Pet
extends Combatant

const ERA_PROFILE = preload("res://scripts/progression/era_profile.gd")

var pet_id := "wolf"
var pet_name := "Lobo compañero"
var level := 1
var damage := 13
var attack_speed := 1.15
var attack_range := 92.0
var movement_speed := 205.0
var body_size := 78.0

var _attack_cooldown := 0.0
var _walk_phase := 0.0
var _base_y := 0.0
var _dying := false
var _sprite: Sprite2D
var _shadow: GroundShadow
var _era_id := "prehistoric"

func setup_from_data(pet_id_p: String, data: Dictionary, level_p: int, era_id_p: String) -> void:
	pet_id = pet_id_p
	pet_name = String(data.get("name", pet_id_p))
	level = maxi(level_p, 1)
	damage = int(data.get("base_damage", 13)) + (level - 1) * int(data.get("level_damage", 2))
	max_health = int(data.get("base_health", 120)) + (level - 1) * int(data.get("level_health", 10))
	attack_speed = float(data.get("attack_speed", 1.15))
	attack_range = float(data.get("attack_range", 92.0))
	movement_speed = float(data.get("movement_speed", 205.0)) + (level - 1) * float(data.get("level_speed", 0.7))
	body_size = float(data.get("body_size", 78.0))
	_era_id = era_id_p if not era_id_p.is_empty() else "prehistoric"

func _ready() -> void:
	super()
	add_to_group("pets")
	_base_y = position.y
	_walk_phase = GameRng.randf() * TAU
	_shadow = GroundShadow.new()
	_shadow.radius = body_size * 0.54
	add_child(_shadow)
	_sprite = Sprite2D.new()
	_sprite.name = "Sprite"
	_sprite.centered = true
	_sprite.scale = Vector2.ONE * 1.18
	_sprite.position = Vector2(0, -body_size * 0.5)
	add_child(_sprite)
	refresh_visual()

func set_era_visual(era_id: String) -> void:
	_era_id = era_id if not era_id.is_empty() else "prehistoric"
	refresh_visual()

func refresh_visual() -> void:
	if _sprite == null:
		return
	var texture := load(ERA_PROFILE.get_asset(_era_id, "pet", pet_id)) as Texture2D
	if texture != null:
		_sprite.texture = texture
	queue_redraw()

func _process(delta: float) -> void:
	var battle_state := get_tree().root.get_node_or_null("/root/GameState")
	if battle_state != null:
		delta *= float(battle_state.battle_speed)
	super(delta)
	if _dying or not can_act():
		return
	delta *= status_speed_multiplier()
	position.y = _base_y
	_attack_cooldown -= delta
	var target := _nearest_enemy()
	var walking := false
	if target != null:
		var distance := global_position.distance_to(target.global_position)
		if distance > attack_range + target.body_size * 0.35:
			var destination_x := target.global_position.x - attack_range
			position.x = move_toward(position.x, clampf(destination_x, 300.0, 950.0), movement_speed * delta)
			walking = true
		elif _attack_cooldown <= 0.0:
			_attack_cooldown = 1.0 / maxf(attack_speed, 0.1)
			target.take_damage(damage)
			_bite(target)
	_animate_actor(delta, walking)

func _nearest_enemy() -> Enemy:
	var best: Enemy = null
	var best_distance := INF
	for node in get_tree().get_nodes_in_group("enemies"):
		var enemy := node as Enemy
		if enemy == null or not enemy.is_alive():
			continue
		var distance := global_position.distance_squared_to(enemy.global_position)
		if distance < best_distance:
			best_distance = distance
			best = enemy
	return best

func _bite(target: Enemy) -> void:
	if target == null or not is_instance_valid(target):
		return
	var tw := create_tween()
	var start := position
	var direction := (target.global_position - global_position).normalized()
	tw.tween_property(self, "position", start + direction * 12.0, 0.08)
	tw.tween_property(self, "position", start, 0.13)

func _animate_actor(delta: float, walking: bool) -> void:
	if _sprite == null:
		return
	_walk_phase += delta * (10.0 if walking else 2.8)
	var stride := sin(_walk_phase)
	_sprite.position.y = -body_size * 0.5 + (absf(stride) * 4.0 if walking else sin(_walk_phase) * 1.5)
	_sprite.position.x = stride * (2.5 if walking else 0.6)
	_sprite.rotation = stride * (0.05 if walking else 0.014)
	if _shadow != null:
		_shadow.scale = Vector2(1.0 + absf(stride) * 0.1, 1.0 - absf(stride) * 0.06)

func _on_death() -> void:
	_dying = true
	remove_from_group("pets")
	super()

func _draw() -> void:
	_draw_hp_bar(body_size + 26.0, -body_size * 0.5 - 28.0)
	if not _dying:
		draw_circle(Vector2(0, -body_size * 0.5 - 42.0), 5.0, ERA_PROFILE.get_transition_color(_era_id))
