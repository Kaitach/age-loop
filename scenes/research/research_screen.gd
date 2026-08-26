extends Control

const MENU_SCENE := "res://scenes/menu/main_menu.tscn"

var _selected_id := ""

@onready var currency_label: Label = %CurrencyLabel
@onready var active_panel: PanelContainer = %ActivePanel
@onready var active_name_label: Label = %ActiveNameLabel
@onready var active_progress: ProgressBar = %ActiveProgress
@onready var active_time_label: Label = %ActiveTimeLabel
@onready var cancel_button: Button = %CancelButton
@onready var eras_list: VBoxContainer = %ErasList
@onready var detail_panel: PanelContainer = %DetailPanel
@onready var detail_title: Label = %DetailTitle
@onready var detail_cost_label: Label = %DetailCostLabel
@onready var detail_time_label: Label = %DetailTimeLabel
@onready var detail_req_label: Label = %DetailReqLabel
@onready var detail_effect_label: Label = %DetailEffectLabel
@onready var research_button: Button = %ResearchButton
@onready var back_button: Button = %BackButton
@onready var completed_banner: Label = %CompletedBanner

var _tick_timer: Timer

func _ready() -> void:
	back_button.pressed.connect(func() -> void: get_tree().change_scene_to_file(MENU_SCENE))
	research_button.pressed.connect(_on_research_pressed)
	cancel_button.pressed.connect(_on_cancel_pressed)
	SignalBus.technology_completed.connect(_on_technology_completed)
	SignalBus.currency_changed.connect(_refresh_detail_button_state)
	_tick_timer = Timer.new()
	_tick_timer.wait_time = 1.0
	_tick_timer.autostart = true
	_tick_timer.timeout.connect(_tick_active)
	add_child(_tick_timer)
	_refresh_all()
	_tick_active()

func _refresh_all() -> void:
	_refresh_currency()
	_refresh_active_panel()
	_refresh_eras_list()
	_refresh_detail()

func _refresh_currency() -> void:
	currency_label.text = "ORO %d    CIENCIA %d    MAT %d" % [GameState.gold, GameState.science, GameState.materials]

func _refresh_active_panel() -> void:
	if not ResearchManager.is_researching():
		active_panel.visible = false
		return
	active_panel.visible = true
	var current: Dictionary = GameState.current_research
	var tech_id := String(current.get("technology_id", ""))
	var tech: Dictionary = DataLoader.load_json("technologies/technologies.json").get(tech_id, {})
	active_name_label.text = String(tech.get("name", tech_id))
	var duration := int(tech.get("duration_seconds", 0))
	var remaining := ResearchManager.get_remaining_seconds()
	active_progress.max_value = duration
	active_progress.value = duration - remaining
	active_time_label.text = _format_time(remaining)

func _tick_active() -> void:
	if ResearchManager.is_researching():
		_refresh_active_panel()
		_refresh_currency()

func _refresh_eras_list() -> void:
	for child in eras_list.get_children():
		child.queue_free()
	var eras: Dictionary = DataLoader.load_json("eras/eras.json")
	var techs: Dictionary = DataLoader.load_json("technologies/technologies.json")
	var ordered_eras: Array = eras.values()
	ordered_eras.sort_custom(func(a, b): return int(a.get("order", 99)) < int(b.get("order", 99)))
	for era in ordered_eras:
		var era_id := String(era.get("id", ""))
		var header := Label.new()
		header.text = String(era.get("name", era_id)).to_upper()
		header.add_theme_font_size_override("font_size", 52)
		header.add_theme_color_override("font_color", Color(0.9, 0.78, 0.4))
		header.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		eras_list.add_child(header)
		for tech_id in techs.keys():
			var tech: Dictionary = techs[tech_id]
			if String(tech.get("era", "")) != era_id:
				continue
			eras_list.add_child(_make_tech_row(String(tech_id), tech))

func _make_tech_row(tech_id: String, tech: Dictionary) -> Button:
	var btn := Button.new()
	btn.custom_minimum_size = Vector2(960, 92)
	btn.add_theme_font_size_override("font_size", 34)
	btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
	var completed := ResearchManager.is_completed(tech_id)
	var can := ResearchManager.can_start(tech_id)
	var status := ""
	var color := Color.WHITE
	if completed:
		status = "✓  "
		color = Color(0.3, 0.8, 0.35)
		btn.disabled = true
	elif bool(can["ok"]):
		status = "→  "
		color = Color(0.6, 0.82, 1.0)
	else:
		status = "🔒  "
		color = Color(0.55, 0.57, 0.62)
		btn.disabled = ResearchManager.is_researching()
	btn.text = status + String(tech.get("name", tech_id))
	btn.add_theme_color_override("font_color", color)
	btn.pressed.connect(func() -> void: _select_tech(tech_id))
	return btn

func _select_tech(tech_id: String) -> void:
	_selected_id = tech_id
	_refresh_detail()

func _refresh_detail() -> void:
	if _selected_id.is_empty():
		detail_panel.visible = false
		return
	detail_panel.visible = true
	var tech: Dictionary = DataLoader.load_json("technologies/technologies.json").get(_selected_id, {})
	detail_title.text = String(tech.get("name", _selected_id))
	var cost: Dictionary = tech.get("cost", {})
	var parts: PackedStringArray = []
	for key in cost.keys():
		parts.append("%d %s" % [int(cost[key]), key.to_upper()])
	detail_cost_label.text = "Costo: " + (", ".join(parts) if not parts.is_empty() else "Gratis")
	detail_time_label.text = "Tiempo: %s" % _format_time(int(tech.get("duration_seconds", 0)))
	var reqs: Array = tech.get("requirements", [])
	if reqs.is_empty():
		detail_req_label.text = "Requisitos: ninguno"
	else:
		detail_req_label.text = "Requisitos: " + ", ".join(reqs)
	var effects: Array = tech.get("effects", [])
	var eff_lines: PackedStringArray = []
	for eff in effects:
		eff_lines.append("%s: %s" % [eff.get("type", "?"), eff.get("value", "?")])
	detail_effect_label.text = "Efectos: " + (", ".join(eff_lines) if not eff_lines.is_empty() else "—")
	_refresh_detail_button_state()

func _refresh_detail_button_state() -> void:
	if _selected_id.is_empty():
		return
	var check := ResearchManager.can_start(_selected_id)
	research_button.disabled = not bool(check["ok"])
	research_button.text = "INVESTIGAR" if bool(check["ok"]) else String(check["reason"])

func _on_research_pressed() -> void:
	if ResearchManager.start_research(_selected_id):
		_refresh_all()

func _on_cancel_pressed() -> void:
	ResearchManager.cancel_current()
	_refresh_all()

func _on_technology_completed(technology_id: String) -> void:
	var tech: Dictionary = DataLoader.load_json("technologies/technologies.json").get(technology_id, {})
	completed_banner.text = "¡Investigación completada: %s!" % tech.get("name", technology_id)
	completed_banner.visible = true
	await get_tree().create_timer(3.0).timeout
	completed_banner.visible = false
	_refresh_all()

func _format_time(total_seconds: int) -> String:
	if total_seconds >= 60:
		return "%dm %ds" % [total_seconds / 60, total_seconds % 60]
	return "%ds" % total_seconds
