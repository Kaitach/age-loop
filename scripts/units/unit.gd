class_name AllyUnit
extends Combatant

var damage: int = 10
var attack_speed: float = 1.0
var attack_range: float = 360.0

var _attack_cd: float = 0.0
var _type: String = "archer"

func setup(unit_id: String) -> void:
	_type = unit_id
	match unit_id:
		"archer":
			damage = 11
			attack_speed = 1.0
			attack_range = 400.0
			max_health = 70
			body_color = Color(0.3, 0.6, 0.85)
		"heavy":
			damage = 16
			attack_speed = 0.7
			attack_range = 110.0
			max_health = 120
			body_color = Color(0.55, 0.55, 0.65)
		"crossbow":
			damage = 20
			attack_speed = 0.8
			attack_range = 460.0
			max_health = 80
			body_color = Color(0.65, 0.5, 0.3)

var body_color: Color = Color(0.3, 0.6, 0.85)
var body_size: float = 58.0

func _ready() -> void:
	super()
	add_to_group("allies")
	var spr := Sprite2D.new()
	var path := "res://assets/units/%s.png" % _type
	if ResourceLoader.exists(path):
		spr.texture = load(path) as Texture2D
	else:
		spr.texture = load("res://assets/units/archer.png") as Texture2D
	spr.centered = true
	add_child(spr)

func _process(delta: float) -> void:
	super(delta)
	if _dying:
		return
	_attack_cd -= delta
	if _attack_cd > 0.0:
		return
	var target := _nearest_enemy()
	if target != null:
		_attack_cd = 1.0 / attack_speed
		_shoot(target)

var _dying: bool = false
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

func _shoot(target: Enemy) -> void:
	var p := Projectile.new()
	p.setup(global_position + Vector2(0, -20), target, damage, 700.0)
	get_parent().add_child(p)

func _draw() -> void:
	var half := body_size * 0.5
	_draw_hp_bar(body_size + 16, -half - 22)
