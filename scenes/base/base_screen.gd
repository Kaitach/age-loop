extends Control

const MENU_SCENE := "res://scenes/menu/main_menu.tscn"

@onready var currency_label: Label = %CurrencyLabel
@onready var buildings_list: VBoxContainer = %BuildingsList
@onready var back_button: Button = %BackButton

var _row_refs: Dictionary = {}

func _ready() -> void:
	back_button.pressed.connect(func() -> void: get_tree().change_scene_to_file(MENU_SCENE))
	SignalBus.currency_changed.connect(_refresh_all)
	_refresh_all()

func _refresh_all() -> void:
	currency_label.text = "ORO %d    CIENCIA %d    MAT %d" % [GameState.gold, GameState.science, GameState.materials]
	_refresh_list()

func _refresh_list() -> void:
	for child in buildings_list.get_children():
		child.queue_free()
	_row_refs.clear()
	var buildings: Dictionary = DataLoader.load_json("buildings/buildings.json")
	for building_id in buildings.keys():
		var def: Dictionary = buildings[building_id]
		buildings_list.add_child(_make_row(building_id, def))

func _make_row(building_id: String, def: Dictionary) -> PanelContainer:
	var panel := PanelContainer.new()
	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 8)
	panel.add_child(vbox)
	var title := Label.new()
	title.add_theme_font_size_override("font_size", 42)
	title.text = "%s  Nv.%d" % [def.get("name", building_id), BuildingManager.get_level(building_id)]
	if BuildingManager.is_maxed(building_id):
		title.add_theme_color_override("font_color", Color(0.5, 0.55, 0.62))
	vbox.add_child(title)
	var prod := _production_text(building_id, def)
	if prod != "":
		var prod_label := Label.new()
		prod_label.add_theme_font_size_override("font_size", 30)
		prod_label.add_theme_color_override("font_color", Color(0.62, 0.68, 0.8))
		prod_label.text = prod
		vbox.add_child(prod_label)
	var next_label := Label.new()
	next_label.add_theme_font_size_override("font_size", 30)
	if BuildingManager.is_maxed(building_id):
		next_label.text = "Nivel maximo"
		next_label.add_theme_color_override("font_color", Color(0.5, 0.55, 0.62))
	else:
		var per_level: Dictionary = def.get("per_level", {})
		var parts: PackedStringArray = []
		for key in per_level.keys():
			parts.append("+%s %s" % [str(per_level[key]), key])
		next_label.text = "Siguiente: " + (", ".join(parts) if not parts.is_empty() else "—")
	vbox.add_child(next_label)
	if not BuildingManager.is_maxed(building_id):
		var cost := BuildingManager.get_cost(building_id)
		var cost_parts: PackedStringArray = []
		for cur in cost.keys():
			cost_parts.append("%d %s" % [int(cost[cur]), cur.to_upper()])
		var cost_label := Label.new()
		cost_label.add_theme_font_size_override("font_size", 30)
		cost_label.text = "Costo: " + ", ".join(cost_parts)
		vbox.add_child(cost_label)
		var btn := Button.new()
		btn.custom_minimum_size = Vector2(760, 96)
		btn.add_theme_font_size_override("font_size", 36)
		btn.text = "MEJORAR"
		btn.disabled = not BuildingManager.can_upgrade(building_id)
		btn.pressed.connect(func() -> void:
			if BuildingManager.upgrade(building_id):
				_refresh_all()
		)
		vbox.add_child(btn)
		_row_refs[building_id] = { "button": btn }
	return panel

func _production_text(building_id: String, def: Dictionary) -> String:
	var level := BuildingManager.get_level(building_id)
	if level == 0:
		return ""
	var per_level: Dictionary = def.get("per_level", {})
	var parts: PackedStringArray = []
	for key in per_level.keys():
		var total: float = float(per_level[key]) * level
		if key == "gold_per_min":
			parts.append("%d oro/min" % int(round(total)))
		elif key == "materials_per_min":
			parts.append("%d mat/min" % int(round(total)))
		elif key == "loot_bonus":
			parts.append("+%.0f%% loot" % (total * 100.0))
		elif key == "base_health_bonus":
			parts.append("+%d vida base" % int(round(total)))
		elif key == "max_units":
			parts.append("%d unidades max" % int(round(total)))
	if parts.is_empty():
		return ""
	return "Produccion: " + ", ".join(parts)
