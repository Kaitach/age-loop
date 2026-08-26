class_name Enemy
extends Combatant

const ENGAGE_RANGE := 400.0
const BODY_SIZE := 72.0

@export var damage: int = 7
@export var movement_speed: float = 110.0
@export var attack_speed: float = 1.0
@export var attack_range: float = 95.0
@export var body_color: Color = Color(0.86, 0.28, 0.25)

var _target: Combatant
var _attack_cooldown: float = 0.0
var _dying: bool = false

func _ready() -> void:
	super()
	add_to_group("enemies")

func _process(delta: float) -> void:
	super(delta)
	if _dying:
		return
	_acquire_target()
	if _target == null or not is_instance_valid(_target) or not _target.is_alive():
		return
	var dist := global_position.distance_to(_target.global_position)
	if dist > attack_range:
		global_position += (_target.global_position - global_position).normalized() * movement_speed * delta
	else:
		_attack_cooldown -= delta
		if _attack_cooldown <= 0.0:
			_attack_cooldown = 1.0 / attack_speed
			_target.take_damage(damage)
			queue_redraw()

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

func _draw() -> void:
	var body := Rect2(-BODY_SIZE * 0.5, -BODY_SIZE * 0.5, BODY_SIZE, BODY_SIZE)
	draw_rect(body, body_color)
	draw_rect(body, body_color.darkened(0.4), false, 5.0)
	draw_rect(Rect2(-22, -18, 14, 14), Color(1, 1, 1))
	draw_rect(Rect2(8, -18, 14, 14), Color(1, 1, 1))
	draw_rect(Rect2(-16, 12, 32, 8), Color(0.2, 0.05, 0.05))
	_draw_hp_bar(BODY_SIZE + 24, -BODY_SIZE * 0.5 - 26.0)
