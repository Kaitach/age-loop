extends Control

const MENU_SCENE := "res://scenes/menu/main_menu.tscn"
const PREMIUM_STYLE = preload("res://scripts/ui/premium_style.gd")

var _selected_id := ""

@onready var currency_label: Label = %CurrencyLabel
@onready var active_panel: PanelContainer = %ActivePanel
@onready var active_name_label: Label = %ActiveNameLabel
@onready var active_progress: ProgressBar = %ActiveProgress
@onready var active_time_label: Label = %ActiveTimeLabel
@onready var cancel_button: Button = %CancelButton
@onready var accelerate_button: Button = %AccelerateButton
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
	_configure_responsive_layout()
	_apply_premium_skin()
	back_button.pressed.connect(func() -> void: get_tree().change_scene_to_file(MENU_SCENE))
	research_button.pressed.connect(_on_research_pressed)
	cancel_button.pressed.connect(_on_cancel_pressed)
	accelerate_button.pressed.connect(_on_accelerate_pressed)
	SignalBus.technology_completed.connect(_on_technology_completed)
	SignalBus.era_changed.connect(_on_era_changed)
	SignalBus.currency_changed.connect(_refresh_detail_button_state)
	_tick_timer = Timer.new()
	_tick_timer.wait_time = 1.0
	_tick_timer.autostart = true
	_tick_timer.timeout.connect(_tick_active)
	add_child(_tick_timer)
	_refresh_all()
	_tick_active()

func _configure_responsive_layout() -> void:
	var visible_rect := get_viewport().get_visible_rect()
	var content_width := minf(920.0, maxf(visible_rect.size.x - 80.0, 640.0))
	var main_vbox := $MainVBox as Control
	main_vbox.set_anchors_preset(Control.PRESET_TOP_LEFT)
	main_vbox.position = Vector2(visible_rect.position.x + (visible_rect.size.x - content_width) * 0.5, visible_rect.position.y + 40.0)
	main_vbox.size = Vector2(content_width, maxf(visible_rect.size.y - 80.0, 1200.0))

func _apply_premium_skin() -> void:
	PREMIUM_STYLE.style_button(back_button, "blue")
	PREMIUM_STYLE.style_button(cancel_button, "brown")
	PREMIUM_STYLE.style_button(accelerate_button, "gold")
	PREMIUM_STYLE.style_button(research_button, "green")
	PREMIUM_STYLE.style_panel(active_panel)
	PREMIUM_STYLE.style_panel(detail_panel)
	PREMIUM_STYLE.style_title($MainVBox/Title, 64)

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		get_tree().change_scene_to_file(MENU_SCENE)

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
	var duration := int(current.get("duration_seconds", 0))
	var name := "Investigación"
	if String(current.get("research_type", "technology")) == "era":
		var era: Dictionary = DataLoader.load_json("eras/eras.json").get(String(current.get("era_id", "")), {})
		name = "Avance: %s" % String(era.get("name", current.get("era_id", "")))
	else:
		var tech_id := String(current.get("technology_id", ""))
		var tech: Dictionary = DataLoader.load_json("technologies/technologies.json").get(tech_id, {})
		name = String(tech.get("name", tech_id))
	active_name_label.text = name
	var remaining := ResearchManager.get_remaining_seconds()
	active_progress.max_value = duration
	active_progress.value = duration - remaining
	active_time_label.text = _format_time(remaining)
	accelerate_button.text = "ACELERAR (%d CRISTAL%s)" % [ResearchManager.get_accelerate_cost(), "" if ResearchManager.get_accelerate_cost() == 1 else "ES"]
	accelerate_button.disabled = GameState.crystals < ResearchManager.get_accelerate_cost()

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
		var next_era_id := _next_era_id(era_id)
		if not next_era_id.is_empty():
			eras_list.add_child(_make_era_row(next_era_id, eras[next_era_id]))

func _next_era_id(current_era_id: String) -> String:
	var current_order := int(DataLoader.load_json("eras/eras.json").get(current_era_id, {}).get("order", 1))
	for era_id in DataLoader.load_json("eras/eras.json").keys():
		if int(DataLoader.load_json("eras/eras.json")[era_id].get("order", 99)) == current_order + 1:
			return String(era_id)
	return ""

func _make_era_row(era_id: String, era: Dictionary) -> Button:
	var btn := Button.new()
	PREMIUM_STYLE.style_button(btn, "gold")
	btn.custom_minimum_size = Vector2(960, 110)
	btn.add_theme_font_size_override("font_size", 34)
	btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
	var check := ResearchManager.can_start_era(era_id)
	btn.text = ("→  AVANZAR A " if bool(check["ok"]) else "🔒  ") + String(era.get("name", era_id))
	btn.disabled = not bool(check["ok"]) and not ResearchManager.is_researching()
	btn.add_theme_color_override("font_color", Color(0.95, 0.75, 0.3) if bool(check["ok"]) else Color(0.55, 0.57, 0.62))
	btn.pressed.connect(func() -> void: _select_era(era_id))
	return btn

func _make_tech_row(tech_id: String, tech: Dictionary) -> Button:
	var btn := Button.new()
	PREMIUM_STYLE.style_button(btn, "blue")
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

func _select_era(era_id: String) -> void:
	_selected_id = "@era:" + era_id
	_refresh_detail()

