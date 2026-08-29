extends Control

const MENU_SCENE := "res://scenes/menu/main_menu.tscn"
const PREMIUM_STYLE = preload("res://scripts/ui/premium_style.gd")

var _selected_id := ""
var _selected_is_pending := false
var _filter_id := "all"
var _filter_buttons: Dictionary = {}
var _detail_icon: ItemIcon

@onready var main_vbox: VBoxContainer = $MainVBox
@onready var items_list: VBoxContainer = %ItemsList
@onready var count_label: Label = %InvCountLabel
@onready var detail_panel: PanelContainer = %DetailPanel
@onready var detail_label: Label = %DetailLabel
@onready var equip_button: Button = %InvEquipButton
@onready var sell_button: Button = %InvSellButton
@onready var back_button: Button = %BackButton
@onready var sell_commons_button: Button = %SellCommonsButton

func _ready() -> void:
	_apply_premium_skin()
	_build_filter_bar()
	back_button.pressed.connect(func() -> void: get_tree().change_scene_to_file(MENU_SCENE))
	equip_button.pressed.connect(_on_equip_pressed)
	sell_button.pressed.connect(_on_sell_pressed)
	sell_commons_button.pressed.connect(_on_sell_commons_pressed)
	InventoryManager.inventory_changed.connect(_refresh)
	_refresh()

func _apply_premium_skin() -> void:
	PREMIUM_STYLE.style_button(sell_commons_button, "green")
	PREMIUM_STYLE.style_button(back_button, "blue")
	PREMIUM_STYLE.style_button(equip_button, "green")
	PREMIUM_STYLE.style_button(sell_button, "gold")
	PREMIUM_STYLE.style_panel(detail_panel)
	PREMIUM_STYLE.style_title($MainVBox/Title, 72)

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		get_tree().change_scene_to_file(MENU_SCENE)

func _refresh() -> void:
	for child in items_list.get_children():
		child.queue_free()
	count_label.text = "%d / 50 objetos  ·  ORO %d%s" % [GameState.inventory.size(), GameState.gold, "  ·  %d pendiente(s)" % GameState.pending_items.size() if not GameState.pending_items.is_empty() else ""]
	detail_panel.visible = false
	_selected_id = ""
	_selected_is_pending = false
	_update_filter_labels()
	var visible_items: Array = []
	for instance in GameState.inventory:
		if _matches_filter(instance):
			visible_items.append({"instance": instance, "pending": false})
	for instance in GameState.pending_items:
		if _matches_filter(instance):
			visible_items.append({"instance": instance, "pending": true})
	if visible_items.is_empty():
		var empty := Label.new()
		empty.text = "No hay objetos en esta categoria."
		empty.add_theme_font_size_override("font_size", 34)
		empty.add_theme_color_override("font_color", Color(0.62, 0.68, 0.8))
		empty.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		items_list.add_child(empty)
		_refresh_buttons_state()
		return
	if not GameState.pending_items.is_empty():
		var pending_note := Label.new()
		pending_note.text = "Los pendientes no ocupan espacio. Guardalos o vendelos desde su detalle."
		pending_note.add_theme_font_size_override("font_size", 26)
		pending_note.add_theme_color_override("font_color", Color(1.0, 0.72, 0.3))
		pending_note.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		pending_note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		items_list.add_child(pending_note)
	for entry in visible_items:
		items_list.add_child(_make_row(entry["instance"], bool(entry["pending"])))
	_refresh_buttons_state()

