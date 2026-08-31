extends Control

const MENU_SCENE := "res://scenes/menu/main_menu.tscn"
const PREMIUM_STYLE = preload("res://scripts/ui/premium_style.gd")
const EQUIPMENT_SLOTS := ["weapon", "helmet", "armor", "gloves", "boots", "amulet"]
const DESIGN_WIDTH := 1080.0

@onready var main_vbox: VBoxContainer = $MainVBox
@onready var slots_grid: VBoxContainer = %SlotsGrid
@onready var stats_label: Label = %StatsLabel
@onready var count_label: Label = %CountLabel
@onready var back_button: Button = %BackButton

var _category_modal: Control
var _compare_modal: Control
var _quick_sort_key := "power"
var _only_better := false

func _ready() -> void:
	_configure_layout()
	_apply_premium_skin()
	_build_top_bar()
	_build_category_modal()
	_build_compare_modal()
	back_button.pressed.connect(_go_back)
	SignalBus.equipment_changed.connect(_refresh)
	SignalBus.inventory_changed.connect(_refresh)
	_refresh()

func _apply_premium_skin() -> void:
	PREMIUM_STYLE.style_button(back_button, "blue")
	PREMIUM_STYLE.style_panel($MainVBox/StatsPanel)
	PREMIUM_STYLE.style_title($MainVBox/Title, 70)
	stats_label.add_theme_color_override("font_color", Color(0.88, 0.92, 1.0, 1))

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		if _compare_modal.visible:
			_compare_modal.visible = false
		elif _category_modal.visible:
			_category_modal.visible = false
		else:
			_go_back()

func _go_back() -> void:
	get_tree().change_scene_to_file(MENU_SCENE)

func _configure_layout() -> void:
	var visible_rect := get_viewport().get_visible_rect()
	var content_width := minf(DESIGN_WIDTH, maxf(visible_rect.size.x - 64.0, 640.0))
	main_vbox.anchor_left = 0.0
	main_vbox.anchor_top = 0.0
	main_vbox.anchor_right = 0.0
	main_vbox.anchor_bottom = 0.0
	main_vbox.position = Vector2(visible_rect.position.x + (visible_rect.size.x - content_width) * 0.5, visible_rect.position.y + 34.0)
	main_vbox.size = Vector2(content_width, maxf(visible_rect.size.y - 68.0, 0.0))

func _build_top_bar() -> void:
	var bar := HBoxContainer.new()
	bar.add_theme_constant_override("separation", 10)
	bar.alignment = BoxContainer.ALIGNMENT_CENTER
	var quick_btn := Button.new()
	quick_btn.text = "⚡ EQUIPAR MEJOR"
	quick_btn.custom_minimum_size = Vector2(320, 72)
	PREMIUM_STYLE.style_button(quick_btn, "gold")
	quick_btn.pressed.connect(_on_quick_equip)
	bar.add_child(quick_btn)
	var preset_row := HBoxContainer.new()
	preset_row.add_theme_constant_override("separation", 6)
	for i in [1,2,3]:
		var b := Button.new()
		b.text = "SET %d" % i
		b.custom_minimum_size = Vector2(110, 72)
		PREMIUM_STYLE.style_button(b, "blue")
		var pid := "set%d" % i
		b.pressed.connect(func(): _on_preset_pressed(pid))
		preset_row.add_child(b)
		var save_b := Button.new()
		save_b.text = "💾"
		save_b.custom_minimum_size = Vector2(60, 72)
		PREMIUM_STYLE.style_button(save_b, "green")
		save_b.pressed.connect(func(): InventoryManager.save_preset(pid); _show_toast("Preset %s guardado" % pid))
		preset_row.add_child(save_b)
	bar.add_child(preset_row)
	main_vbox.add_child(bar)
	main_vbox.move_child(bar, 3)

