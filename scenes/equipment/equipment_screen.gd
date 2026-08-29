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

func _ready() -> void:
	_configure_layout()
	_apply_premium_skin()
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
		_go_back()

func _go_back() -> void:
	get_tree().change_scene_to_file(MENU_SCENE)

func _refresh() -> void:
	for child in slots_grid.get_children():
		child.queue_free()
	# Reservamos la altura de las tarjetas creadas dinámicamente para que el VBox
	# principal pueda distribuir de forma estable los seis slots.
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

func _configure_layout() -> void:
	# Mantiene el panel vertical de diseño centrado cuando "expand" agrega
	# ancho lógico en escritorio; en Android conserva el ancho completo 1080.
	var visible_rect := get_viewport().get_visible_rect()
	var content_width := minf(DESIGN_WIDTH, maxf(visible_rect.size.x - 64.0, 640.0))
	main_vbox.anchor_left = 0.0
	main_vbox.anchor_top = 0.0
	main_vbox.anchor_right = 0.0
	main_vbox.anchor_bottom = 0.0
	main_vbox.position = Vector2(visible_rect.position.x + (visible_rect.size.x - content_width) * 0.5, visible_rect.position.y + 34.0)
	main_vbox.size = Vector2(content_width, maxf(visible_rect.size.y - 68.0, 0.0))

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
		name_label.text = "VACÍO"
		name_label.add_theme_color_override("font_color", Color(0.48, 0.53, 0.62))
	else:
		name_label.text = "%s  Nv.%d" % [String(instance.get("name", "?")), int(instance.get("level", 1))]
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
	return panel

func _slot_label(slot: String) -> String:
	return {"weapon": "ARMA", "helmet": "CASCO", "armor": "ARMADURA", "gloves": "GUANTES", "boots": "BOTAS", "amulet": "AMULETO"}.get(slot, slot.to_upper())
