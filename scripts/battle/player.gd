class_name Player
extends Combatant

const BODY_RADIUS := 46.0

@export var base_damage: int = 14
@export var base_max_health: int = 100
@export var attack_speed: float = 1.2
@export var attack_range: float = 430.0
@export var projectile_speed: float = 720.0

signal critical_hit(target: Combatant, damage: int)

var damage: int = 14
var critical_chance: float = 0.05
var critical_damage: float = 1.5

var _attack_cooldown: float = 0.6
var _dying: bool = false

func _ready() -> void:
	var final_stats := StatsCalculator.player_final_stats(self)
	damage = int(round(float(final_stats["damage"])))
	max_health = int(round(float(final_stats["max_health"])))
	attack_speed = float(final_stats["attack_speed"])
	critical_chance = float(final_stats["critical_chance"])
	critical_damage = float(final_stats["critical_damage"])
	super()
	add_to_group("player")
	var spr := Sprite2D.new()
	spr.texture = load("res://assets/characters/player.png") as Texture2D
	spr.centered = true
	add_child(spr)

func _process(delta: float) -> void:
	super(delta)
	if _dying:
		return
	_attack_cooldown -= delta
	if _attack_cooldown > 0.0:
		return
	var target := _nearest_enemy()
	if target != null:
		_attack_cooldown = 1.0 / attack_speed
		_shoot(target)

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

func _shoot(target: Enemy) -> void:
	var projectile := Projectile.new()
	var hit_damage := damage
	var is_crit := randf() < critical_chance
	if is_crit:
		hit_damage = int(round(damage * critical_damage))
		critical_hit.emit(target, hit_damage)
		_play_sfx("critical")
	else:
		_play_sfx("hit")
	projectile.setup(global_position + Vector2(0, -34), target, hit_damage, projectile_speed)
	get_parent().add_child(projectile)

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
