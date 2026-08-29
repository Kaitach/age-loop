extends Control

const MENU_SCENE := "res://scenes/menu/main_menu.tscn"
const PREMIUM_STYLE = preload("res://scripts/ui/premium_style.gd")

@onready var currency_label: Label = %CurrencyLabel
@onready var buildings_list: VBoxContainer = %BuildingsList
@onready var back_button: Button = %BackButton
@onready var hint_label: Label = %HintLabel

var _row_refs: Dictionary = {}

func _ready() -> void:
	_configure_responsive_layout()
	_apply_premium_skin()
	back_button.pressed.connect(func() -> void: get_tree().change_scene_to_file(MENU_SCENE))
	SignalBus.currency_changed.connect(_refresh_all)
	_refresh_all()

func _configure_responsive_layout() -> void:
	var visible_rect := get_viewport().get_visible_rect()
	var content_width := minf(920.0, maxf(visible_rect.size.x - 80.0, 640.0))
	var main_vbox := $MainVBox as Control
	main_vbox.set_anchors_preset(Control.PRESET_TOP_LEFT)
	main_vbox.position = Vector2(visible_rect.position.x + (visible_rect.size.x - content_width) * 0.5, visible_rect.position.y + 40.0)
	main_vbox.size = Vector2(content_width, maxf(visible_rect.size.y - 80.0, 1200.0))

func _apply_premium_skin() -> void:
	PREMIUM_STYLE.style_button(back_button, "blue")
	PREMIUM_STYLE.style_title($MainVBox/Title, 64)

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		get_tree().change_scene_to_file(MENU_SCENE)

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
	PREMIUM_STYLE.style_panel(panel, Color(0.35, 0.75, 0.45, 1.0))
	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 8)
	panel.add_child(vbox)
	var era_strip := ColorRect.new()
	era_strip.custom_minimum_size = Vector2(0, 18)
	era_strip.color = _era_color(GameState.current_era)
	vbox.add_child(era_strip)
	var title := Label.new()
	title.add_theme_font_size_override("font_size", 42)
	title.text = "%s  Nv.%d" % [def.get("name", building_id), BuildingManager.get_level(building_id)]
	if not BuildingManager.is_unlocked(building_id):
		title.text = "🔒 " + title.text
		title.add_theme_color_override("font_color", Color(0.5, 0.55, 0.62))
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
	if not BuildingManager.is_unlocked(building_id):
		var locked := Label.new()
		locked.add_theme_font_size_override("font_size", 30)
		locked.text = "Requiere: " + BuildingManager.unlock_requirement(building_id)
		locked.add_theme_color_override("font_color", Color(1.0, 0.72, 0.3))
		vbox.add_child(locked)
		return panel
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
		PREMIUM_STYLE.style_button(btn, "green")
		btn.custom_minimum_size = Vector2(760, 96)
		btn.add_theme_font_size_override("font_size", 36)
		btn.text = "MEJORAR"
		btn.disabled = not BuildingManager.can_upgrade(building_id)
		btn.pressed.connect(func() -> void:
			if BuildingManager.upgrade(building_id):
				_refresh_all()
				if TutorialManager.show_once("first_building"):
					_show_context_hint("Tu primer edificio ya produce beneficios. Volvé a mejorarlo cuando tengas recursos.")
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

func _era_color(era_id: String) -> Color:
	match era_id:
		"prehistoric": return Color(0.55, 0.36, 0.2)
		"bronze": return Color(0.78, 0.52, 0.2)
		"iron": return Color(0.42, 0.5, 0.62)
		_: return Color(0.35, 0.4, 0.5)

func _show_context_hint(message: String) -> void:
	hint_label.text = message
	hint_label.visible = true
	var tw := create_tween()
	tw.tween_interval(4.0)
	tw.tween_callback(func() -> void:
		if is_instance_valid(hint_label):
			hint_label.visible = false
)
