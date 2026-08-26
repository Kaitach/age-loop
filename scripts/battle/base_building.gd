class_name BaseBuilding
extends Combatant

const WIDTH := 340.0
const HEIGHT := 150.0

func _ready() -> void:
	super()
	add_to_group("base_fort")

func _process(delta: float) -> void:
	super(delta)

func _on_death() -> void:
	queue_redraw()

func _draw() -> void:
	var alive := is_alive()
	var wall_color := Color(0.52, 0.56, 0.65) if alive else Color(0.3, 0.31, 0.34)
	var top_y := -HEIGHT
	draw_rect(Rect2(-WIDTH * 0.5, top_y, WIDTH, HEIGHT), wall_color)
	for i in range(4):
		var x := -WIDTH * 0.5 + i * (WIDTH / 4.0) + 10.0
		draw_rect(Rect2(x, top_y - 26.0, WIDTH / 4.0 - 20.0, 26.0), wall_color.darkened(0.15))
	draw_rect(Rect2(-34, -64, 68, 64), Color(0.16, 0.13, 0.1))
	draw_line(Vector2(WIDTH * 0.5 - 30, top_y - 26.0), Vector2(WIDTH * 0.5 - 30, top_y - 110.0), Color(0.35, 0.3, 0.25), 6.0)
	var flag_color := Color(0.9, 0.72, 0.25) if alive else Color(0.45, 0.42, 0.38)
	draw_colored_polygon(PackedVector2Array([Vector2(WIDTH * 0.5 - 30, top_y - 110.0), Vector2(WIDTH * 0.5 - 90, top_y - 92.0), Vector2(WIDTH * 0.5 - 30, top_y - 74.0)]), flag_color)
	_draw_hp_bar(WIDTH + 80.0, top_y - 60.0)
