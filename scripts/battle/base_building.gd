class_name BaseBuilding
extends Combatant

const WIDTH := 340.0
const HEIGHT := 150.0

@export var base_max_health: int = 300

func _ready() -> void:
	var wall_bonus := 0
	var bm := Engine.get_main_loop() as SceneTree
	if bm != null and bm.root.has_node("/root/BuildingManager"):
		wall_bonus = int(bm.root.get_node("/root/BuildingManager").get_bonus("base_health_bonus"))
	max_health = base_max_health + Upgrades.bonus_value("base_health") + wall_bonus
	super()
	add_to_group("base_fort")
	var spr := Sprite2D.new()
	spr.texture = load("res://assets/buildings/base.png") as Texture2D
	spr.centered = true
	spr.position = Vector2(0, -75)
	add_child(spr)

func _process(delta: float) -> void:
	super(delta)

func _on_death() -> void:
	queue_redraw()

func _draw() -> void:
	_draw_hp_bar(WIDTH + 80.0, -HEIGHT - 60.0)
