extends Control

const MENU_SCENE := "res://scenes/menu/main_menu.tscn"

var _selected_id := ""

@onready var items_list: VBoxContainer = %ItemsList
@onready var count_label: Label = %InvCountLabel
@onready var detail_panel: PanelContainer = %DetailPanel
@onready var detail_label: Label = %DetailLabel
@onready var equip_button: Button = %InvEquipButton
@onready var sell_button: Button = %InvSellButton
@onready var back_button: Button = %BackButton
@onready var sell_commons_button: Button = %SellCommonsButton

func _ready() -> void:
	back_button.pressed.connect(func() -> void: get_tree().change_scene_to_file(MENU_SCENE))
	equip_button.pressed.connect(_on_equip_pressed)
	sell_button.pressed.connect(_on_sell_pressed)
	sell_commons_button.pressed.connect(_on_sell_commons_pressed)
	InventoryManager.inventory_changed.connect(_refresh)
	_refresh()

func _refresh() -> void:
	for child in items_list.get_children():
		child.queue_free()
	count_label.text = "%d / 50 objetos  ·  ORO %d" % [GameState.inventory.size(), GameState.gold]
	detail_panel.visible = false
	_selected_id = ""
	if GameState.inventory.is_empty():
		var empty := Label.new()
		empty.text = "Inventario vacio. Gana oleadas para conseguir objetos."
		empty.add_theme_font_size_override("font_size", 34)
		empty.add_theme_color_override("font_color", Color(0.62, 0.68, 0.8))
		items_list.add_child(empty)
		return
	for instance in GameState.inventory:
		items_list.add_child(_make_row(instance))
	_refresh_buttons_state()

func _make_row(instance: Dictionary) -> Button:
	var row := Button.new()
	row.custom_minimum_size = Vector2(960, 96)
	row.add_theme_font_size_override("font_size", 32)
	row.alignment = HORIZONTAL_ALIGNMENT_LEFT
	row.text = "[%s]  %s  Nv.%d   ·   %s" % [
		LootManager.get_rarity_name(String(instance.get("rarity", ""))).to_upper(),
		instance.get("name", "?"),
		int(instance.get("level", 1)),
		String(instance.get("slot", "")).to_upper(),
	]
	row.add_theme_color_override("font_color", LootManager.get_rarity_color(String(instance.get("rarity", ""))))
	var id := String(instance.get("id", ""))
	row.pressed.connect(func() -> void: _select_item(id))
	return row

func _select_item(item_id: String) -> void:
	_selected_id = item_id
	var instance := InventoryManager.find_item(item_id)
	if instance.is_empty():
		return
	detail_panel.visible = true
	var lines: PackedStringArray = []
	lines.append("%s — %s Nv.%d" % [instance.get("name", "?"), LootManager.get_rarity_name(String(instance.get("rarity", ""))), int(instance.get("level", 1))])
	for stat_key in StatsCalculator.item_total_stats(instance).keys():
		lines.append(StatsCalculator.format_stat_line(stat_key, float(StatsCalculator.item_total_stats(instance)[stat_key])))
	lines.append("Valor de venta: %d oro" % int(instance.get("sell_value", 0)))
	detail_label.text = "\n".join(lines)
	_refresh_buttons_state()

func _refresh_buttons_state() -> void:
	var has_selection := not _selected_id.is_empty()
	equip_button.disabled = not has_selection
	sell_button.disabled = not has_selection

func _on_equip_pressed() -> void:
	if InventoryManager.equip_item(_selected_id):
		_show_toast("¡Equipado!")
	else:
		_show_toast("No se pudo equipar")

func _on_sell_pressed() -> void:
	var val := InventoryManager.sell_item(_selected_id)
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