func _refresh_detail() -> void:
	if _selected_id.is_empty():
		detail_panel.visible = false
		return
	detail_panel.visible = true
	if _selected_id.begins_with("@era:"):
		var era_id := _selected_id.trim_prefix("@era:")
		var era: Dictionary = DataLoader.load_json("eras/eras.json").get(era_id, {})
		detail_title.text = "Avanzar a " + String(era.get("name", era_id))
		var era_cost: Dictionary = era.get("unlock_cost", {})
		var era_parts: PackedStringArray = []
		for key in era_cost.keys():
			era_parts.append("%d %s" % [int(era_cost[key]), key.to_upper()])
		detail_cost_label.text = "Costo: " + (", ".join(era_parts) if not era_parts.is_empty() else "Gratis")
		detail_time_label.text = "Tiempo: " + _format_time(int(era.get("research_time_seconds", 0)))
		var requirements: Array = era.get("requirements", [])
		var requirement_names: PackedStringArray = []
		for requirement_id in requirements:
			var technology: Dictionary = DataLoader.load_json("technologies/technologies.json").get(String(requirement_id), {})
			requirement_names.append(String(technology.get("name", requirement_id)))
		detail_req_label.text = "Requisitos: " + (", ".join(requirement_names) if not requirement_names.is_empty() else "ninguno")
		var profile: Dictionary = DataLoader.get_era_profile(era_id)
		var mechanic_name := String(profile.get("mechanic_name", "Evolución visual"))
		var mechanic_description := String(profile.get("mechanic_description", "El campo de batalla se transforma al completar la investigación."))
		var check := ResearchManager.can_start_era(era_id)
		var requirement_line := "Tecnología requerida: " + (", ".join(requirement_names) if not requirement_names.is_empty() else "ninguna")
		var cost_line := "Recursos: " + ", ".join(era_parts) if not era_parts.is_empty() else "Recursos: gratis"
		var state_line := "LISTA PARA INVESTIGAR" if bool(check["ok"]) else "BLOQUEADA: " + String(check["reason"])
		detail_effect_label.text = "CAMBIO VISUAL Y DE COMBATE\n%s: %s\n\n%s\n%s\n%s\n\nAl completar: el jugador y la ciudad avanzan; los enemigos mantienen la era de su oleada." % [mechanic_name, mechanic_description, requirement_line, cost_line, state_line]
		_refresh_detail_button_state()
		return
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
		eff_lines.append(EffectProcessor.describe_effect(eff))
	detail_effect_label.text = "Efectos: " + (", ".join(eff_lines) if not eff_lines.is_empty() else "—")
	_refresh_detail_button_state()

func _refresh_detail_button_state() -> void:
	if _selected_id.is_empty():
		return
	var check := ResearchManager.can_start_era(_selected_id.trim_prefix("@era:")) if _selected_id.begins_with("@era:") else ResearchManager.can_start(_selected_id)
	research_button.disabled = not bool(check["ok"])
	research_button.text = "AVANZAR" if _selected_id.begins_with("@era:") and bool(check["ok"]) else ("INVESTIGAR" if bool(check["ok"]) else String(check["reason"]))

func _on_research_pressed() -> void:
	var started := ResearchManager.start_era_research(_selected_id.trim_prefix("@era:")) if _selected_id.begins_with("@era:") else ResearchManager.start_research(_selected_id)
	if started:
		if TutorialManager.show_once("first_research"):
			_show_context_hint("La investigación avanza con tiempo real. Puedes seguir jugando mientras espera.")
		_refresh_all()

func _on_cancel_pressed() -> void:
	ResearchManager.cancel_current()
	_refresh_all()

func _on_accelerate_pressed() -> void:
	if ResearchManager.accelerate_current():
		_refresh_all()

func _on_technology_completed(technology_id: String) -> void:
	_consume_notification("technology", technology_id)
	var tech: Dictionary = DataLoader.load_json("technologies/technologies.json").get(technology_id, {})
	completed_banner.text = "¡Investigación completada: %s!" % tech.get("name", technology_id)
	completed_banner.visible = true
	await get_tree().create_timer(3.0).timeout
	completed_banner.visible = false
	_refresh_all()

func _on_era_changed(era_id: String) -> void:
	_consume_notification("era", era_id)
	completed_banner.text = "¡Nueva era: %s!" % DataLoader.load_json("eras/eras.json").get(era_id, {}).get("name", era_id)
	completed_banner.visible = true
	_refresh_all()

func _consume_notification(notification_type: String, notification_id: String) -> void:
	for i in range(GameState.pending_notifications.size()):
		var notification: Dictionary = GameState.pending_notifications[i]
		if String(notification.get("type", "")) == notification_type and String(notification.get("id", "")) == notification_id:
			GameState.pending_notifications.remove_at(i)
			return

func _show_context_hint(message: String) -> void:
	completed_banner.text = message
	completed_banner.visible = true
	var tw := create_tween()
	tw.tween_interval(4.0)
	tw.tween_callback(func() -> void:
		if is_instance_valid(completed_banner):
			completed_banner.visible = false
)

func _format_time(total_seconds: int) -> String:
	if total_seconds >= 60:
		return "%dm %ds" % [total_seconds / 60, total_seconds % 60]
	return "%ds" % total_seconds
