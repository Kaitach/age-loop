class_name BaseBuilding
extends Combatant

const ERA_PROFILE = preload("res://scripts/progression/era_profile.gd")

const WIDTH := 340.0
const HEIGHT := 150.0

@export var base_max_health: int = 300
var _sprite: Sprite2D
var _era_id := "prehistoric"

func _ready() -> void:
	var wall_bonus := 0
	var bm := Engine.get_main_loop() as SceneTree
	if bm != null and bm.root.has_node("/root/BuildingManager"):
		wall_bonus = int(bm.root.get_node("/root/BuildingManager").get_bonus("base_health_bonus"))
	max_health = base_max_health + Upgrades.bonus_value("base_health") + wall_bonus
	super()
	add_to_group("base_fort")
	_era_id = _current_era()
	var shadow := GroundShadow.new()
	shadow.radius = 150.0
	shadow.position = Vector2(0, 0)
	add_child(shadow)
	_sprite = Sprite2D.new()
	_sprite.texture = load(ERA_PROFILE.get_asset(_era_id, "base")) as Texture2D
	_sprite.centered = true
	_sprite.position = Vector2(0, -75)
	_sprite.name = "BaseSprite"
	add_child(_sprite)

func set_era_visual(era_id: String) -> void:
	_era_id = era_id
	if _sprite == null:
		return
	var texture := load(ERA_PROFILE.get_asset(_era_id, "base")) as Texture2D
	if texture != null:
		_sprite.texture = texture
	queue_redraw()

func _current_era() -> String:
	var state := get_tree().root.get_node_or_null("/root/GameState")
	return String(state.current_era) if state != null else "prehistoric"

func _process(delta: float) -> void:
	super(delta)

func _on_death() -> void:
	queue_redraw()

func _draw() -> void:
	_draw_hp_bar(WIDTH + 80.0, -HEIGHT - 60.0)