func _refresh() -> void:
	for child in slots_grid.get_children():
		child.queue_free()
	slots_grid.custom_minimum_size = Vector2(940, EQUIPMENT_SLOTS.size() * 142 + (EQUIPMENT_SLOTS.size() - 1) * 14)
	var equipped_count := 0
	for slot in EQUIPMENT_SLOTS:
		var instance = GameState.equipped_items.get(slot, null)
		if instance != null and instance is Dictionary:
			equipped_count += 1
		slots_grid.add_child(_make_slot_card(slot, instance))
	slots_grid.queue_sort()
	main_vbox.queue_sort()
	count_label.text = "%d / %d slots ocupados" % [equipped_count, EQUIPMENT_SLOTS.size()]
	var dummy := Player.new()
	dummy.base_damage = 14
	dummy.base_max_health = 100
	dummy.attack_speed = 1.2
	var stats: Dictionary = StatsCalculator.player_final_stats(dummy)
	dummy.free()
	stats_label.text = "PODER  %d\nDAÑO  %d     VIDA  %d     ARMADURA  %d\nCRÍTICO  %.1f%%     VELOCIDAD  %.0f%%\n%s     ALCANCE  %d" % [
		StatsCalculator.combat_power(stats),
		int(round(float(stats.get("damage", 0.0)))),
		int(round(float(stats.get("max_health", 0.0)))),
		int(round(float(stats.get("armor", 0.0)))),
		float(stats.get("critical_chance", 0.0)) * 100.0,
		float(stats.get("attack_speed", 0.0)) * 100.0,
		"ATAQUE A DISTANCIA" if String(stats.get("attack_type", "melee")) == "ranged" else "ATAQUE CUERPO A CUERPO",
		int(round(float(stats.get("attack_range", 0.0))))
	]

func _make_slot_card(slot: String, instance) -> PanelContainer:
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(940, 142)
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.065, 0.085, 0.135, 0.98)
	style.border_color = LootManager.get_rarity_color(String(instance.get("rarity", "common"))) if instance is Dictionary else Color(0.24, 0.34, 0.52, 0.85)
	style.set_border_width_all(2)
	style.set_corner_radius_all(18)
	style.shadow_color = Color(0.01, 0.02, 0.04, 0.7)
	style.shadow_size = 10
	style.content_margin_left = 20.0
	style.content_margin_right = 20.0
	style.content_margin_top = 14.0
	style.content_margin_bottom = 14.0
	panel.add_theme_stylebox_override("panel", style)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	panel.add_child(row)
	var icon := ItemIcon.new()
	icon.custom_minimum_size = Vector2(110, 110)
	icon.set_item(instance if instance is Dictionary else {"slot": slot, "rarity": "common", "name": slot})
	row.add_child(icon)
	var info := VBoxContainer.new()
	info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	info.add_theme_constant_override("separation", 3)
	row.add_child(info)
	var slot_label := Label.new()
	slot_label.add_theme_font_size_override("font_size", 24)
	slot_label.add_theme_color_override("font_color", Color(0.55, 0.66, 0.82))
	slot_label.text = _slot_label(slot)
	info.add_child(slot_label)
	var name_label := Label.new()
	name_label.add_theme_font_size_override("font_size", 27)
	if instance == null or not (instance is Dictionary):
		name_label.text = "VACÍO — Toca para ver %ss" % slot.to_upper()
		name_label.add_theme_color_override("font_color", Color(0.48, 0.53, 0.62))
	else:
		var fav := "⭐ " if bool(instance.get("favorite", false)) else ""
		name_label.text = fav + "%s  Nv.%d" % [String(instance.get("name", "?")), int(instance.get("level", 1))]
		name_label.add_theme_color_override("font_color", LootManager.get_rarity_color(String(instance.get("rarity", "common"))))
	info.add_child(name_label)
	var detail := Label.new()
	detail.add_theme_font_size_override("font_size", 21)
	detail.add_theme_color_override("font_color", Color(0.62, 0.7, 0.83))
	if instance == null or not (instance is Dictionary):
		detail.text = "Sin objeto equipado"
	else:
		var parts: PackedStringArray = []
		var totals := StatsCalculator.item_total_stats(instance)
		for key in ["damage", "max_health", "critical_chance", "attack_speed", "armor"]:
			if totals.has(key):
				parts.append(StatsCalculator.format_stat_line(key, float(totals[key])))
		detail.text = "  ·  ".join(parts.slice(0, 2)) if not parts.is_empty() else "Sin bonificadores"
	info.add_child(detail)
	var open_btn := Button.new()
	open_btn.custom_minimum_size = Vector2(140, 76)
	open_btn.add_theme_font_size_override("font_size", 24)
	open_btn.text = "VER"
	PREMIUM_STYLE.style_button(open_btn, "blue")
	open_btn.pressed.connect(func(): _open_category(slot))
	row.add_child(open_btn)
	if instance != null and instance is Dictionary:
		var remove_button := Button.new()
		remove_button.custom_minimum_size = Vector2(112, 76)
		remove_button.add_theme_font_size_override("font_size", 22)
		remove_button.text = "QUITAR"
		PREMIUM_STYLE.style_button(remove_button, "brown")
		remove_button.pressed.connect(func() -> void:
			if InventoryManager.unequip_item(slot):
				_refresh()
		)
		row.add_child(remove_button)
	# make whole panel clickable
	panel.gui_input.connect(func(event: InputEvent):
		if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			_open_category(slot)
	)
	return panel

