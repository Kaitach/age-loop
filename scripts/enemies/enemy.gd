class_name Enemy
extends Combatant

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
var reward_gold := 0
var reward_science := 0
var reward_materials := 0

var _target: Combatant
var _attack_cooldown: float = 0.0
var _dying: bool = false
var _summon_cd: float = 7.0
var _enraged: bool = false

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
	var rewards: Dictionary = data.get("rewards", {})
	reward_gold = int(rewards.get("gold", 0))
	reward_science = int(rewards.get("science", 0))
	reward_materials = int(rewards.get("materials", 0))

func _ready() -> void:
	super()
	add_to_group("enemies")
	_add_sprite()

func _process(delta: float) -> void:
	super(delta)
	if _dying:
		return
	if enemy_id == "boss_chief" and is_boss:
		_summon_cd -= delta
		if _summon_cd <= 0.0:
			_summon_cd = 8.0
			_spawn_minions()
	if enemy_id == "berserker" and health < max_health * 0.4 and not _enraged:
		_enraged = true
		movement_speed *= 1.7
		attack_speed *= 1.3
		modulate = Color(1.2, 0.5, 0.5)
	if enemy_id == "boss_iron_general" and health < max_health * 0.5 and not _enraged:
		_enraged = true
		attack_speed *= 1.6
		body_color = body_color.darkened(0.15)
		queue_redraw()
	_acquire_target()
	if _target == null or not is_instance_valid(_target) or not _target.is_alive():
		return
	var dist := global_position.distance_to(_target.global_position)
	var eff_speed := movement_speed
	if dist > attack_range:
		global_position += (_target.global_position - global_position).normalized() * eff_speed * delta
	else:
		_attack_cooldown -= delta
		if _attack_cooldown <= 0.0:
			_attack_cooldown = 1.0 / attack_speed
			_target.take_damage(damage)
			queue_redraw()

func _spawn_minions() -> void:
	var parent_node := get_parent()
	if parent_node == null:
		return
	for i in range(2):
		var m := Enemy.new()
		m.setup_from_data("fast", WaveManager.get_enemy_data("fast"), 1.0, 1.0)
		m.position = position + Vector2(randf_range(-80, 80), randf_range(-40, 40))
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
	var path := "res://assets/enemies/%s.png" % enemy_id
	if not ResourceLoader.exists(path):
		path = "res://assets/enemies/normal.png"
	var tex = load(path) as Texture2D
	if tex == null:
		return
	var spr := Sprite2D.new()
	spr.texture = tex
	spr.centered = true
	add_child(spr)

func _draw() -> void:
	var half := body_size * 0.5
	var bar_width := maxf(body_size + 24.0, BOSS_BAR_WIDTH if is_boss else 0.0)
	_draw_hp_bar(bar_width, -half - 30.0)
