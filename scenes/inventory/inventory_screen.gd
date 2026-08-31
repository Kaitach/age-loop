extends Control

const MENU_SCENE := "res://scenes/menu/main_menu.tscn"
const PREMIUM_STYLE = preload("res://scripts/ui/premium_style.gd")

var _selected_id := ""
var _selected_is_pending := false
var _filter_id := "all"
var _filter_buttons: Dictionary = {}
var _detail_icon: ItemIcon
var _sort_key := "power"
var _only_better := false
var _only_favorites := false

@onready var main_vbox: VBoxContainer = $MainVBox
@onready var items_list: VBoxContainer = %ItemsList
@onready var count_label: Label = %InvCountLabel
@onready var detail_panel: PanelContainer = %DetailPanel
@onready var detail_label: Label = %DetailLabel
@onready var equip_button: Button = %InvEquipButton
@onready var sell_button: Button = %InvSellButton
@onready var back_button: Button = %BackButton
@onready var sell_commons_button: Button = %SellCommonsButton

var _capacity_bar: ProgressBar
var _capacity_hint: Label
var _bulk_modal: Control
var _confirm_modal: Control
var _sort_option: OptionButton
var _better_check: CheckBox
var _fav_check: CheckBox

func _ready() -> void:
	_apply_premium_skin()
	_build_filter_bar()
	_build_capacity_bar()
	_build_bulk_and_sort_bar()
	_build_bulk_modal()
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
		if _confirm_modal.visible:
			_confirm_modal.visible = false
		elif _bulk_modal.visible:
			_bulk_modal.visible = false
		elif detail_panel.visible:
			detail_panel.visible = false
			_selected_id = ""
		else:
			get_tree().change_scene_to_file(MENU_SCENE)

func _build_capacity_bar() -> void:
	var container := VBoxContainer.new()
	container.add_theme_constant_override("separation", 4)
	_capacity_bar = ProgressBar.new()
	_capacity_bar.max_value = InventoryManager.CAPACITY
	_capacity_bar.show_percentage = false
	_capacity_bar.custom_minimum_size = Vector2(0, 18)
	_capacity_hint = Label.new()
	_capacity_hint.add_theme_font_size_override("font_size", 24)
	_capacity_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	container.add_child(_capacity_bar)
	container.add_child(_capacity_hint)
	main_vbox.add_child(container)
	main_vbox.move_child(container, 2)

func _update_capacity() -> void:
	var info := InventoryManager.get_capacity_info()
	_capacity_bar.max_value = info["total"]
	_capacity_bar.value = info["used"]
	_capacity_bar.modulate = Color(0.95, 0.35, 0.35) if info["pct"] >= 1.0 else Color(1, 0.85, 0.3) if info["pct"] >= 0.85 else Color(1,1,1)
	var hint := "%d / %d  ·  %d libres" % [info["used"], info["total"], info["free"]]
	if info["pct"] >= 1.0:
		hint = "🔴 INVENTARIO LLENO  ·  " + hint
	elif info["pct"] >= 0.85:
		hint = "⚠️ CASI LLENO  ·  " + hint
	if info["pending"] > 0:
		hint += "  ·  %d pendiente(s)" % info["pending"]
	count_label.text = hint
	_capacity_hint.text = _capacity_text(info)

func _capacity_text(info: Dictionary) -> String:
	var pct := float(info["pct"]) * 100.0
	var bar_len := 20
	var filled := int(round(pct / 100.0 * bar_len))
	return "[" + "█".repeat(filled) + "░".repeat(bar_len - filled) + "]  %.0f%%" % pct

