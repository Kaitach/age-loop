class_name EraTransitionOverlay
extends Control

signal midpoint_reached
signal transition_finished

var _old_name := ""
var _new_name := ""
var _accent := Color(0.35, 0.82, 0.45)
var _elapsed := 0.0
var _duration := 2.6
var _active := false
var _tween: Tween
var _particles: Array[Dictionary] = []

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	visible = false
	process_mode = Node.PROCESS_MODE_ALWAYS

func play(old_name: String, new_name: String, accent: Color, duration: float = 2.6) -> void:
	if _tween != null and _tween.is_valid():
		_tween.kill()
	_old_name = old_name
	_new_name = new_name
	_accent = accent
	_duration = maxf(duration, 1.6)
	_elapsed = 0.0
	_active = true
	visible = true
	modulate.a = 0.0
	scale = Vector2(0.96, 0.96)
	_particles.clear()
	for i in range(36):
		_particles.append({
			"angle": float(i) / 36.0 * TAU,
			"radius": 260.0 + float((i * 47) % 260),
			"speed": 0.5 + float(i % 5) * 0.12,
			"size": 3.0 + float(i % 4) * 2.0,
		})
	queue_redraw()
	_tween = create_tween()
	_tween.tween_property(self, "modulate:a", 1.0, 0.25)
	_tween.parallel().tween_property(self, "scale", Vector2.ONE, 0.42).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_tween.tween_interval(_duration * 0.38)
	_tween.tween_callback(midpoint_reached.emit)
	_tween.tween_interval(_duration * 0.42)
	_tween.tween_property(self, "modulate:a", 0.0, 0.42)
	_tween.tween_callback(_finish)
	set_process(true)

func is_active() -> bool:
	return _active

func _process(delta: float) -> void:
	if not _active:
		return
	_elapsed += delta
	queue_redraw()

func _finish() -> void:
	_active = false
	visible = false
	set_process(false)
	transition_finished.emit()

func _draw() -> void:
	var viewport_size := get_viewport_rect().size
	if viewport_size.x <= 0.0 or viewport_size.y <= 0.0:
		return
	var center := viewport_size * 0.5
	var pulse := 0.5 + 0.5 * sin(_elapsed * 4.2)
	draw_rect(Rect2(Vector2.ZERO, viewport_size), Color(0.008, 0.012, 0.03, 0.94))
	draw_circle(center, 235.0 + pulse * 22.0, Color(_accent, 0.08))
	draw_circle(center, 150.0 + pulse * 14.0, Color(_accent, 0.12))
	draw_arc(center, 190.0 + pulse * 20.0, 0.0, TAU, 64, Color(_accent, 0.7), 5.0)
	for particle in _particles:
		var angle := float(particle["angle"]) + _elapsed * float(particle["speed"])
		var radius := float(particle["radius"]) + sin(_elapsed * 2.0 + angle) * 35.0
		var point := center + Vector2.from_angle(angle) * radius
		draw_circle(point, float(particle["size"]), Color(_accent, 0.35 + pulse * 0.4))

	var font := ThemeDB.fallback_font
	if font == null:
		return
	var title_y := center.y - 150.0
	draw_string(font, Vector2(80.0, title_y), "NUEVA ERA", HORIZONTAL_ALIGNMENT_CENTER, viewport_size.x - 160.0, 52, Color(0.95, 0.78, 0.35, 0.98))
	draw_string(font, Vector2(80.0, title_y + 82.0), _new_name.to_upper(), HORIZONTAL_ALIGNMENT_CENTER, viewport_size.x - 160.0, 76, Color(0.95, 0.97, 1.0, 0.98))
	draw_string(font, Vector2(80.0, title_y + 143.0), "LA HISTORIA VUELVE A NACER", HORIZONTAL_ALIGNMENT_CENTER, viewport_size.x - 160.0, 25, Color(_accent, 0.95))
	if not _old_name.is_empty():
		draw_string(font, Vector2(80.0, center.y + 190.0), "%s  →  %s" % [_old_name.to_upper(), _new_name.to_upper()], HORIZONTAL_ALIGNMENT_CENTER, viewport_size.x - 160.0, 24, Color(0.68, 0.73, 0.85, 0.8))