func _slot_label(slot: String) -> String:
	return {"weapon": "ARMA", "helmet": "CASCO", "armor": "ARMADURA", "gloves": "GUANTES", "boots": "BOTAS", "amulet": "AMULETO"}.get(slot, slot.to_upper())

# ── category modal ─────────────────────────────────────────────────────────
func _build_category_modal() -> void:
	_category_modal = ColorRect.new()
	_category_modal.color = Color(0,0,0,0.65)
	_category_modal.visible = false
	_category_modal.mouse_filter = Control.MOUSE_FILTER_STOP
	_category_modal.set_anchors_preset(Control.PRESET_FULL_RECT)
	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	_category_modal.add_child(center)
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(980, 0)
	PREMIUM_STYLE.style_panel(panel)
	center.add_child(panel)
	var vbox := VBoxContainer.new()
	vbox.name = "CatVBox"
	vbox.add_theme_constant_override("separation", 12)
	panel.add_child(vbox)
	add_child(_category_modal)
	_category_modal.gui_input.connect(func(e):
		if e is InputEventMouseButton and e.pressed:
			_category_modal.visible = false
	)

func _open_category(slot: String) -> void:
	var vbox := _category_modal.get_child(0).get_child(0).get_child(0) as VBoxContainer
	for c in vbox.get_children():
		c.queue_free()
	var title := Label.new()
	title.text = "%ss DISPONIBLES" % _slot_label(slot)
	title.add_theme_font_size_override("font_size", 48)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(title)
	# controls row: sort + only better
	var ctrl_row := HBoxContainer.new()
	ctrl_row.add_theme_constant_override("separation", 10)
	ctrl_row.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_child(ctrl_row)
	var sort_btn := OptionButton.new()
	sort_btn.custom_minimum_size = Vector2(220, 56)
	for opt in [["power","Poder"],["level","Nivel"],["rarity","Rareza"]]:
		sort_btn.add_item(opt[1])
	sort_btn.selected = 0
	ctrl_row.add_child(sort_btn)
	var better_check := CheckBox.new()
	better_check.text = "Solo mejoras"
	ctrl_row.add_child(better_check)
	var fav_check := CheckBox.new()
	fav_check.text = "⭐ Favoritos"
	ctrl_row.add_child(fav_check)
	# recommended
	var rec := InventoryManager.recommend_for_slot(slot)
	var rec_label := Label.new()
	rec_label.add_theme_font_size_override("font_size", 28)
	if rec.is_empty():
		rec_label.text = "No hay mejoras disponibles"
		rec_label.add_theme_color_override("font_color", Color(0.6,0.65,0.7))
	else:
		rec_label.text = "⭐ RECOMENDADO: %s Nv.%d  +%d poder" % [rec.get("name","?"), int(rec.get("level",1)), int(InventoryManager.get_item_power(rec) - _equipped_power(slot))]
		rec_label.add_theme_color_override("font_color", Color(1,0.82,0.2))
		var rec_btn := Button.new()
		rec_btn.text = "EQUIPAR RECOMENDADO"
		rec_btn.custom_minimum_size = Vector2(320, 64)
		PREMIUM_STYLE.style_button(rec_btn, "gold")
		rec_btn.pressed.connect(func():
			InventoryManager.equip_item(String(rec.get("id","")))
			_category_modal.visible = false
			_refresh()
		)
		ctrl_row.add_child(rec_btn)
	vbox.add_child(rec_label)
	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(900, 700)
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_child(scroll)
	var list := VBoxContainer.new()
	list.name = "CatList"
	list.add_theme_constant_override("separation", 10)
	scroll.add_child(list)
	var refresh_list := func():
		for c in list.get_children():
			c.queue_free()
		var items: Array = []
		for it in GameState.inventory:
			if String(it.get("slot","")) != slot:
				continue
			if fav_check.button_pressed and not bool(it.get("favorite",false)):
				continue
			if better_check.button_pressed and not InventoryManager.is_better_than_equipped(it):
				continue
			items.append(it)
		var key_map := ["power","level","rarity"]
		items = InventoryManager.sort_items(items, key_map[sort_btn.selected])
		if items.is_empty():
			var empty := Label.new()
			empty.text = "No hay objetos para este filtro"
			empty.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			list.add_child(empty)
			return
		for it in items:
			list.add_child(_make_category_row(it, slot))
	refresh_list.call()
	sort_btn.item_selected.connect(func(_i): refresh_list.call())
	better_check.toggled.connect(func(_v): refresh_list.call())
	fav_check.toggled.connect(func(_v): refresh_list.call())
	var close := Button.new()
	close.text = "CERRAR"
	PREMIUM_STYLE.style_button(close, "blue")
	close.pressed.connect(func(): _category_modal.visible = false)
	vbox.add_child(close)
	_category_modal.visible = true