func _build_bulk_and_sort_bar() -> void:
	var bulk_row := HBoxContainer.new()
	bulk_row.add_theme_constant_override("separation", 8)
	bulk_row.alignment = BoxContainer.ALIGNMENT_CENTER
	for spec in [["no_equip", "VENDER NO EQUIPADOS"], ["mass", "VENTA MASIVA"], ["smart", "LIMPIEZA"], ["quick", "EQUIPAR MEJOR"]]:
		var b := Button.new()
		b.custom_minimum_size = Vector2(232, 72)
		b.add_theme_font_size_override("font_size", 22)
		b.text = spec[1]
		_apply_button_style(b, Color(0.1, 0.15, 0.24), Color(0.18, 0.3, 0.48), Color(0.08, 0.12, 0.2))
		match spec[0]:
			"no_equip": b.pressed.connect(_on_sell_unequipped_pressed)
			"mass": b.pressed.connect(_open_mass_sale)
			"smart": b.pressed.connect(_open_smart_cleanup)
			"quick": b.pressed.connect(_on_quick_equip_pressed)
		bulk_row.add_child(b)
	main_vbox.add_child(bulk_row)
	main_vbox.move_child(bulk_row, 4)
	var sort_row := HBoxContainer.new()
	sort_row.add_theme_constant_override("separation", 12)
	sort_row.alignment = BoxContainer.ALIGNMENT_CENTER
	var sort_lbl := Label.new()
	sort_lbl.text = "Orden:"
	sort_lbl.add_theme_font_size_override("font_size", 24)
	sort_row.add_child(sort_lbl)
	_sort_option = OptionButton.new()
	_sort_option.custom_minimum_size = Vector2(220, 56)
	for opt in [["power","Poder"],["level","Nivel"],["rarity","Rareza"],["value","Valor"],["recent","Reciente"]]:
		_sort_option.add_item(opt[1])
	_sort_option.selected = 0
	_sort_option.item_selected.connect(func(idx): _sort_key = ["power","level","rarity","value","recent"][idx]; _refresh())
	sort_row.add_child(_sort_option)
	_better_check = CheckBox.new()
	_better_check.text = "Solo mejoras"
	_better_check.toggled.connect(func(v): _only_better = v; _refresh())
	sort_row.add_child(_better_check)
	_fav_check = CheckBox.new()
	_fav_check.text = "⭐ Favoritos"
	_fav_check.toggled.connect(func(v): _only_favorites = v; _refresh())
	sort_row.add_child(_fav_check)
	main_vbox.add_child(sort_row)
	main_vbox.move_child(sort_row, 5)

func _build_bulk_modal() -> void:
	_bulk_modal = _make_modal()
	_confirm_modal = _make_modal()
	_confirm_modal.name = "ConfirmModal"

func _make_modal() -> Control:
	var overlay := ColorRect.new()
	overlay.color = Color(0,0,0,0.65)
	overlay.visible = false
	overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay.add_child(center)
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(880, 0)
	PREMIUM_STYLE.style_panel(panel)
	center.add_child(panel)
	add_child(overlay)
	return overlay

func _show_confirm(title: String, body: String, confirm_text: String, on_confirm: Callable, warn_level: String = "ok") -> void:
	for c in _confirm_modal.get_child(0).get_child(0).get_children():
		if c is VBoxContainer:
			c.queue_free()
	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 16)
	_confirm_modal.get_child(0).get_child(0).add_child(vbox)
	var title_lbl := Label.new()
	title_lbl.text = title
	title_lbl.add_theme_font_size_override("font_size", 44)
	title_lbl.add_theme_color_override("font_color", Color(1,0.45,0.35) if warn_level == "epic_confirm" else Color(1,0.82,0.39))
	title_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(title_lbl)
	var body_lbl := Label.new()
	body_lbl.text = body
	body_lbl.add_theme_font_size_override("font_size", 30)
	body_lbl.add_theme_color_override("font_color", Color(0.85,0.9,1.0))
	body_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	body_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vbox.add_child(body_lbl)
	var hbox := HBoxContainer.new()
	hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	hbox.add_theme_constant_override("separation", 18)
	vbox.add_child(hbox)
	var cancel := Button.new()
	cancel.text = "CANCELAR"
	cancel.custom_minimum_size = Vector2(260, 84)
	PREMIUM_STYLE.style_button(cancel, "blue")
	cancel.pressed.connect(func(): _confirm_modal.visible = false)
	hbox.add_child(cancel)
	var confirm := Button.new()
	confirm.text = confirm_text
	confirm.custom_minimum_size = Vector2(260, 84)
	PREMIUM_STYLE.style_button(confirm, "gold" if warn_level != "epic_confirm" else "brown")
	confirm.pressed.connect(func():
		_confirm_modal.visible = false
		on_confirm.call()
	)
	hbox.add_child(confirm)
	_confirm_modal.visible = true

