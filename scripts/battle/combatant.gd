class_name Combatant
extends Node2D

signal damaged(amount: int)
signal died

@export var max_health: int = 100
var armor: float = 0.0
var damage_taken_multiplier: float = 1.0

var health: int = 0
var _flash_left: float = 0.0
var _dead: bool = false
var _status_effects: Dictionary = {}

func _ready() -> void:
	health = max_health

func is_alive() -> bool:
	return not _dead and health > 0

func apply_status(status_id: String, duration: float, strength: float = 0.0) -> void:
	if status_id.is_empty() or duration <= 0.0:
		return
	var current: Dictionary = _status_effects.get(status_id, {})
	_status_effects[status_id] = {
		"remaining": maxf(duration, float(current.get("remaining", 0.0))),
		"strength": strength if current.is_empty() else maxf(strength, float(current.get("strength", 0.0))),
	}
	queue_redraw()

func has_status(status_id: String) -> bool:
	return _status_effects.has(status_id)

func clear_status(status_id: String) -> void:
	if _status_effects.erase(status_id):
		queue_redraw()

func status_speed_multiplier() -> float:
	var multiplier := 1.0
	if _status_effects.has("slow"):
		multiplier *= clampf(float(_status_effects["slow"].get("strength", 1.0)), 0.05, 1.0)
	if _status_effects.has("haste"):
		multiplier *= maxf(float(_status_effects["haste"].get("strength", 1.0)), 1.0)
	return multiplier

func can_act() -> bool:
	return not _status_effects.has("stun")

func restore_health(amount: int) -> int:
	if _dead or amount <= 0:
		return 0
	var before := health
	health = mini(max_health, health + amount)
	queue_redraw()
	return health - before

func take_damage(amount: int) -> void:
	if _dead or amount <= 0:
		return
	if _status_effects.has("invulnerable"):
		return
	var reduced := int(round(float(amount) * maxf(damage_taken_multiplier, 0.0) * 100.0 / (100.0 + maxf(armor, 0.0))))
	if _status_effects.has("guard"):
		var guard: Dictionary = _status_effects["guard"]
		reduced = int(round(float(reduced) * (1.0 - clampf(float(guard.get("strength", 0.0)), 0.0, 0.95))))
		_status_effects.erase("guard")
	if _status_effects.has("shield"):
		var shield: Dictionary = _status_effects["shield"]
		var absorbed := mini(reduced, int(round(float(shield.get("strength", 0.0)))))
		reduced -= absorbed
		shield["strength"] = float(shield.get("strength", 0.0)) - absorbed
		if float(shield["strength"]) <= 0.0:
			_status_effects.erase("shield")
	health = maxi(health - maxi(reduced, 1), 0)
	_flash_left = 0.15
	queue_redraw()
	damaged.emit(amount)
	if health == 0:
		_dead = true
		died.emit()
		_on_death()

func _process(delta: float) -> void:
	var expired: Array[String] = []
	for status_id in _status_effects.keys():
		var status: Dictionary = _status_effects[status_id]
		status["remaining"] = float(status.get("remaining", 0.0)) - delta
		if status_id == "radiation":
			var tick_left := float(status.get("tick_left", 0.0)) - delta
			if tick_left <= 0.0:
				tick_left = 0.5
				take_damage(maxi(1, int(round(float(status.get("strength", 1.0)) * 0.5))))
			status["tick_left"] = tick_left
		if float(status.get("remaining", 0.0)) <= 0.0:
			expired.append(String(status_id))
	for status_id in expired:
		_status_effects.erase(status_id)
	if _flash_left > 0.0:
		_flash_left -= delta
		modulate = Color(1.0, 0.4, 0.4) if _flash_left > 0.0 else Color.WHITE

func _on_death() -> void:
	var tween := create_tween()
	tween.tween_property(self, "modulate:a", 0.0, 0.25)
	tween.parallel().tween_property(self, "scale", Vector2(0.6, 0.6), 0.25)
	tween.tween_callback(queue_free)

func _draw_hp_bar(width: float, y_offset: float) -> void:
	if _dead or health >= max_health or health <= 0:
		return
	var ratio := float(health) / float(max_health)
	draw_rect(Rect2(-width * 0.5 - 2.0, y_offset - 2.0, width + 4.0, 12.0), Color(0, 0, 0, 0.6))
	var fill_color := Color(0.35, 0.85, 0.3).lerp(Color(0.9, 0.25, 0.2), 1.0 - ratio)
	draw_rect(Rect2(-width * 0.5, y_offset, width * ratio, 8.0), fill_color)