func _equipped_power(slot: String) -> float:
	var eq = GameState.equipped_items.get(slot, null)
	if eq == null or not (eq is Dictionary):
		return -1
	return InventoryManager.get_item_power(eq)

func _make_category_row(item: Dictionary, slot: String) -> PanelContainer:
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(880, 110)
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.07,0.09,0.14,0.98)
	style.border_color = LootManager.get_rarity_color(String(item.get("rarity","common")))
	style.set_border_width_all(2)
	style.set_corner_radius_all(14)
	panel.add_theme_stylebox_override("panel", style)
	var hbox := HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 12)
	panel.add_child(hbox)
	var icon := ItemIcon.new()
	icon.custom_minimum_size = Vector2(90,90)
	icon.set_item(item)
	hbox.add_child(icon)
	var info := VBoxContainer.new()
	info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hbox.add_child(info)
	var fav := "⭐ " if bool(item.get("favorite",false)) else ""
	var trash := "🗑️ " if bool(item.get("trash",false)) else ""
	var title := Label.new()
	title.text = fav + trash + "%s Nv.%d" % [item.get("name","?"), int(item.get("level",1))]
	title.add_theme_color_override("font_color", LootManager.get_rarity_color(String(item.get("rarity","common"))))
	title.add_theme_font_size_override("font_size", 28)
	info.add_child(title)
	var sub := Label.new()
	sub.text = "%s · Poder %d · %d oro" % [LootManager.get_rarity_name(String(item.get("rarity",""))), int(InventoryManager.get_item_power(item)), int(item.get("sell_value",0))]
	sub.add_theme_font_size_override("font_size", 22)
	info.add_child(sub)
	var is_better := InventoryManager.is_better_than_equipped(item)
	var badge := Label.new()
	badge.text = "🟢 MEJORA" if is_better else "🔴 INFERIOR"
	badge.add_theme_font_size_override("font_size", 22)
	badge.add_theme_color_override("font_color", Color(0.3,0.8,0.35) if is_better else Color(0.8,0.3,0.3))
	info.add_child(badge)
	var btn := Button.new()
	btn.text = "EQUIPAR"
	btn.custom_minimum_size = Vector2(140, 70)
	PREMIUM_STYLE.style_button(btn, "green")
	btn.pressed.connect(func(): _show_comparison(item, slot))
	hbox.add_child(btn)
	return panel

# ── comparison ────────────────────────────────────────────────────────────
func _build_compare_modal() -> void:
	_compare_modal = ColorRect.new()
	_compare_modal.color = Color(0,0,0,0.65)
	_compare_modal.visible = false
	_compare_modal.mouse_filter = Control.MOUSE_FILTER_STOP
	_compare_modal.set_anchors_preset(Control.PRESET_FULL_RECT)
	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	_compare_modal.add_child(center)
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(980, 0)
	PREMIUM_STYLE.style_panel(panel)
	center.add_child(panel)
	panel.add_child(VBoxContainer.new())
	add_child(_compare_modal)