func _refresh() -> void:
	for child in items_list.get_children():
		child.queue_free()
	_update_capacity()
	detail_panel.visible = false
	_selected_id = ""
	_selected_is_pending = false
	_update_filter_labels()
	var visible_items := _get_visible_items()
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

func _get_visible_items() -> Array:
	var raw: Array = []
	for instance in GameState.inventory:
		if _matches_filter(instance):
			raw.append({"instance": instance, "pending": false})
	for instance in GameState.pending_items:
		if _matches_filter(instance):
			raw.append({"instance": instance, "pending": true})
	if _only_favorites:
		raw = raw.filter(func(e): return bool(e["instance"].get("favorite", false)))
	if _only_better:
		raw = raw.filter(func(e): return InventoryManager.is_better_than_equipped(e["instance"]))
	var items_only: Array = raw.map(func(e): return e["instance"])
	items_only = InventoryManager.sort_items(items_only, _sort_key)
	var sorted_raw: Array = []
	for it in items_only:
		for e in raw:
			if String(e["instance"].get("id","")) == String(it.get("id","")):
				sorted_raw.append(e)
				break
	return sorted_raw

func _make_row(instance: Dictionary, pending: bool = false) -> PanelContainer:
	var row := PanelContainer.new()
	row.custom_minimum_size = Vector2(960, 118)
	var row_style := StyleBoxFlat.new()
	row_style.bg_color = Color(0.07, 0.09, 0.14, 0.98) if not pending else Color(0.14, 0.10, 0.065, 0.98)
	row_style.border_color = Color(1.0, 0.68, 0.25) if pending else LootManager.get_rarity_color(String(instance.get("rarity", "common")))
	row_style.set_border_width_all(2)
	row_style.set_corner_radius_all(16)
	if bool(instance.get("favorite", false)):
		row_style.border_width_left = 6
		row_style.border_color = Color(1, 0.82, 0.2)
	if bool(instance.get("trash", false)):
		row_style.bg_color = row_style.bg_color.darkened(0.15)
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
	var fav_mark := "⭐ " if bool(instance.get("favorite", false)) else ""
	var trash_mark := "🗑️ " if bool(instance.get("trash", false)) else ""
	var title := Label.new()
	title.add_theme_font_size_override("font_size", 31)
	title.add_theme_color_override("font_color", Color(1.0, 0.75, 0.3) if pending else LootManager.get_rarity_color(String(instance.get("rarity", "common"))))
	title.text = fav_mark + trash_mark + ("PENDIENTE · " if pending else "") + String(instance.get("name", "?"))
	info.add_child(title)
	var subtitle := Label.new()
	subtitle.add_theme_font_size_override("font_size", 25)
	subtitle.add_theme_color_override("font_color", Color(0.68, 0.75, 0.88))
	subtitle.text = "%s  ·  Nv.%d  ·  %s  ·  Poder %d" % [_slot_label(String(instance.get("slot", ""))), int(instance.get("level", 1)), LootManager.get_rarity_name(String(instance.get("rarity", ""))).to_upper(), int(InventoryManager.get_item_power(instance))]
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
	select_button.focus_mode = Control.FOCUS_NONE
	_apply_button_style(select_button, Color(0.13, 0.19, 0.3), Color(0.2, 0.32, 0.5), Color(0.1, 0.15, 0.24))
	select_button.pressed.connect(func() -> void: _select_item(String(instance.get("id", "")), pending))
	hbox.add_child(select_button)
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
	var fav_txt := "⭐ FAVORITO  " if bool(instance.get("favorite", false)) else ""
	var trash_txt := "🗑️ PARA VENTA  " if bool(instance.get("trash", false)) else ""
	var lines: PackedStringArray = []
	lines.append("%s%s — %s Nv.%d" % [fav_txt, trash_txt, instance.get("name", "?"), int(instance.get("level", 1))])
	lines.append("Tipo: %s  ·  %s  ·  Poder %d" % [_slot_label(String(instance.get("slot", ""))), "A distancia" if _is_ranged(instance) else "Cuerpo a cuerpo", int(InventoryManager.get_item_power(instance))])
	var totals := StatsCalculator.item_total_stats(instance)
	for stat_key in totals.keys():
		if stat_key == "attack_range" and float(totals[stat_key]) <= 0.0:
			continue
		lines.append(StatsCalculator.format_stat_line(stat_key, float(totals[stat_key])))
	lines.append("Valor de venta: %d oro%s" % [int(instance.get("sell_value", 0)), "  ·  PENDIENTE" if pending else ""])
	detail_label.text = "\n".join(lines)
	_refresh_buttons_state()
	_rebuild_detail_buttons(instance, pending)