func _make_row(instance: Dictionary, pending: bool = false) -> PanelContainer:
	var row := PanelContainer.new()
	row.custom_minimum_size = Vector2(960, 116)
	var row_style := StyleBoxFlat.new()
	row_style.bg_color = Color(0.07, 0.09, 0.14, 0.98) if not pending else Color(0.14, 0.10, 0.065, 0.98)
	row_style.border_color = Color(1.0, 0.68, 0.25) if pending else LootManager.get_rarity_color(String(instance.get("rarity", "common")))
	row_style.set_border_width_all(2)
	row_style.set_corner_radius_all(16)
	row.add_theme_stylebox_override("panel", row_style)
	var hbox := HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 14)
	row.add_child(hbox)
	var icon := ItemIcon.new()
	icon.custom_minimum_size = Vector2(100, 100)
	icon.set_item(instance)
	hbox.add_child(icon)
	var info := VBoxContainer.new()
	info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	info.add_theme_constant_override("separation", 2)
	hbox.add_child(info)
	var title := Label.new()
	title.add_theme_font_size_override("font_size", 31)
	title.add_theme_color_override("font_color", Color(1.0, 0.75, 0.3) if pending else LootManager.get_rarity_color(String(instance.get("rarity", "common"))))
	title.text = ("PENDIENTE · " if pending else "") + String(instance.get("name", "?"))
	info.add_child(title)
	var subtitle := Label.new()
	subtitle.add_theme_font_size_override("font_size", 25)
	subtitle.add_theme_color_override("font_color", Color(0.68, 0.75, 0.88))
	subtitle.text = "%s  ·  Nv.%d  ·  %s" % [_slot_label(String(instance.get("slot", ""))), int(instance.get("level", 1)), LootManager.get_rarity_name(String(instance.get("rarity", ""))).to_upper()]
	info.add_child(subtitle)
	var summary := Label.new()
	summary.add_theme_font_size_override("font_size", 22)
	summary.add_theme_color_override("font_color", Color(0.54, 0.63, 0.76))
	summary.text = _item_summary(instance)
	info.add_child(summary)
	var select_button := Button.new()
	select_button.custom_minimum_size = Vector2(128, 86)
	select_button.add_theme_font_size_override("font_size", 27)
	select_button.text = "VER"
	select_button.tooltip_text = "Ver detalles"
	select_button.focus_mode = Control.FOCUS_NONE
	_apply_button_style(select_button, Color(0.13, 0.19, 0.3), Color(0.2, 0.32, 0.5), Color(0.1, 0.15, 0.24))
	select_button.pressed.connect(func() -> void: _select_item(String(instance.get("id", "")), pending))
	hbox.add_child(select_button)
	var id := String(instance.get("id", ""))
	return row

func _select_item(item_id: String, pending: bool = false) -> void:
	_selected_id = item_id
	_selected_is_pending = pending
	var instance := InventoryManager.find_pending_item(item_id) if pending else InventoryManager.find_item(item_id)
	if instance.is_empty():
		return
	detail_panel.visible = true
	if _detail_icon != null:
		_detail_icon.queue_free()
	_detail_icon = ItemIcon.new()
	_detail_icon.custom_minimum_size = Vector2(112, 112)
	_detail_icon.set_item(instance)
	var detail_vbox := detail_label.get_parent() as VBoxContainer
	detail_vbox.add_child(_detail_icon)
	detail_vbox.move_child(_detail_icon, 0)
	var lines: PackedStringArray = []
	lines.append("%s — %s Nv.%d" % [instance.get("name", "?"), LootManager.get_rarity_name(String(instance.get("rarity", ""))), int(instance.get("level", 1))])
	lines.append("Tipo: %s  ·  %s" % [_slot_label(String(instance.get("slot", ""))), "A distancia" if _is_ranged(instance) else "Cuerpo a cuerpo"])
	var totals := StatsCalculator.item_total_stats(instance)
	for stat_key in totals.keys():
		if stat_key == "attack_range" and float(totals[stat_key]) <= 0.0:
			continue
		lines.append(StatsCalculator.format_stat_line(stat_key, float(totals[stat_key])))
	lines.append("Valor de venta: %d oro%s" % [int(instance.get("sell_value", 0)), "  ·  PENDIENTE" if pending else ""])
	detail_label.text = "\n".join(lines)
	_refresh_buttons_state()

func _refresh_buttons_state() -> void:
	var has_selection := not _selected_id.is_empty()
	equip_button.disabled = not has_selection or _selected_is_pending
	sell_button.disabled = not has_selection

func _on_equip_pressed() -> void:
	if InventoryManager.equip_item(_selected_id):
		_show_toast("¡Equipado!")
	else:
		_show_toast("No se pudo equipar")

func _on_sell_pressed() -> void:
	var val := InventoryManager.sell_pending_item(_selected_id) if _selected_is_pending else InventoryManager.sell_item(_selected_id)
	if val > 0:
		_show_toast("Vendido por %d oro" % val)

func _on_sell_commons_pressed() -> void:
	var total := InventoryManager.sell_all_by_rarity("common")
	if total > 0:
		_show_toast("Vendidos comunes por %d oro" % total)
	else:
		_show_toast("No hay comunes para vender")

func _show_toast(text: String) -> void:
	var lbl := Label.new()
	lbl.text = text
	lbl.add_theme_font_size_override("font_size", 38)
	lbl.add_theme_color_override("font_color", Color(1, 0.92, 0.5))
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.position = Vector2(40, 1720)
	lbl.size = Vector2(1000, 60)
	add_child(lbl)
	var tw := create_tween()
	tw.tween_interval(1.4)
	tw.tween_property(lbl, "modulate:a", 0.0, 0.4)
	tw.tween_callback(lbl.queue_free)