func _show_comparison(new_item: Dictionary, slot: String) -> void:
	_category_modal.visible = false
	var vbox := _compare_modal.get_child(0).get_child(0).get_child(0) as VBoxContainer
	for c in vbox.get_children():
		c.queue_free()
	var title := Label.new()
	title.text = "COMPARAR %s" % _slot_label(slot)
	title.add_theme_font_size_override("font_size", 44)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(title)
	var cur = GameState.equipped_items.get(slot, null)
	var cur_box := _make_compare_card("ACTUAL", cur)
	var new_box := _make_compare_card("NUEVO", new_item)
	var cols := HBoxContainer.new()
	cols.add_theme_constant_override("separation", 16)
	cols.add_child(cur_box)
	cols.add_child(new_box)
	vbox.add_child(cols)
	# diff per stat
	var cur_totals := StatsCalculator.item_total_stats(cur) if cur is Dictionary else {}
	var new_totals := StatsCalculator.item_total_stats(new_item)
	var diff_box := VBoxContainer.new()
	diff_box.add_theme_constant_override("separation", 4)
	vbox.add_child(diff_box)
	var diff_title := Label.new()
	diff_title.text = "Diferencia por objeto"
	diff_title.add_theme_font_size_override("font_size", 26)
	diff_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	diff_box.add_child(diff_title)
	for key in ["damage","max_health","armor","critical_chance","attack_speed"]:
		var cur_v := float(cur_totals.get(key,0.0)) if cur is Dictionary else 0.0
		var new_v := float(new_totals.get(key,0.0))
		var diff := new_v - cur_v
		if absf(diff) < 0.0005:
			continue
		var lbl := Label.new()
		var icon: String = String({"damage":"⚔️","max_health":"❤️","armor":"🛡️","critical_chance":"⭐","attack_speed":"⚡"}.get(key, "•"))
		var col := Color(0.3,0.8,0.35) if diff>0 else Color(0.9,0.3,0.3)
		var sign := "🟢" if diff>0 else "🔴"
		lbl.text = "%s %s: %s → %s  %s %+.1f" % [icon, key, str(cur_v), str(new_v), sign, diff]
		lbl.add_theme_color_override("font_color", col)
		lbl.add_theme_font_size_override("font_size", 24)
		diff_box.add_child(lbl)
	# total character impact
	var dummy_before := Player.new()
	dummy_before.base_damage = 14; dummy_before.base_max_health = 100; dummy_before.attack_speed = 1.2
	var before_stats: Dictionary = StatsCalculator.player_final_stats(dummy_before)
	dummy_before.free()
	var bak = GameState.equipped_items.duplicate(true)
	GameState.equipped_items[slot] = new_item
	var dummy_after := Player.new()
	dummy_after.base_damage = 14; dummy_after.base_max_health = 100; dummy_after.attack_speed = 1.2
	var after_stats: Dictionary = StatsCalculator.player_final_stats(dummy_after)
	dummy_after.free()
	GameState.equipped_items = bak
	var impact_title := Label.new()
	impact_title.text = "Impacto en personaje"
	impact_title.add_theme_font_size_override("font_size", 28)
	impact_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(impact_title)
	var impact_box := VBoxContainer.new()
	vbox.add_child(impact_box)
	for key in ["damage","max_health","critical_chance"]:
		var b := float(before_stats.get(key,0.0))
		var a := float(after_stats.get(key,0.0))
		var d := a - b
		if absf(d) < 0.0005:
			continue
		var lbl2 := Label.new()
		var ic2: String = String({"damage":"⚔️","max_health":"❤️","critical_chance":"⭐"}.get(key,"•"))
		lbl2.text = "%s %s: %.1f → %.1f  %s %+.1f" % [ic2, key, b, a, "🟢" if d>0 else "🔴", d]
		lbl2.add_theme_color_override("font_color", Color(0.3,0.8,0.35) if d>0 else Color(0.9,0.3,0.3))
		impact_box.add_child(lbl2)
	var btn_row := HBoxContainer.new()
	btn_row.alignment = BoxContainer.ALIGNMENT_CENTER
	btn_row.add_theme_constant_override("separation", 16)
	vbox.add_child(btn_row)
	var cancel := Button.new()
	cancel.text = "CANCELAR"
	PREMIUM_STYLE.style_button(cancel, "blue")
	cancel.pressed.connect(func(): _compare_modal.visible = false)
	btn_row.add_child(cancel)
	var equip := Button.new()
	equip.text = "EQUIPAR"
	PREMIUM_STYLE.style_button(equip, "green")
	equip.pressed.connect(func():
		InventoryManager.equip_item(String(new_item.get("id","")))
		_compare_modal.visible = false
		_refresh()
	)
	btn_row.add_child(equip)
	_compare_modal.visible = true