func _rebuild_detail_buttons(instance: Dictionary, pending: bool) -> void:
	var btn_row := detail_label.get_parent().get_node_or_null("Buttons") as HBoxContainer
	if btn_row == null:
		return
	for c in btn_row.get_children():
		if c.name == "FavBtn" or c.name == "TrashBtn":
			c.queue_free()
	var fav_btn := Button.new()
	fav_btn.name = "FavBtn"
	fav_btn.custom_minimum_size = Vector2(200, 86)
	fav_btn.add_theme_font_size_override("font_size", 26)
	fav_btn.text = "★ Quitar Fav" if bool(instance.get("favorite", false)) else "☆ Favorito"
	_apply_button_style(fav_btn, Color(0.18,0.16,0.08), Color(0.26,0.22,0.12), Color(0.12,0.10,0.06))
	fav_btn.pressed.connect(func():
		InventoryManager.toggle_favorite(String(instance.get("id","")))
		_select_item(String(instance.get("id","")), pending)
		_refresh()
	)
	btn_row.add_child(fav_btn)
	btn_row.move_child(fav_btn, 0)
	var trash_btn := Button.new()
	trash_btn.name = "TrashBtn"
	trash_btn.custom_minimum_size = Vector2(200, 86)
	trash_btn.add_theme_font_size_override("font_size", 26)
	trash_btn.text = "Desmarcar" if bool(instance.get("trash", false)) else "🗑️ Marcar"
	_apply_button_style(trash_btn, Color(0.18,0.08,0.08), Color(0.28,0.12,0.12), Color(0.12,0.06,0.06))
	trash_btn.pressed.connect(func():
		if not InventoryManager.toggle_trash(String(instance.get("id",""))):
			_show_toast("No podés marcar favorito como basura")
		else:
			_select_item(String(instance.get("id","")), pending)
			_refresh()
	)
	btn_row.add_child(trash_btn)
	btn_row.move_child(trash_btn, 1)

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
	var inst := InventoryManager.find_item(_selected_id) if not _selected_is_pending else InventoryManager.find_pending_item(_selected_id)
	if inst.is_empty():
		return
	var check := InventoryManager.can_sell_item(inst)
	if not check["allowed"]:
		_show_confirm("No se puede vender", check["reason"], "OK", func(): pass, "blocked")
		return
	if check["level"] == "epic_confirm":
		_show_confirm("⚠️ Vender %s" % inst.get("name",""), "Es %s. ¿Seguro?\nValor: %d oro" % [LootManager.get_rarity_name(String(inst.get("rarity",""))), int(inst.get("sell_value",0))], "VENDER", func():
			var v := InventoryManager.sell_pending_item(_selected_id) if _selected_is_pending else InventoryManager.sell_item(_selected_id)
			if v>0: _show_toast("Vendido por %d oro" % v)
		, "epic_confirm")
		return
	if InventoryManager.is_trash(inst) or String(inst.get("rarity","")) in ["common","uncommon"]:
		var v := InventoryManager.sell_pending_item(_selected_id) if _selected_is_pending else InventoryManager.sell_item(_selected_id)
		if v>0: _show_toast("Vendido por %d oro" % v)
	else:
		_show_confirm("Vender %s" % inst.get("name",""), "Valor: %d oro" % int(inst.get("sell_value",0)), "VENDER", func():
			var vv := InventoryManager.sell_pending_item(_selected_id) if _selected_is_pending else InventoryManager.sell_item(_selected_id)
			if vv>0: _show_toast("Vendido por %d oro" % vv)
		)

