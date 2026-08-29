class_name JuiceBurst
extends Node2D

var title := ""
var subtitle := ""
var burst_color := Color.WHITE
var accent_color := Color(1.0, 0.75, 0.2)
var _elapsed := 0.0
var _particles: Array[Dictionary] = []

func setup(new_title: String, new_subtitle: String, new_color: Color, new_accent: Color) -> void:
	title = new_title
	subtitle = new_subtitle
	burst_color = new_color
	accent_color = new_accent
	_particles.clear()
	for i in range(14):
		var angle := -PI * 0.95 + float(i) / 13.0 * PI * 1.9
		_particles.append({
			"angle": angle,
			"distance": 55.0 + float((i * 31) % 65),
			"size": 5.0 + float(i % 4) * 2.0,
			"speed": 0.82 + float(i % 3) * 0.1,
		})
	queue_redraw()

func _ready() -> void:
	z_index = 30
	scale = Vector2(0.55, 0.55)
	modulate.a = 0.0
	var tw := create_tween().set_parallel(true)
	tw.tween_property(self, "scale", Vector2.ONE, 0.24).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_property(self, "modulate:a", 1.0, 0.10)

func _process(delta: float) -> void:
	_elapsed += delta
	queue_redraw()
	if _elapsed > 0.92:
		queue_free()
	else:
		modulate.a = 1.0 - maxf((_elapsed - 0.55) / 0.37, 0.0)

func _draw() -> void:
	var progress := clampf(_elapsed / 0.92, 0.0, 1.0)
	var fade := 1.0 - progress
	var ring_radius := 28.0 + progress * 92.0
	draw_circle(Vector2.ZERO, ring_radius, Color(accent_color, 0.07 * fade))
	draw_arc(Vector2.ZERO, ring_radius, -PI, PI, 40, Color(accent_color, 0.75 * fade), 7.0)
	draw_circle(Vector2.ZERO, 16.0 * (1.0 - progress * 0.35), Color(burst_color, 0.82 * fade))
	for particle in _particles:
		var distance: float = float(particle.distance) + progress * 115.0 * float(particle.speed)
		var point := Vector2.from_angle(float(particle.angle)) * distance
		var particle_color := Color(accent_color, 0.9 * fade)
		draw_line(point - Vector2.from_angle(float(particle.angle)) * 16.0, point, particle_color, 5.0)
		draw_circle(point, float(particle.size) * (1.0 - progress * 0.35), particle_color)

	var font := ThemeDB.fallback_font
	if font != null and not title.is_empty():
		draw_string(font, Vector2(-220, -104 - progress * 24.0), title, HORIZONTAL_ALIGNMENT_CENTER, 440.0, 40, Color(1, 1, 1, 0.96 * fade))
	if font != null and not subtitle.is_empty():
		draw_string(font, Vector2(-220, -62 - progress * 24.0), subtitle, HORIZONTAL_ALIGNMENT_CENTER, 440.0, 24, Color(accent_color, 0.95 * fade))
