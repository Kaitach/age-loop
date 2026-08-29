class_name BattleBackdrop
extends Node2D

const GROUND_Y := 1380.0
var era_id := "prehistoric"
var _time := 0.0

func set_era(value: String) -> void:
	era_id = value
	queue_redraw()

func background_color() -> Color:
	return _palette().sky_dark

func ground_color() -> Color:
	return _palette().ground

func detail_color() -> Color:
	return _palette().horizon

func accent_color() -> Color:
	return _palette().accent

func _process(delta: float) -> void:
	_time += delta
	queue_redraw()

func _draw() -> void:
	var palette := _palette()
	var width := maxf(get_viewport().get_visible_rect().size.x, 1080.0)
	# Bandas de color: hacen que el campo respire y que cada era se sienta distinta.
	for i in range(5):
		var y := 220.0 + i * 190.0
		draw_rect(Rect2(0, y, width, 190), palette.sky_dark.lerp(palette.sky_light, float(i) / 5.0), true)

	_draw_atmosphere(palette, width)

	var hill_count := maxi(int(ceil(width / 190.0)) + 1, 7)
	for i in range(hill_count):
		var x := float(i * 190 - 80)
		var height := float(100 + (i % 3) * 48)
		var points := PackedVector2Array([
			Vector2(x, GROUND_Y), Vector2(x + 100, GROUND_Y - height),
			Vector2(x + 210, GROUND_Y),
		])
		draw_colored_polygon(points, palette.hill)

	# Línea de horizonte y carriles, que ayudan a leer el movimiento lateral.
	draw_rect(Rect2(0, GROUND_Y, width, 540), palette.ground, true)
	draw_line(Vector2(0, GROUND_Y), Vector2(width, GROUND_Y), palette.horizon, 8.0)
	for lane in range(1, 4):
		var y := GROUND_Y + lane * 105.0
		draw_line(Vector2(0, y), Vector2(width, y), Color(palette.horizon, 0.16), 2.0)

	for i in range(15):
		var x := fmod(float(i * 157) + _time * 7.0, width + 80.0) - 40.0
		var y := GROUND_Y + 22.0 + float((i * 37) % 250)
		draw_line(Vector2(x, y), Vector2(x + 18, y - 4), Color(palette.dirt, 0.45), 4.0)
	_draw_motif(palette, width)

func _draw_atmosphere(palette: Dictionary, width: float) -> void:
	var motif := String(palette.motif)
	var star_motifs := ["lightning", "atom", "grid", "circuit", "planet", "nebula", "quantum"]
	if motif in star_motifs:
		for i in range(34):
			var star_x := fmod(float(i * 137 + 53) + _time * float(3 + (i % 4)), width)
			var star_y := 255.0 + float((i * 83) % 920)
			var radius := 2.0 + float(i % 3)
			draw_circle(Vector2(star_x, star_y), radius, Color(palette.accent, 0.35 + float(i % 3) * 0.12))
	else:
		draw_circle(Vector2(width - 180.0, 285), 58.0, palette.sun)
		draw_circle(Vector2(width - 180.0, 285), 78.0, Color(palette.sun, 0.08))