func _on_sell_commons_pressed() -> void:
	var preview := InventoryManager.preview_sell({"rarities": ["common"]})
	if preview["count"] == 0:
		_show_toast("No hay comunes para vender")
		return
	_show_confirm("Vender comunes", "Se venderán %d objetos.\nObtendrás +%d oro.\n\nNunca se venden equipados ni favoritos." % [preview["count"], preview["gold"]], "VENDER", func():
		var g := InventoryManager.sell_filtered({"rarities": ["common"]}, true)
		_show_toast("Vendidos %d comunes por %d oro" % [preview["count"], g])
	)

func _on_sell_unequipped_pressed() -> void:
	var preview := InventoryManager.preview_sell({"only_unequipped": true})
	if preview["count"] == 0:
		_show_toast("No hay objetos para vender")
		return
	var body := "Se venderán %d objetos no equipados.\n+%d oro" % [preview["count"], preview["gold"]]
	if preview["blocked"] > 0:
		body += "\n\n%d protegidos (favoritos/equipados) no se venderán." % preview["blocked"]
	_show_confirm("Vender no equipados", body, "VENDER", func():
		var g := InventoryManager.sell_filtered({"only_unequipped": true}, false)
		if g==0:
			_show_confirm("⚠️ Incluye épicos/legendarios", "Hay %d épicos/legendarios. ¿Vender de todas formas?" % preview["count"], "VENDER TODO", func():
				InventoryManager.sell_filtered({"only_unequipped": true}, true)
				_show_toast("Venta completada")
			, "epic_confirm")
		else:
			_show_toast("Vendidos por %d oro" % g)
	)

func _open_mass_sale() -> void:
	for c in _bulk_modal.get_child(0).get_child(0).get_children():
		if c is VBoxContainer:
			c.queue_free()
	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 14)
	_bulk_modal.get_child(0).get_child(0).add_child(vbox)
	var title := Label.new()
	title.text = "VENTA MASIVA"
	title.add_theme_font_size_override("font_size", 48)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(title)
	var rarities: Array = ["common","uncommon","rare","epic","legendary"]
	var rarity_checks: Dictionary = {}
	var rar_row := HBoxContainer.new()
	rar_row.add_theme_constant_override("separation", 6)
	for r in rarities:
		var cb := CheckBox.new()
		cb.text = LootManager.get_rarity_name(r).substr(0,3).to_upper()
		cb.button_pressed = (r=="common")
		rarity_checks[r]=cb
		rar_row.add_child(cb)
	vbox.add_child(rar_row)
	var slots: Array = ["weapon","helmet","armor","gloves","boots","amulet"]
	var slot_checks: Dictionary = {}
	var slot_row := HBoxContainer.new()
	for s in slots:
		var cb2 := CheckBox.new()
		cb2.text = s.substr(0,3).to_upper()
		slot_checks[s]=cb2
		slot_row.add_child(cb2)
	vbox.add_child(slot_row)
	var level_row := HBoxContainer.new()
	level_row.add_theme_constant_override("separation", 8)
	var lvl_label := Label.new()
	lvl_label.text = "Nivel <"
	level_row.add_child(lvl_label)
	var lvl_spin := SpinBox.new()
	lvl_spin.min_value = 1
	lvl_spin.max_value = 99
	lvl_spin.value = 5
	lvl_spin.custom_minimum_size = Vector2(120, 0)
	level_row.add_child(lvl_spin)
	var lvl_check := CheckBox.new()
	lvl_check.text = "Filtrar nivel"
	level_row.add_child(lvl_check)
	vbox.add_child(level_row)
	var preview_lbl := Label.new()
	preview_lbl.add_theme_font_size_override("font_size", 30)
	preview_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(preview_lbl)
	var update_preview := func():
		var rar_sel: Array = []
		for k in rarity_checks.keys():
			if rarity_checks[k].button_pressed:
				rar_sel.append(k)
		var slot_sel: Array = []
		for k in slot_checks.keys():
			if slot_checks[k].button_pressed:
				slot_sel.append(k)
		var filt := {}
		if not rar_sel.is_empty(): filt["rarities"] = rar_sel
		if not slot_sel.is_empty(): filt["slots"] = slot_sel
		if lvl_check.button_pressed:
			filt["max_level"] = int(lvl_spin.value) - 1
		var p := InventoryManager.preview_sell(filt)
		preview_lbl.text = "%d objetos  ·  +%d oro  ·  %d protegidos" % [p["count"], p["gold"], p["blocked"]]
	for cb in rarity_checks.values(): cb.toggled.connect(func(_v): update_preview.call())
	for cb in slot_checks.values(): cb.toggled.connect(func(_v): update_preview.call())
	lvl_check.toggled.connect(func(_v): update_preview.call())
	lvl_spin.value_changed.connect(func(_v): if lvl_check.button_pressed: update_preview.call())
	update_preview.call()
	var hbox := HBoxContainer.new()
	hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	hbox.add_theme_constant_override("separation", 16)
	vbox.add_child(hbox)
	var cancel := Button.new()
	cancel.text = "CANCELAR"
	PREMIUM_STYLE.style_button(cancel, "blue")
	cancel.pressed.connect(func(): _bulk_modal.visible=false)
	hbox.add_child(cancel)
	var confirm := Button.new()
	confirm.text = "CONFIRMAR VENTA"
	PREMIUM_STYLE.style_button(confirm, "gold")
	confirm.pressed.connect(func():
		var rar_sel2: Array = []
		for k in rarity_checks.keys():
			if rarity_checks[k].button_pressed:
				rar_sel2.append(k)
		var slot_sel2: Array = []
		for k in slot_checks.keys():
			if slot_checks[k].button_pressed:
				slot_sel2.append(k)
		var filt2 := {}
		if not rar_sel2.is_empty(): filt2["rarities"]=rar_sel2
		if not slot_sel2.is_empty(): filt2["slots"]=slot_sel2
		if lvl_check.button_pressed:
			filt2["max_level"]=int(lvl_spin.value)-1
		var p2 := InventoryManager.preview_sell(filt2)
		if p2["count"]==0:
			_show_toast("Nada para vender")
			return
		_show_confirm("Confirmar venta", "%d objetos por %d oro" % [p2["count"], p2["gold"]], "VENDER", func():
			InventoryManager.sell_filtered(filt2, true)
			_show_toast("Vendidos %d por %d oro" % [p2["count"], p2["gold"]])
			_bulk_modal.visible=false
		)
	)
	hbox.add_child(confirm)
	_bulk_modal.visible = true