func _build_filter_bar() -> void:
	var bar := HBoxContainer.new()
	bar.name = "FilterBar"
	bar.custom_minimum_size = Vector2(0, 78)
	bar.add_theme_constant_override("separation", 8)
	bar.alignment = BoxContainer.ALIGNMENT_CENTER
	var group := ButtonGroup.new()
	var filter_icons := {"weapon": "res://assets/ui/icons/sword.png", "armor": "res://assets/ui/icons/shield.png", "accessory": "res://assets/ui/icons/ring.png"}
	for spec in [["all", "TODOS"], ["weapon", "ARMAS"], ["armor", "ARMADURAS"], ["accessory", "ACCESORIOS"]]:
		var button := Button.new()
		button.custom_minimum_size = Vector2(232, 72)
		button.toggle_mode = true
		button.button_group = group
		button.add_theme_font_size_override("font_size", 25)
		if filter_icons.has(String(spec[0])):
			button.icon = PREMIUM_STYLE.load_icon(filter_icons[String(spec[0])], 48)
			button.icon_alignment = HORIZONTAL_ALIGNMENT_LEFT
		_apply_button_style(button, Color(0.1, 0.15, 0.24), Color(0.18, 0.3, 0.48), Color(0.08, 0.12, 0.2))
		button.pressed.connect(_set_filter.bind(String(spec[0])))
		bar.add_child(button)
		_filter_buttons[String(spec[0])] = button
	main_vbox.add_child(bar)
	main_vbox.move_child(bar, items_list.get_parent().get_index())

func _set_filter(filter_id: String) -> void:
	_filter_id = filter_id
	for id in _filter_buttons.keys():
		_filter_buttons[id].button_pressed = String(id) == filter_id
	if is_inside_tree() and not items_list.get_children().is_empty():
		_refresh()

func _update_filter_labels() -> void:
	var counts := {"all": 0, "weapon": 0, "armor": 0, "accessory": 0}
	for instance in GameState.inventory:
		counts["all"] += 1
		counts[_filter_for_slot(String(instance.get("slot", "")))] += 1
	var labels := {"all": "TODOS", "weapon": "ARMAS", "armor": "ARMADURAS", "accessory": "ACCESORIOS"}
	for id in _filter_buttons.keys():
		_filter_buttons[id].text = "%s  %d" % [String(labels.get(id, id)).to_upper(), int(counts[id])]

func _matches_filter(instance: Dictionary) -> bool:
	return _filter_id == "all" or _filter_for_slot(String(instance.get("slot", ""))) == _filter_id

func _filter_for_slot(slot: String) -> String:
	if slot == "weapon":
		return "weapon"
	if slot == "amulet":
		return "accessory"
	return "armor"

func _slot_label(slot: String) -> String:
	return {"weapon": "ARMA", "helmet": "CASCO", "armor": "ARMADURA", "gloves": "GUANTES", "boots": "BOTAS", "amulet": "AMULETO"}.get(slot, slot.to_upper())

func _item_summary(instance: Dictionary) -> String:
	var totals := StatsCalculator.item_total_stats(instance)
	var parts: PackedStringArray = []
	for key in ["damage", "max_health", "critical_chance", "attack_range"]:
		if totals.has(key) and (key != "attack_range" or float(totals[key]) > 0.0):
			parts.append(StatsCalculator.format_stat_line(key, float(totals[key])))
	if parts.is_empty():
		return "Sin bonificadores"
	return "  ·  ".join(parts.slice(0, 2))

func _is_ranged(instance: Dictionary) -> bool:
	if String(instance.get("attack_type", "")) == "ranged":
		return true
	return float(StatsCalculator.item_total_stats(instance).get("attack_range", 0.0)) >= 160.0

func _apply_button_style(button: Button, normal_color: Color, hover_color: Color, pressed_color: Color) -> void:
	for entry in [["normal", normal_color], ["hover", hover_color], ["pressed", pressed_color], ["focus", hover_color]]:
		var style := StyleBoxFlat.new()
		style.bg_color = entry[1]
		style.border_color = Color(0.88, 0.65, 0.23, 0.9)
		style.set_border_width_all(2)
		style.set_corner_radius_all(14)
		style.shadow_color = Color(0.01, 0.02, 0.04, 0.68)
		style.shadow_size = 8
		button.add_theme_stylebox_override(entry[0], style)
