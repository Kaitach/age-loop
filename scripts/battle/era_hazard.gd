class_name EraHazard
extends Node2D

var _mode := "strike"
var _kind := ""
var _target: Combatant
var _delay := 2.0
var _damage := 1
var _duration := 3.0
var _damage_per_second := 2.0
var _elapsed := 0.0
var _tick_left := 0.5
var _color := Color(1.0, 0.45, 0.2)

func setup_strike(kind: String, target: Combatant, delay: float, damage: int, color: Color) -> void:
	_mode = "strike"
	_kind = kind
	_target = target
	_delay = maxf(delay, 0.4)
	_damage = maxi(damage, 1)
	_color = color
	z_index = 12
	queue_redraw()

func setup_zone(duration: float, damage_per_second: float, color: Color) -> void:
	_mode = "zone"
	_duration = maxf(duration, 0.5)
	_damage_per_second = maxf(damage_per_second, 0.1)
	_color = color
	z_index = 11
	queue_redraw()

func _process(delta: float) -> void:
	_elapsed += delta
	if _mode == "strike":
		if _elapsed >= _delay:
			if is_instance_valid(_target) and _target.is_alive():
				_target.take_damage(_damage)
			queue_free()
	else:
		_tick_left -= delta
		if _tick_left <= 0.0:
			_tick_left = 0.5
			var player := get_tree().get_first_node_in_group("player") as Combatant
			if player != null and player.is_alive() and global_position.distance_to(player.global_position) <= 150.0:
				player.take_damage(maxi(1, int(round(_damage_per_second * 0.5))))
			var base := get_tree().get_first_node_in_group("base_fort") as Combatant
			if base != null and base.is_alive() and global_position.distance_to(base.global_position) <= 180.0:
				base.take_damage(maxi(1, int(round(_damage_per_second * 0.5))))
		if _elapsed >= _duration:
			queue_free()
	queue_redraw()

func _draw() -> void:
	var progress := clampf(_elapsed / (_delay if _mode == "strike" else _duration), 0.0, 1.0)
	if _mode == "strike":
		var pulse := 0.5 + sin(_elapsed * 7.0) * 0.5
		draw_circle(Vector2.ZERO, 75.0 + pulse * 10.0, Color(_color, 0.12))
		draw_arc(Vector2.ZERO, 65.0, 0.0, TAU, 40, Color(_color, 0.85), 7.0)
		draw_arc(Vector2.ZERO, 65.0, -PI * 0.5, -PI * 0.5 + TAU * progress, 32, Color.WHITE, 8.0)
		draw_line(Vector2(-28, -28), Vector2(28, 28), Color(_color, 0.82), 6.0)
		draw_line(Vector2(28, -28), Vector2(-28, 28), Color(_color, 0.82), 6.0)
	else:
		var fade := 0.52 + sin(_elapsed * 5.0) * 0.08
		draw_circle(Vector2.ZERO, 145.0, Color(_color, fade * 0.20))
		draw_arc(Vector2.ZERO, 145.0, 0.0, TAU, 48, Color(_color, fade), 6.0)
		for i in range(6):
			var angle := float(i) * TAU / 6.0 + _elapsed
			draw_circle(Vector2.from_angle(angle) * 105.0, 5.0, Color(_color, 0.9))