func _open_smart_cleanup() -> void:
	var preview := InventoryManager.get_smart_cleanup_preview()
	if preview["total_unique"]==0:
		_show_toast("¡Inventario limpio!")
		return
	var body := "Encontrados:\n• %d comunes no útiles\n• %d inferiores al equipado\n• %d duplicados inferiores\n• %d marcados basura\n\nOro potencial: +%d\nEspacios: %d" % [preview["commons"].size(), preview["inferior"].size(), preview["duplicates"].size(), preview["trash"].size(), preview["gold"], preview["total_unique"]]
	_show_confirm("Limpieza inteligente", body, "REVISAR", func():
		var filt_ids := {}
		for it in preview["all"]:
			filt_ids[String(it.get("id",""))]=true
		var gold := 0
		var kept: Array = []
		for it in GameState.inventory:
			if filt_ids.has(String(it.get("id",""))):
				gold += int(it.get("sell_value",0))
			else:
				kept.append(it)
		if gold>0:
			_show_confirm("Vender %d objetos" % filt_ids.size(), "+%d oro" % gold, "VENDER", func():
				GameState.inventory = kept
				Economy.add_gold(gold)
				InventoryManager.inventory_changed.emit()
				SignalBus.inventory_changed.emit()
				SignalBus.save_requested.emit()
				_show_toast("Limpieza: +%d oro" % gold)
			)
	)

func _on_quick_equip_pressed() -> void:
	var preview := InventoryManager.quick_equip_best_preview()
	if preview["best"].is_empty():
		_show_toast("Ya tenés el mejor equipo")
		return
	var body := "Poder %d → %d\nDaño %d → %d\nVida %d → %d" % [preview["power_before"], preview["power_after"], int(preview["before"].get("damage",0)), int(preview["after"].get("damage",0)), int(preview["before"].get("max_health",0)), int(preview["after"].get("max_health",0))]
	_show_confirm("Equipamiento rápido", body, "APLICAR", func():
		InventoryManager.quick_equip_best_apply()
		_show_toast("Equipo optimizado")
	)

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
