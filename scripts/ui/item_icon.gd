class_name ItemIcon
extends Control

## Icono procedural de un item. Mantiene el inventario data-driven sin obligar
## a crear un sprite distinto cada vez que se agrega un template nuevo.

var item: Dictionary = {}
var _rarity_color := Color(0.7, 0.71, 0.73)

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	custom_minimum_size = Vector2(92, 92)
	if not item.is_empty():
		_rarity_color = LootManager.get_rarity_color(String(item.get("rarity", "common")))
	queue_redraw()

func set_item(value: Dictionary) -> void:
	item = value.duplicate(true)
	if is_inside_tree():
		_rarity_color = LootManager.get_rarity_color(String(item.get("rarity", "common")))
		queue_redraw()

func _draw() -> void:
	var bounds := Rect2(Vector2(3, 3), Vector2(maxf(size.x, 92.0) - 6.0, maxf(size.y, 92.0) - 6.0))
	var card := StyleBoxFlat.new()
	card.bg_color = Color(0.035, 0.05, 0.085, 0.98)
	card.border_color = _rarity_color
	card.set_border_width_all(3)
	card.set_corner_radius_all(18)
	draw_style_box(card, bounds)

	var center := bounds.get_center()
	var slot := String(item.get("slot", "weapon"))
	var attack_range := _attack_range()
	var ink := _rarity_color.lightened(0.22)
	match slot:
		"weapon":
			if attack_range >= 160.0:
				_draw_bow(center, ink)
			else:
				_draw_melee_weapon(center, ink)
		"helmet":
			_draw_helmet(center, ink)
		"armor":
			_draw_armor(center, ink)
		"gloves":
			_draw_gloves(center, ink)
		"boots":
			_draw_boots(center, ink)
		"amulet":
			_draw_amulet(center, ink)
		_:
			draw_circle(center, 20.0, ink)

	var rarity := String(item.get("rarity", "common"))
	var stars := int(DataLoader.load_json("rarities/rarities.json").get(rarity, {}).get("modifiers", 0))
	for i in range(stars):
		draw_circle(Vector2(bounds.position.x + 15.0 + i * 12.0, bounds.end.y - 13.0), 3.0, _rarity_color)

func _attack_range() -> float:
	var stats: Dictionary = item.get("stats", {})
	if stats.has("attack_range"):
		return float(stats.get("attack_range", 0.0))
	return 0.0

func _draw_bow(center: Vector2, color: Color) -> void:
	draw_arc(center + Vector2(-4, 0), 27.0, -1.15, 1.15, 20, color, 7.0, true)
	draw_line(center + Vector2(-4, -25), center + Vector2(-4, 25), Color(0.95, 0.9, 0.72), 3.0)
	draw_line(center + Vector2(-4, 0), center + Vector2(28, 0), color, 4.0)
	draw_colored_polygon(PackedVector2Array([center + Vector2(28, 0), center + Vector2(18, -7), center + Vector2(18, 7)]), color)

func _draw_melee_weapon(center: Vector2, color: Color) -> void:
	var name := String(item.get("name", "")).to_lower()
	if name.contains("garrote") or name.contains("club"):
		draw_line(center + Vector2(-24, 20), center + Vector2(21, -22), Color(0.52, 0.31, 0.18), 10.0)
		draw_circle(center + Vector2(23, -24), 13.0, color)
		return
	draw_line(center + Vector2(-24, 24), center + Vector2(23, -23), Color(0.48, 0.28, 0.16), 7.0)
	draw_colored_polygon(PackedVector2Array([center + Vector2(12, -34), center + Vector2(34, -12), center + Vector2(29, -7), center + Vector2(7, -29)]), color)
	draw_line(center + Vector2(-25, 25), center + Vector2(-8, 8), Color(0.85, 0.68, 0.42), 5.0)

func _draw_helmet(center: Vector2, color: Color) -> void:
	draw_arc(center + Vector2(0, 6), 27.0, PI, TAU, 18, color, 9.0, true)
	draw_line(center + Vector2(-28, 7), center + Vector2(28, 7), color, 7.0)
	draw_line(center + Vector2(8, -21), center + Vector2(28, -3), color, 5.0)

func _draw_armor(center: Vector2, color: Color) -> void:
	var points := PackedVector2Array([
		center + Vector2(-22, -28), center + Vector2(22, -28),
		center + Vector2(31, 26), center + Vector2(0, 34),
		center + Vector2(-31, 26)
	])
	draw_colored_polygon(points, color.darkened(0.22))
	draw_polyline(PackedVector2Array([points[0], points[1], points[2], points[3], points[4], points[0]]), color, 5.0, true)
	draw_line(center + Vector2(0, -23), center + Vector2(0, 27), color, 3.0)

func _draw_gloves(center: Vector2, color: Color) -> void:
	draw_circle(center + Vector2(-18, 7), 14.0, color)
	draw_circle(center + Vector2(18, 7), 14.0, color)
	for x in [-25.0, -18.0, -11.0, 11.0, 18.0, 25.0]:
		draw_line(center + Vector2(x, -5), center + Vector2(x, -19), color, 4.0)

func _draw_boots(center: Vector2, color: Color) -> void:
	draw_line(center + Vector2(-22, -22), center + Vector2(-22, 16), color, 12.0)
	draw_line(center + Vector2(13, -22), center + Vector2(13, 16), color, 12.0)
	draw_line(center + Vector2(-31, 19), center + Vector2(-10, 19), color, 9.0)
	draw_line(center + Vector2(4, 19), center + Vector2(26, 19), color, 9.0)

func _draw_amulet(center: Vector2, color: Color) -> void:
	draw_arc(center + Vector2(0, -13), 20.0, PI + 0.25, TAU - 0.25, 18, Color(0.82, 0.72, 0.38), 5.0, true)
	draw_colored_polygon(PackedVector2Array([center + Vector2(0, -3), center + Vector2(16, 13), center + Vector2(0, 30), center + Vector2(-16, 13)]), color)
	draw_circle(center + Vector2(0, 13), 6.0, Color(1, 0.94, 0.67))
