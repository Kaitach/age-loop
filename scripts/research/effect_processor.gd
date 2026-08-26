class_name EffectProcessor
extends RefCounted

static func apply(effects: Array) -> void:
	for effect in effects:
		var type := String(effect.get("type", ""))
		match type:
			"unlock_era":
				var era_id := String(effect.get("value", ""))
				if not GameState.current_era == era_id:
					GameState.current_era = era_id
					SignalBus.era_changed.emit(era_id)
			"unlock_item", "unlock_building":
				pass
			"stat_multiplier":
				pass
			_:
				push_warning("[EFFECT] Tipo desconocido: %s" % type)