func _make_compare_card(label: String, item) -> PanelContainer:
	var p := PanelContainer.new()
	p.custom_minimum_size = Vector2(460, 0)
	p.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var s := StyleBoxFlat.new()
	s.bg_color = Color(0.06,0.08,0.12,0.98)
	s.set_border_width_all(2)
	s.set_corner_radius_all(12)
	s.border_color = LootManager.get_rarity_color(String(item.get("rarity","common"))) if item is Dictionary else Color(0.3,0.35,0.45)
	p.add_theme_stylebox_override("panel", s)
	var vb := VBoxContainer.new()
	p.add_child(vb)
	var l1 := Label.new()
	l1.text = label
	l1.add_theme_font_size_override("font_size", 22)
	l1.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vb.add_child(l1)
	if item == null or not (item is Dictionary):
		var empty := Label.new()
		empty.text = "Vacío"
		empty.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		vb.add_child(empty)
	else:
		var icon := ItemIcon.new()
		icon.custom_minimum_size = Vector2(90,90)
		icon.set_item(item)
		vb.add_child(icon)
		var n := Label.new()
		n.text = "%s Nv.%d" % [item.get("name","?"), int(item.get("level",1))]
		n.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		vb.add_child(n)
		var totals := StatsCalculator.item_total_stats(item)
		for k in totals.keys():
			var ll := Label.new()
			ll.text = StatsCalculator.format_stat_line(k, float(totals[k]))
			ll.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			vb.add_child(ll)
	return p

# ── quick equip / presets ──────────────────────────────────────────────────
func _on_quick_equip() -> void:
	var preview := InventoryManager.quick_equip_best_preview()
	if preview["best"].is_empty():
		_show_toast("Ya tenés el mejor equipo")
		return
	var body := "Poder %d → %d\nDaño %d → %d\nVida %d → %d" % [preview["power_before"], preview["power_after"], int(preview["before"].get("damage",0)), int(preview["after"].get("damage",0)), int(preview["before"].get("max_health",0)), int(preview["after"].get("max_health",0))]
	_show_confirm("Equipamiento rápido", body, "APLICAR", func():
		InventoryManager.quick_equip_best_apply()
		_show_toast("Equipo optimizado")
	)

func _on_preset_pressed(preset_id: String) -> void:
	if Input.is_key_pressed(KEY_SHIFT):
		InventoryManager.save_preset(preset_id)
		_show_toast("Preset %s guardado (Shift)" % preset_id)
	else:
		if InventoryManager.load_preset(preset_id):
			_show_toast("Preset %s cargado" % preset_id)
		else:
			_show_toast("Preset vacío — Shift+click para guardar")

func _show_toast(text: String) -> void:
	var lbl := Label.new()
	lbl.text = text
	lbl.add_theme_font_size_override("font_size", 34)
	lbl.add_theme_color_override("font_color", Color(1,0.92,0.5))
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.position = Vector2(40, 1720)
	lbl.size = Vector2(1000, 60)
	add_child(lbl)
	var tw := create_tween()
	tw.tween_interval(1.4)
	tw.tween_property(lbl, "modulate:a", 0.0, 0.4)
	tw.tween_callback(lbl.queue_free)

func _show_confirm(title: String, body: String, confirm_text: String, on_confirm: Callable) -> void:
	var overlay := ColorRect.new()
	overlay.color = Color(0,0,0,0.65)
	overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay.add_child(center)
	var panel := PanelContainer.new()
	PREMIUM_STYLE.style_panel(panel)
	center.add_child(panel)
	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 16)
	panel.add_child(vbox)
	var tl := Label.new()
	tl.text = title
	tl.add_theme_font_size_override("font_size", 42)
	tl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(tl)
	var bl := Label.new()
	bl.text = body
	bl.add_theme_font_size_override("font_size", 28)
	bl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	bl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vbox.add_child(bl)
	var hbox := HBoxContainer.new()
	hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_child(hbox)
	var cancel := Button.new()
	cancel.text = "CANCELAR"
	PREMIUM_STYLE.style_button(cancel, "blue")
	cancel.pressed.connect(func(): overlay.queue_free())
	hbox.add_child(cancel)
	var ok := Button.new()
	ok.text = confirm_text
	PREMIUM_STYLE.style_button(ok, "gold")
	ok.pressed.connect(func(): overlay.queue_free(); on_confirm.call())
	hbox.add_child(ok)
	add_child(overlay)
