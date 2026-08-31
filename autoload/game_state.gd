extends Node

var gold: int = 0
var science: int = 0
var materials: int = 0
var crystals: int = 0

var world: int = 1
var wave: int = 1

var current_era: String = "prehistoric"
var future_era_preview: String = "medieval"

var inventory: Array = []
var pending_items: Array = []
var equipped_items: Dictionary = {}
var equipment_presets: Dictionary = {}
var active_pet_id: String = "wolf"
var pet_levels: Dictionary = {"wolf": 1}
var buildings: Dictionary = {}
var technologies: Dictionary = {}
var upgrades: Dictionary = {}
var effect_modifiers: Dictionary = {}
var effect_additions: Dictionary = {}
var unlocked_items: Dictionary = {}
var unlocked_buildings: Dictionary = {}
var unlocked_units: Dictionary = {}

var current_research = null
var pending_notifications: Array = []

var stats: Dictionary = {
	"enemies_killed": 0,
	"bosses_killed": 0,
	"waves_completed": 0,
}

var tutorial_flags: Dictionary = {}
var settings: Dictionary = {
	"music_enabled": true,
	"sfx_enabled": true,
	"vibration_enabled": true,
	"music_volume": 1.0,
	"sfx_volume": 1.0,
}

var last_played_at: int = 0
var battle_speed: float = 1.0

func get_effect_modifier(effect_id: String) -> float:
	return float(effect_modifiers.get(effect_id, 0.0))

func get_effect_addition(effect_id: String) -> float:
	return float(effect_additions.get(effect_id, 0.0))

func has_unlocked_content(content_type: String, content_id: String) -> bool:
	var content = get("unlocked_%s" % content_type)
	if not (content is Dictionary):
		return false
	return bool(content.get(content_id, false))