func _draw_motif(palette: Dictionary, width: float) -> void:
	var accent: Color = palette.accent
	var soft := Color(accent, 0.24)
	var bright := Color(accent, 0.58)
	match String(palette.motif):
		"temple":
			for i in range(4):
				var x := 110.0 + i * 255.0
				draw_rect(Rect2(x, 930, 34, 300), Color(accent, 0.14), true)
				draw_rect(Rect2(x - 20, 910, 74, 24), soft, true)
				draw_colored_polygon(PackedVector2Array([Vector2(x - 30, 910), Vector2(x + 64, 910), Vector2(x + 48, 884), Vector2(x - 6, 884)]), soft)
		"fortress", "castle":
			var x := width * 0.73
			draw_rect(Rect2(x, 1010, 210, 370), Color(accent, 0.13), true)
			for i in range(3):
				draw_rect(Rect2(x - 14 + i * 76, 960, 48, 50), soft, true)
				draw_line(Vector2(x + 10 + i * 76, 960), Vector2(x + 10 + i * 76, 880), bright, 5.0)
				draw_colored_polygon(PackedVector2Array([Vector2(x - 8 + i * 76, 885), Vector2(x + 28 + i * 76, 895), Vector2(x - 8 + i * 76, 905)]), bright)
		"arches":
			for i in range(3):
				var x := 170.0 + i * 270.0
				draw_arc(Vector2(x, 1120), 92.0, PI, TAU, 24, Color(accent, 0.36), 14.0)
				draw_line(Vector2(x - 92, 1120), Vector2(x + 92, 1120), soft, 12.0)
		"factory":
			for i in range(3):
				var x := 130.0 + i * 300.0
				draw_rect(Rect2(x, 1040 - i * 28, 160, 340), Color(accent, 0.12), true)
				draw_rect(Rect2(x + 28, 870 - i * 28, 30, 190), soft, true)
				draw_circle(Vector2(x + 43, 850 - i * 28), 32.0, Color(accent, 0.10))
		"lightning":
			var bolt_x := width * 0.72
			var bolt := PackedVector2Array([Vector2(bolt_x, 300), Vector2(bolt_x - 48, 510), Vector2(bolt_x + 8, 490), Vector2(bolt_x - 38, 760)])
			draw_polyline(bolt, Color(accent, 0.58), 12.0)
			draw_polyline(bolt, Color(1, 1, 1, 0.25), 3.0)
		"atom":
			var center := Vector2(width * 0.76, 520)
			draw_circle(center, 22.0, bright)
			for rotation in [0.0, PI / 3.0, 2.0 * PI / 3.0]:
				draw_set_transform(center, rotation, Vector2.ONE)
				draw_arc(Vector2.ZERO, 120.0, 0.0, TAU, 36, Color(accent, 0.30), 8.0)
			draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
		"grid":
			for i in range(8):
				var x := float(i * 160)
				draw_line(Vector2(x, 300), Vector2(x, 1190), Color(accent, 0.13), 3.0)
			for i in range(6):
				var y := 360.0 + i * 150.0
				draw_line(Vector2(0, y), Vector2(width, y), Color(accent, 0.13), 3.0)
		"circuit":
			for i in range(6):
				var y := 360.0 + i * 145.0
				var x := float((i % 2) * 120)
				var path := PackedVector2Array([Vector2(x, y), Vector2(x + 150, y), Vector2(x + 205, y + 48), Vector2(x + 420, y + 48)])
				draw_polyline(path, Color(accent, 0.34), 6.0)
				draw_circle(path[-1], 12.0, bright)
		"planet":
			var planet := Vector2(width * 0.76, 520)
			draw_circle(planet, 108.0, Color(accent, 0.20))
			draw_circle(planet, 92.0, Color(accent, 0.30))
			draw_arc(planet, 145.0, 0.15, PI - 0.15, 40, Color(accent, 0.55), 12.0)
		"nebula":
			for i in range(4):
				var center := Vector2(width * (0.25 + i * 0.18), 500 + (i % 2) * 190)
				draw_circle(center, 90.0 + i * 25.0, Color(accent, 0.07))
				draw_arc(center, 105.0 + i * 20.0, 0.2, 2.7, 30, Color(accent, 0.30), 7.0)
		"quantum":
			var center := Vector2(width * 0.70, 550)
			draw_circle(center, 18.0, Color(1, 1, 1, 0.82))
			for i in range(5):
				draw_arc(center, 70.0 + i * 34.0, _time * (0.35 + i * 0.1), _time * (0.35 + i * 0.1) + PI * 1.45, 32, Color(accent, 0.20 + i * 0.06), 6.0)
				draw_circle(center + Vector2(cos(_time + i), sin(_time * 1.3 + i)) * (70.0 + i * 34.0), 8.0, bright)

func _palette() -> Dictionary:
	var fallback := {
		"sky_dark": Color(0.045, 0.07, 0.13), "sky_light": Color(0.13, 0.22, 0.32),
		"sun": Color(0.75, 0.87, 0.98), "hill": Color(0.08, 0.14, 0.18),
		"ground": Color(0.085, 0.12, 0.16), "horizon": Color(0.36, 0.55, 0.43),
		"dirt": Color(0.28, 0.35, 0.23), "accent": Color(0.35, 0.82, 0.45), "motif": "hills"
	}
	var era_data: Dictionary = DataLoader.load_json("eras/eras.json").get(era_id, {})
	var visual: Dictionary = era_data.get("visual", {})
	if visual.is_empty():
		return fallback
	return {
		"sky_dark": DataLoader.color_from_array(visual.get("sky_dark", []), fallback.sky_dark),
		"sky_light": DataLoader.color_from_array(visual.get("sky_light", []), fallback.sky_light),
		"sun": DataLoader.color_from_array(visual.get("sun", []), fallback.sun),
		"hill": DataLoader.color_from_array(visual.get("hill", []), fallback.hill),
		"ground": DataLoader.color_from_array(visual.get("ground", []), fallback.ground),
		"horizon": DataLoader.color_from_array(visual.get("horizon", []), fallback.horizon),
		"dirt": DataLoader.color_from_array(visual.get("dirt", []), fallback.dirt),
		"accent": DataLoader.color_from_array(visual.get("accent", []), fallback.accent),
		"motif": String(visual.get("motif", "hills"))
	}
